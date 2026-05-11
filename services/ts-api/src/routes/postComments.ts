import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { PublicPost, PostComment } from '../models';
import { analyzeText, createRiskEventIfNeeded } from '../utils/emotion';

const router = Router();

router.use(authMiddleware);

function normalizeCommentRow(row: PostComment): PostComment {
  return row;
}

router.get('/:id/comments', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const post = await queryOne<PublicPost>("SELECT * FROM public_posts WHERE id = $1 AND deleted_at IS NULL AND moderation_status = 'approved'", [req.params.id]);
    if (!post) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    const comments = await query<PostComment>(
      `SELECT * FROM post_comments
       WHERE post_id = $1 AND deleted_at IS NULL AND moderation_status = 'approved'
       ORDER BY created_at ASC`,
      [req.params.id]
    );

    res.json({ comments: comments.map(normalizeCommentRow) });
  } catch (error) {
    console.error('List comments error:', error);
    res.status(500).json({ error: 'Failed to list comments' });
  }
});

router.post('/:id/comments', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const content = String(req.body.content || '').trim();
    if (!content) {
      res.status(400).json({ error: 'content is required' });
      return;
    }

    const post = await queryOne<PublicPost>("SELECT * FROM public_posts WHERE id = $1 AND deleted_at IS NULL AND moderation_status = 'approved'", [req.params.id]);
    if (!post) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }
    if (!post.allow_comments) {
      res.status(403).json({ error: 'Comments are disabled for this post' });
      return;
    }

    const analysis = await analyzeText(content);
    if (analysis.risk_level === 'high' || analysis.risk_level === 'critical') {
      await createRiskEventIfNeeded(req.user!.id, analysis, 'comment', req.params.id, content);
      res.status(403).json({ error: '安全检测未通过', message: '评论内容包含高风险信息，已拦截。' });
      return;
    }

    const commentId = uuidv4();
    const now = new Date().toISOString();
    await execute(
      `INSERT INTO post_comments (
        id, post_id, user_id, content, ai_summary, keywords, emotion, emotion_intensity,
        risk_level, moderation_status, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'approved', $10, $11)`,
      [
        commentId,
        req.params.id,
        req.user!.id,
        content,
        analysis.summary || null,
        analysis.keywords || [],
        analysis.emotion || null,
        analysis.intensity || null,
        analysis.risk_level,
        now,
        now
      ]
    );

    const comment = await queryOne<PostComment>('SELECT * FROM post_comments WHERE id = $1', [commentId]);
    res.status(201).json({ comment });
  } catch (error) {
    console.error('Create comment error:', error);
    res.status(500).json({ error: 'Failed to create comment' });
  }
});

router.delete('/:postId/comments/:commentId', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const deleted = await execute(
      'UPDATE post_comments SET deleted_at = $1 WHERE id = $2 AND post_id = $3 AND user_id = $4 AND deleted_at IS NULL',
      [new Date().toISOString(), req.params.commentId, req.params.postId, req.user!.id]
    );

    if (deleted === 0) {
      res.status(404).json({ error: 'Comment not found' });
      return;
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete comment error:', error);
    res.status(500).json({ error: 'Failed to delete comment' });
  }
});

export default router;
