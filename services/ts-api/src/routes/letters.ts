import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { PrivateLetter } from '../models';
import { analyzeText, createEmotionRecord, createRiskEventIfNeeded, EmotionAnalysisResult } from '../utils/emotion';

const router = Router();

router.use(authMiddleware);

function buildLetterListQuery(userId: string, req: AuthenticatedRequest): { sql: string; params: unknown[] } {
  const params: unknown[] = [userId];
  const filters = ['user_id = $1', 'deleted_at IS NULL'];

  const keyword = req.query.keyword as string | undefined;
  const emotion = req.query.emotion as string | undefined;
  const startDate = req.query.start_date as string | undefined;
  const endDate = req.query.end_date as string | undefined;

  if (keyword) {
    params.push(`%${keyword}%`);
    filters.push(`(title ILIKE $${params.length} OR content ILIKE $${params.length})`);
  }

  if (emotion) {
    params.push(emotion);
    filters.push(`emotion = $${params.length}`);
  }

  if (startDate) {
    params.push(startDate);
    filters.push(`created_at >= $${params.length}`);
  }

  if (endDate) {
    params.push(endDate);
    filters.push(`created_at <= $${params.length}`);
  }

  const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
  params.push(limit);

  return {
    sql: `SELECT * FROM private_letters WHERE ${filters.join(' AND ')} ORDER BY created_at DESC LIMIT $${params.length}`,
    params
  };
}

router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const { sql, params } = buildLetterListQuery(userId, req);
    const letters = await query<PrivateLetter>(sql, params);
    res.json({ letters });
  } catch (error) {
    console.error('List letters error:', error);
    res.status(500).json({ error: 'Failed to list letters' });
  }
});

router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const {
      content,
      title,
      allow_ai_analysis = true,
      write_to_emotion_profile = true,
      open_at
    } = req.body;

    if (!content || typeof content !== 'string') {
      res.status(400).json({ error: 'content is required' });
      return;
    }

    const userId = req.user!.id;
    const now = new Date().toISOString();
    const letterId = uuidv4();
    let analysis: EmotionAnalysisResult | null = null;

    if (allow_ai_analysis) {
      analysis = await analyzeText(content);
    }

    await execute(
      `INSERT INTO private_letters (
        id, user_id, title, content, content_type, allow_ai_analysis, ai_summary, keywords,
        emotion, emotion_intensity, write_to_emotion_profile, open_at, is_public, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, false, $13)`,
      [
        letterId,
        userId,
        title || null,
        content,
        'text',
        allow_ai_analysis,
        analysis?.summary || null,
        analysis?.keywords || [],
        analysis?.emotion || null,
        analysis?.intensity || null,
        write_to_emotion_profile,
        open_at || null,
        now
      ]
    );

    if (analysis && write_to_emotion_profile) {
      await createEmotionRecord(userId, analysis, 'text', letterId);
    }
    if (analysis) {
      await createRiskEventIfNeeded(userId, analysis, 'private_letter', letterId, content);
    }

    const letter = await queryOne<PrivateLetter>('SELECT * FROM private_letters WHERE id = $1', [letterId]);
    res.status(201).json({ letter, emotion_analysis: analysis });
  } catch (error) {
    console.error('Create letter error:', error);
    res.status(500).json({ error: 'Failed to create letter' });
  }
});

router.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;

    const letter = await queryOne<PrivateLetter>(
      'SELECT * FROM private_letters WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
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

router.patch('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;
    const existing = await queryOne<PrivateLetter>(
      'SELECT * FROM private_letters WHERE id = $1 AND user_id = $2 AND deleted_at IS NULL',
      [id, userId]
    );

    if (!existing) {
      res.status(404).json({ error: 'Letter not found' });
      return;
    }

    const content = typeof req.body.content === 'string' ? req.body.content : existing.content;
    const title = req.body.title !== undefined ? req.body.title : existing.title;
    const allowAiAnalysis = req.body.allow_ai_analysis !== undefined ? Boolean(req.body.allow_ai_analysis) : existing.allow_ai_analysis;
    const writeToProfile = req.body.write_to_emotion_profile !== undefined ? Boolean(req.body.write_to_emotion_profile) : existing.write_to_emotion_profile;
    const openAt = req.body.open_at !== undefined ? req.body.open_at : existing.open_at;

    let analysis: EmotionAnalysisResult | null = null;
    if (allowAiAnalysis) {
      analysis = await analyzeText(content);
    }

    await execute(
      `UPDATE private_letters
       SET title = $1, content = $2, allow_ai_analysis = $3, ai_summary = $4, keywords = $5,
           emotion = $6, emotion_intensity = $7, write_to_emotion_profile = $8, open_at = $9
       WHERE id = $10 AND user_id = $11`,
      [
        title || null,
        content,
        allowAiAnalysis,
        analysis?.summary || null,
        analysis?.keywords || [],
        analysis?.emotion || null,
        analysis?.intensity || null,
        writeToProfile,
        openAt || null,
        id,
        userId
      ]
    );

    if (analysis && writeToProfile) {
      await createEmotionRecord(userId, analysis, 'text', id);
    }
    if (analysis) {
      await createRiskEventIfNeeded(userId, analysis, 'private_letter', id, content);
    }

    const letter = await queryOne<PrivateLetter>('SELECT * FROM private_letters WHERE id = $1', [id]);
    res.json({ letter, emotion_analysis: analysis });
  } catch (error) {
    console.error('Update letter error:', error);
    res.status(500).json({ error: 'Failed to update letter' });
  }
});

router.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const userId = req.user!.id;
    const deleted = await execute(
      'UPDATE private_letters SET deleted_at = $1 WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL',
      [new Date().toISOString(), id, userId]
    );

    if (deleted === 0) {
      res.status(404).json({ error: 'Letter not found' });
      return;
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete letter error:', error);
    res.status(500).json({ error: 'Failed to delete letter' });
  }
});

export default router;
