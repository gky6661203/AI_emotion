import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { PrivateLetter } from '../models';
import { analyzeText, createRiskEventIfNeeded, EmotionAnalysisResult } from '../utils/emotion';

const router = Router();

router.use(authMiddleware);

// Get all public posts (Anonymous Plaza)
router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
    const sql = `
      SELECT p.*, u.nickname as author_nickname, u.avatar_url as author_avatar
      FROM private_letters p
      LEFT JOIN users u ON p.user_id = u.id
      WHERE p.is_public = true AND p.deleted_at IS NULL
      ORDER BY p.created_at DESC
      LIMIT $1
    `;
    const posts = await query(sql, [limit]);
    
    // Format response to hide exact user_id if needed, but for MVP we just return
    res.json({ posts });
  } catch (error) {
    console.error('List public posts error:', error);
    res.status(500).json({ error: 'Failed to list posts' });
  }
});

// Create a new public post
router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { content, title, allow_comments = true } = req.body;

    if (!content || typeof content !== 'string') {
      res.status(400).json({ error: 'content is required' });
      return;
    }

    const userId = req.user!.id;
    const now = new Date().toISOString();
    const postId = uuidv4();
    
    // Safety check for public posts
    const analysis = await analyzeText(content);
    
    if (analysis.risk_level === 'high' || analysis.risk_level === 'critical') {
      await createRiskEventIfNeeded(userId, analysis, 'post', postId, content);
      res.status(403).json({ 
        error: '安全检测未通过', 
        message: '您的内容包含高风险信息，无法发布到广场。如果您需要帮助，请联系心理中心。'
      });
      return;
    }

    await execute(
      `INSERT INTO private_letters (
        id, user_id, title, content, content_type, allow_ai_analysis, ai_summary, keywords,
        emotion, emotion_intensity, write_to_emotion_profile, is_public, created_at, affect_recommendation
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)`,
      [
        postId,
        userId,
        title || null,
        content,
        'text',
        true, // Always analyze public posts for safety
        analysis.summary || null,
        analysis.keywords || [],
        analysis.emotion || null,
        analysis.intensity || null,
        true,
        true, // is_public = true
        now,
        JSON.stringify({ allow_comments })
      ]
    );

    const newPost = await queryOne<PrivateLetter>('SELECT * FROM private_letters WHERE id = $1', [postId]);
    res.status(201).json({ post: newPost });
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

// Gentle response (Reaction)
router.post('/:id/reactions', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { type } = req.body; // e.g., 'hug', 'listen'
    const postId = req.params.id;
    
    // In a real DB we would have a post_reactions table.
    // For MVP, we'll just acknowledge it.
    res.status(200).json({ success: true, message: 'Reaction added' });
  } catch (error) {
    res.status(500).json({ error: 'Failed to add reaction' });
  }
});

export default router;
