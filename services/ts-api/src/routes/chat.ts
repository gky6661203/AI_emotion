import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { ChatMessage } from '../models';
import { runPythonTool } from '../utils/pythonTools';

const router = Router();

router.use(authMiddleware);

router.post('/messages', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { content, session_id } = req.body;
    const userId = req.user!.id;
    const now = new Date().toISOString();

    const userMessageId = uuidv4();
    execute(
      `INSERT INTO chat_messages (id, user_id, session_id, role, content, content_type, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [userMessageId, userId, session_id || null, 'user', content, 'text', now]
    );

    const aiMessageId = uuidv4();
    let aiContent = '感谢你的分享。我在这里倾听你。';

    const emotionResult = await runPythonTool('emotion_analysis.py', { text: content });
    if (emotionResult.success && emotionResult.data) {
      const emotionData = emotionResult.data as { response?: string };
      if (emotionData.response) {
        aiContent = emotionData.response;
      }
    }

    execute(
      `INSERT INTO chat_messages (id, user_id, session_id, role, content, content_type, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [aiMessageId, userId, session_id || null, 'assistant', aiContent, 'text', now]
    );

    execute(
      'UPDATE users SET total_interactions = total_interactions + 1, updated_at = ? WHERE id = ?',
      [now, userId]
    );

    const userMessage = query<ChatMessage>(
      'SELECT * FROM chat_messages WHERE id = ?',
      [userMessageId]
    );
    const aiMessage = query<ChatMessage>(
      'SELECT * FROM chat_messages WHERE id = ?',
      [aiMessageId]
    );

    res.status(201).json({
      message: userMessage[0],
      ai_response: aiMessage[0]
    });
  } catch (error) {
    console.error('Send message error:', error);
    res.status(500).json({ error: 'Failed to send message' });
  }
});

export default router;
