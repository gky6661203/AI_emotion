import { Router, Response } from 'express';
import { query, execute } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function fitScore(target: number, candidate: number): number {
  return 1 - Math.abs(target - candidate);
}

router.get('/suggestions', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const limit = Math.min(parseInt(req.query.limit as string) || 5, 10);

    const profileRows = await query<{
      dominant_emotion: string;
      average_intensity: number;
      risk_rate: number;
      state_vector: any;
      preference_signals: any;
    }>(
      `SELECT dominant_emotion, average_intensity, risk_rate, state_vector, preference_signals
       FROM user_profile_snapshots
       WHERE user_id = $1
       ORDER BY snapshot_date DESC
       LIMIT 1`,
      [userId]
    );

    const profile = profileRows[0];
    const baseState = profile?.state_vector || { valence: 0.5, arousal: 0.5, dominance: 0.5, social: 0.5, cognitive: 0.5 };
    const riskRate = Number(profile?.risk_rate || 0);

    const candidates = await query<{
      user_id: string;
      state_vector: any;
      dominant_emotion: string;
      preference_signals: any;
      signal_summary: string;
      created_at: string;
    }>(
      `SELECT s.user_id, s.state_vector, s.dominant_emotion, s.preference_signals, s.signal_summary, s.created_at
       FROM user_profile_snapshots s
       WHERE s.user_id <> $1
       ORDER BY s.created_at DESC
       LIMIT 50`,
      [userId]
    );

    const scored = candidates.map((candidate) => {
      const state = candidate.state_vector || {};
      const valenceScore = fitScore(baseState.valence || 0.5, Number(state.valence || 0.5));
      const arousalScore = fitScore(baseState.arousal || 0.5, Number(state.arousal || 0.5));
      const socialScore = fitScore(baseState.social || 0.5, Number(state.social || 0.5));
      const cognitiveScore = fitScore(baseState.cognitive || 0.5, Number(state.cognitive || 0.5));
      const emotionBonus = candidate.dominant_emotion === profile?.dominant_emotion ? 0.08 : 0;
      const total = clamp((valenceScore * 0.28 + arousalScore * 0.22 + socialScore * 0.18 + cognitiveScore * 0.18 + emotionBonus + (riskRate > 0.2 ? 0.04 : 0)), 0, 1);
      return {
        user_id: candidate.user_id,
        dominant_emotion: candidate.dominant_emotion,
        signal_summary: candidate.signal_summary,
        score: total,
        reason: riskRate > 0.2 ? '当前状态偏谨慎，优先匹配稳定型搭子' : `与你的画像相似度 ${Math.round(total * 100)}%`
      };
    }).sort((a, b) => b.score - a.score).slice(0, limit);

    res.json({
      suggestions: scored,
      profile: {
        dominant_emotion: profile?.dominant_emotion || 'neutral',
        average_intensity: Number(profile?.average_intensity || 0),
        risk_rate: riskRate,
        state_vector: baseState
      }
    });
  } catch (error) {
    console.error('Get match suggestions error:', error);
    res.status(500).json({ error: 'Failed to get match suggestions' });
  }
});

router.post('/request', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { match_type = 'companion', note } = req.body || {};
    const userId = req.user!.id;
    const now = new Date().toISOString();
    const requestId = `${userId}-${now}`;

    await execute(
      `INSERT INTO match_requests (id, user_id, match_type, note, status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, 'open', $5, $5)`,
      [requestId, userId, String(match_type), note || null, now]
    );

    res.json({ success: true, request_id: requestId });
  } catch (error) {
    console.error('Create match request error:', error);
    res.status(500).json({ error: 'Failed to create match request' });
  }
});

router.get('/requests', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const requests = await query<{
      id: string;
      match_type: string;
      note?: string;
      status: string;
      created_at: string;
    }>(
      `SELECT id, match_type, note, status, created_at
       FROM match_requests
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 20`,
      [userId]
    );

    res.json({ requests });
  } catch (error) {
    console.error('List match requests error:', error);
    res.status(500).json({ error: 'Failed to list match requests' });
  }
});

router.post('/close', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const requestId = String(req.body?.request_id || '');
    if (!requestId) {
      res.status(400).json({ error: 'request_id is required' });
      return;
    }

    await execute(
      `UPDATE match_requests SET status = 'closed', updated_at = $2 WHERE id = $1 AND user_id = $3`,
      [requestId, new Date().toISOString(), userId]
    );

    res.json({ success: true });
  } catch (error) {
    console.error('Close match request error:', error);
    res.status(500).json({ error: 'Failed to close match request' });
  }
});

export default router;
