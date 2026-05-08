import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { PrivateLetter } from '../models';
import { runPythonTool } from '../utils/pythonTools';

const router = Router();

router.use(authMiddleware);

router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { content, title, allow_ai_analysis = true } = req.body;
    const userId = req.user!.id;
    const now = new Date().toISOString();

    const letterId = uuidv4();
    let emotion: string | undefined;
    let emotionIntensity: number | undefined;

    if (allow_ai_analysis) {
      const emotionResult = await runPythonTool('emotion_analysis.py', { text: content });
      if (emotionResult.success && emotionResult.data) {
        const emotionData = emotionResult.data as { emotion?: string; intensity?: number };
        emotion = emotionData.emotion;
        emotionIntensity = emotionData.intensity;
      }
    }

    execute(
      `INSERT INTO private_letters (id, user_id, title, content, content_type, allow_ai_analysis, emotion, emotion_intensity, write_to_emotion_profile, is_public, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, 0, ?)`,
      [
        letterId, userId, title || null, content, 'text',
        allow_ai_analysis ? 1 : 0, emotion || null, emotionIntensity || null,
        allow_ai_analysis ? 1 : 0, now
      ]
    );

    const letter = queryOne<PrivateLetter>(
      'SELECT * FROM private_letters WHERE id = ?',
      [letterId]
    );

    res.status(201).json({ letter });
  } catch (error) {
    console.error('Create letter error:', error);
    res.status(500).json({ error: 'Failed to create letter' });
  }
});

router.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const letter = queryOne<PrivateLetter>(
      'SELECT * FROM private_letters WHERE id = ? AND user_id = ? AND deleted_at IS NULL',
      [id, userId]
    );

    if (!letter) {
      res.status(404).json({ error: 'Letter not found' });
      return;
    }

    res.json({ letter });
  } catch (error) {
    console.error('Get letter error:', error);
    res.status(500).json({ error: 'Failed to get letter' });
  }
});

export default router;
