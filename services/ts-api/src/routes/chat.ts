import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { ChatMessage } from '../models';
import { analyzeText, createEmotionRecord, createRiskEventIfNeeded } from '../utils/emotion';

const router = Router();
const BAILIAN_API_URL = process.env.BAILIAN_API_URL || 'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions';
const BAILIAN_API_KEY = process.env.BAILIAN_API_KEY || '';
const BAILIAN_MODEL = process.env.BAILIAN_MODEL || 'qwen-plus';

router.use(authMiddleware);

type CompanionAnalysis = Awaited<ReturnType<typeof analyzeText>>;

async function generateCompanionReply(content: string, analysis: CompanionAnalysis, recentMessages: ChatMessage[] = []) {
  if (analysis.risk_detected) {
    return '我听见你现在可能很难受。先把自己放到一个更安全、更安静的地方，试着联系一位你信任的人陪你一下。如果你觉得自己有立即危险，请马上拨打当地紧急求助电话或联系身边的现实支持。';
  }

  if (!BAILIAN_API_KEY) {
    return analysis.response || '谢谢你愿意告诉我这些，我会认真听你说完。';
  }

  try {
    const response = await fetch(BAILIAN_API_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${BAILIAN_API_KEY}`
      },
      body: JSON.stringify({
        model: BAILIAN_MODEL,
        messages: [
          {
            role: 'system',
            content: '你是一个温柔、耐心、非评判性的AI陪伴助手。请用中文回复，像真实的人在陪伴聊天。优先共情、复述对方感受、提出一个轻柔的问题、再给出一点点鼓励。回复尽量是2到4段自然短句，不要只回一句，不要编号罗列，不要空话套话。遇到高风险内容时，优先做安全提示、稳定情绪和求助建议。'
          },
          ...recentMessages.map((message) => ({
            role: message.role === 'assistant' ? 'assistant' : 'user',
            content: message.content
          })),
          {
            role: 'user',
            content: `用户刚才说：${content}\n\n情绪分析结果：${analysis.summary}\n情绪：${analysis.emotion}，强度：${analysis.intensity}，关键词：${analysis.keywords.join('、') || '无'}。请结合前面的对话上下文，给出一段贴近陪伴语气的回复。`
          }
        ],
        temperature: 0.8,
        top_p: 0.9,
        max_tokens: 400
      })
    });

    if (!response.ok) {
      throw new Error(`Bailian request failed with status ${response.status}`);
    }

    const data = await response.json() as { choices?: Array<{ message?: { content?: string } }> };
    const text = data.choices?.[0]?.message?.content?.trim();
    return text || analysis.response || '谢谢你愿意告诉我这些，我会认真听你说完。';
  } catch (error) {
    console.error('Generate companion reply failed:', error);
    return analysis.response || '谢谢你愿意告诉我这些，我会认真听你说完。';
  }
}

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
    const sessionMessages = session_id
      ? await query<ChatMessage>(
          'SELECT * FROM chat_messages WHERE user_id = $1 AND session_id = $2 ORDER BY created_at DESC LIMIT 6',
          [userId, session_id]
        )
      : [];
    const recentMessages = sessionMessages.reverse();

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
    const aiContent = await generateCompanionReply(content, analysis, recentMessages);

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
