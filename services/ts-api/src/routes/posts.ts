import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query, queryOne } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { AnonymousProfile, PublicPost, PostReaction, PostReport } from '../models';
import { analyzeText, createRiskEventIfNeeded } from '../utils/emotion';

const router = Router();

router.use(authMiddleware);

const allowedReactionTypes = new Set(['listen', 'hug', 'strength', 'same', 'rest', 'not_alone']);

async function ensureAnonymousProfile(userId: string): Promise<AnonymousProfile> {
  let profile = await queryOne<AnonymousProfile>('SELECT * FROM anonymous_profiles WHERE user_id = $1', [userId]);
  if (profile) return profile;

  await execute(
    `INSERT INTO anonymous_profiles (user_id, display_name)
     VALUES ($1, $2)
     ON CONFLICT (user_id) DO NOTHING`,
    [userId, '匿名同学']
  );

  profile = await queryOne<AnonymousProfile>('SELECT * FROM anonymous_profiles WHERE user_id = $1', [userId]);
  if (!profile) throw new Error('Failed to create anonymous profile');
  return profile;
}

function normalizePostRow(row: PublicPost & { reaction_counts_json?: Record<string, number> | null }): PublicPost {
  return {
    ...row,
    reaction_counts: row.reaction_counts_json || {}
  };
}

router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const limit = Math.min(parseInt(req.query.limit as string) || 50, 100);
    const topic = typeof req.query.topic === 'string' ? req.query.topic : undefined;
    const keyword = typeof req.query.keyword === 'string' ? req.query.keyword : undefined;

    const params: unknown[] = [];
    const filters = [`p.deleted_at IS NULL`, `p.moderation_status = 'approved'`];

    if (topic) {
      params.push(topic);
      filters.push(`p.topic = $${params.length}`);
    }
    if (keyword) {
      params.push(`%${keyword}%`);
      filters.push(`(p.title ILIKE $${params.length} OR p.content ILIKE $${params.length})`);
    }

    params.push(limit);
    const rows = await query<PublicPost & { reaction_counts_json?: Record<string, number> | null }>(
      `SELECT p.*, ap.display_name AS author_display_name, ap.avatar_url AS author_avatar_url,
              COALESCE(r.reaction_counts, '{}'::json) AS reaction_counts_json
       FROM public_posts p
       LEFT JOIN anonymous_profiles ap ON ap.id = p.anonymous_profile_id
       LEFT JOIN (
         SELECT post_id, json_object_agg(reaction_type, count) AS reaction_counts
         FROM (
           SELECT post_id, reaction_type, COUNT(*)::int AS count
           FROM post_reactions
           GROUP BY post_id, reaction_type
         ) grouped_reactions
         GROUP BY post_id
       ) r ON r.post_id = p.id
       WHERE ${filters.join(' AND ')}
       ORDER BY p.created_at DESC
       LIMIT $${params.length}`,
      params
    );

    res.json({ posts: rows.map(normalizePostRow) });
  } catch (error) {
    console.error('List public posts error:', error);
    res.status(500).json({ error: 'Failed to list posts' });
  }
});

router.post('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { content, title, topic, allow_comments = true, link_match_request = false } = req.body;

    if (!content || typeof content !== 'string') {
      res.status(400).json({ error: 'content is required' });
      return;
    }

    const userId = req.user!.id;
    const profile = await ensureAnonymousProfile(userId);
    const now = new Date().toISOString();
    const postId = uuidv4();
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
      `INSERT INTO public_posts (
        id, user_id, anonymous_profile_id, title, content, topic, allow_comments, link_match_request,
        ai_summary, keywords, emotion, emotion_intensity, risk_level, moderation_status, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, 'approved', $14, $15)`,
      [
        postId,
        userId,
        profile.id,
        title || null,
        content,
        topic || null,
        Boolean(allow_comments),
        Boolean(link_match_request),
        analysis.summary || null,
        analysis.keywords || [],
        analysis.emotion || null,
        analysis.intensity || null,
        analysis.risk_level,
        now,
        now
      ]
    );

    const post = await queryOne<PublicPost>('SELECT * FROM public_posts WHERE id = $1', [postId]);
    res.status(201).json({ post });
  } catch (error) {
    console.error('Create post error:', error);
    res.status(500).json({ error: 'Failed to create post' });
  }
});

