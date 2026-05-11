import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const recommendationType = String(req.body.recommendation_type || '').trim();
    const title = String(req.body.title || '').trim();
    const feedback = String(req.body.feedback || '').trim();
    const rating = Number(req.body.rating || 0);
    const context = typeof req.body.context === 'string' ? req.body.context.trim() : null;

    if (!recommendationType || !feedback) {
      res.status(400).json({ error: 'recommendation_type and feedback are required' });
      return;
    }

    const feedbackId = uuidv4();
    await execute(
      `INSERT INTO recommendation_feedback (
        id, user_id, recommendation_type, title, feedback, rating, context, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)` ,
      [feedbackId, req.user!.id, recommendationType, title || null, feedback, Number.isFinite(rating) ? rating : null, context, new Date().toISOString()]
    );

    res.status(201).json({ success: true, feedback_id: feedbackId });
  } catch (error) {
    console.error('Create recommendation feedback error:', error);
    res.status(500).json({ error: 'Failed to create recommendation feedback' });
  }
});

router.get('/recent', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 10, 20);
    const rows = await query<any>(
      `SELECT recommendation_type, title, feedback, rating, context, created_at
       FROM recommendation_feedback
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2`,
      [req.user!.id, limit]
    );

    res.json({ feedback: rows });
  } catch (error) {
    console.error('Get recommendation feedback error:', error);
    res.status(500).json({ error: 'Failed to get recommendation feedback' });
  }
});

export default router;
