import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { ChatMessage } from '../models';
import { analyzeText, createEmotionRecord, createRiskEventIfNeeded } from '../utils/emotion';

const router = Router();

router.use(authMiddleware);

router.get('/messages', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
    const sessionId = req.query.session_id as string | undefined;

    const params: unknown[] = [userId];
    let where = 'WHERE user_id = $1';

    if (sessionId) {
      params.push(sessionId);
      where += ` AND session_id = $${params.length}`;
    }

    params.push(limit);
    const messages = await query<ChatMessage>(
      `SELECT * FROM chat_messages ${where} ORDER BY created_at DESC LIMIT $${params.length}`,
      params
    );

    res.json({ messages: messages.reverse() });
  } catch (error) {
    console.error('List messages error:', error);
    res.status(500).json({ error: 'Failed to list messages' });
  }
});

router.post('/messages', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { content, session_id } = req.body;
    if (!content || typeof content !== 'string') {
      res.status(400).json({ error: 'content is required' });
      return;
    }

    const userId = req.user!.id;
    const now = new Date().toISOString();
    const analysis = await analyzeText(content);

    const userMessageId = uuidv4();
    await execute(
      `INSERT INTO chat_messages (id, user_id, session_id, role, content, content_type, message_metadata, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        userMessageId,
        userId,
        session_id || null,
        'user',
        content,
        'text',
        JSON.stringify({ emotion_analysis: analysis }),
        now
      ]
    );

    await createEmotionRecord(userId, analysis, 'text', userMessageId);
    await createRiskEventIfNeeded(userId, analysis, 'chat', userMessageId, content);

    const aiMessageId = uuidv4();
    const aiContent = analysis.risk_detected
      ? '我听见你现在可能很难受。请先让自己远离危险物品，尽量联系身边可信任的人或学校心理支持资源。如果你正处在立即危险中，请马上联系当地紧急求助电话。'
      : analysis.response || '感谢你的分享。我在这里倾听你。';

    await execute(
      `INSERT INTO chat_messages (id, user_id, session_id, role, content, content_type, message_metadata, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [
        aiMessageId,
        userId,
        session_id || null,
        'assistant',
        aiContent,
        'text',
        JSON.stringify({ based_on_message_id: userMessageId, risk_level: analysis.risk_level }),
        now
      ]
    );

    await execute(
      'UPDATE users SET total_interactions = total_interactions + 1, updated_at = $1 WHERE id = $2',
      [now, userId]
    );

    const userMessage = await queryOne<ChatMessage>('SELECT * FROM chat_messages WHERE id = $1', [userMessageId]);
    const aiMessage = await queryOne<ChatMessage>('SELECT * FROM chat_messages WHERE id = $1', [aiMessageId]);

    res.status(201).json({
      message: userMessage,
      ai_response: aiMessage,
      emotion_analysis: analysis
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

export default router;