router.get('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const post = await queryOne<PublicPost & { reaction_counts_json?: Record<string, number> | null }>(
      `SELECT p.*, ap.display_name AS author_display_name, ap.avatar_url AS author_avatar_url,
              COALESCE(r.reaction_counts, '{}'::json) AS reaction_counts_json
       FROM public_posts p
       LEFT JOIN anonymous_profiles ap ON ap.id = p.anonymous_profile_id
       LEFT JOIN (
         SELECT post_id, json_object_agg(reaction_type, count) AS reaction_counts
         FROM (
           SELECT post_id, reaction_type, COUNT(*)::int AS count
           FROM post_reactions
           GROUP BY post_id, reaction_type
         ) grouped_reactions
         GROUP BY post_id
       ) r ON r.post_id = p.id
       WHERE p.id = $1 AND p.deleted_at IS NULL AND p.moderation_status = 'approved'`,
      [req.params.id]
    );

    if (!post) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    res.json({ post: normalizePostRow(post) });
  } catch (error) {
    console.error('Get post error:', error);
    res.status(500).json({ error: 'Failed to get post' });
  }
});

router.delete('/:id', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const deleted = await execute(
      'UPDATE public_posts SET deleted_at = $1 WHERE id = $2 AND user_id = $3 AND deleted_at IS NULL',
      [new Date().toISOString(), req.params.id, req.user!.id]
    );

    if (deleted === 0) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    res.json({ success: true });
  } catch (error) {
    console.error('Delete post error:', error);
    res.status(500).json({ error: 'Failed to delete post' });
  }
});

router.post('/:id/reactions', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const type = String(req.body.type || '').trim();
    if (!allowedReactionTypes.has(type)) {
      res.status(400).json({ error: 'invalid reaction type' });
      return;
    }

    const post = await queryOne<PublicPost>(
      `SELECT * FROM public_posts WHERE id = $1 AND deleted_at IS NULL AND moderation_status = 'approved'`,
      [req.params.id]
    );
    if (!post) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    await execute(
      `INSERT INTO post_reactions (id, post_id, user_id, reaction_type, created_at)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (post_id, user_id, reaction_type) DO NOTHING`,
      [uuidv4(), req.params.id, req.user!.id, type, new Date().toISOString()]
    );

    const reaction = await queryOne<PostReaction>(
      'SELECT * FROM post_reactions WHERE post_id = $1 AND user_id = $2 AND reaction_type = $3',
      [req.params.id, req.user!.id, type]
    );

    res.status(201).json({ success: true, reaction });
  } catch (error) {
    console.error('Add reaction error:', error);
    res.status(500).json({ error: 'Failed to add reaction' });
  }
});

router.post('/:id/report', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const reason = String(req.body.reason || '').trim();
    const description = typeof req.body.description === 'string' ? req.body.description.trim() : null;

    if (!reason) {
      res.status(400).json({ error: 'reason is required' });
      return;
    }

    const post = await queryOne<PublicPost>('SELECT * FROM public_posts WHERE id = $1 AND deleted_at IS NULL', [req.params.id]);
    if (!post) {
      res.status(404).json({ error: 'Post not found' });
      return;
    }

    const reportId = uuidv4();
    await execute(
      `INSERT INTO post_reports (id, post_id, reporter_user_id, reason, description, status, created_at)
       VALUES ($1, $2, $3, $4, $5, 'pending', $6)`,
      [reportId, req.params.id, req.user!.id, reason, description, new Date().toISOString()]
    );

    const report = await queryOne<PostReport>('SELECT * FROM post_reports WHERE id = $1', [reportId]);
    res.status(201).json({ success: true, report });
  } catch (error) {
    console.error('Report post error:', error);
    res.status(500).json({ error: 'Failed to report post' });
  }
});

export default router;
