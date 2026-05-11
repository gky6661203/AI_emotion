import { Router, Response } from 'express';
import { query, queryOne, execute } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function average(values: number[]): number {
  if (values.length === 0) return 0;
  return values.reduce((sum, value) => sum + value, 0) / values.length;
}

async function computeSnapshot(userId: string) {
  const emotionRecords = await query<{ emotion: string; intensity: number; risk_detected: boolean; created_at: string }>(
    `SELECT emotion, intensity, risk_detected, created_at
     FROM emotion_records
     WHERE user_id = $1
     ORDER BY created_at DESC
     LIMIT 90`,
    [userId]
  );

  const letters = await query<{ emotion?: string; allow_ai_analysis: boolean; write_to_emotion_profile: boolean; created_at: string }>(
    `SELECT emotion, allow_ai_analysis, write_to_emotion_profile, created_at
     FROM private_letters
     WHERE user_id = $1 AND deleted_at IS NULL
     ORDER BY created_at DESC
     LIMIT 30`,
    [userId]
  );

  const voices = await query<{ emotion?: string; emotion_intensity?: number; risk_level: string; created_at: string }>(
    `SELECT emotion, emotion_intensity, risk_level, created_at
     FROM voice_records
     WHERE user_id = $1 AND deleted_at IS NULL
     ORDER BY created_at DESC
     LIMIT 30`,
    [userId]
  );

  const posts = await query<{ allow_comments: boolean; risk_level: string; created_at: string }>(
    `SELECT allow_comments, risk_level, created_at
     FROM public_posts
     WHERE user_id = $1 AND deleted_at IS NULL
     ORDER BY created_at DESC
     LIMIT 30`,
    [userId]
  );

  const counts = {
    emotion_records: emotionRecords.length,
    letters: letters.length,
    voices: voices.length,
    posts: posts.length
  };

  const emotionCounts: Record<string, number> = {};
  let intensitySum = 0;
  let riskCount = 0;

  for (const item of emotionRecords) {
    emotionCounts[item.emotion] = (emotionCounts[item.emotion] || 0) + 1;
    intensitySum += Number(item.intensity || 0);
    if (item.risk_detected) riskCount++;
  }
  for (const item of letters) {
    if (item.emotion) emotionCounts[item.emotion] = (emotionCounts[item.emotion] || 0) + 1;
  }
  for (const item of voices) {
    if (item.emotion) emotionCounts[item.emotion] = (emotionCounts[item.emotion] || 0) + 1;
    intensitySum += Number(item.emotion_intensity || 0);
    if (item.risk_level === 'high' || item.risk_level === 'critical') riskCount++;
  }
  for (const item of posts) {
    if (item.risk_level === 'high' || item.risk_level === 'critical') riskCount++;
  }

  const dominantEmotion = Object.entries(emotionCounts).sort((a, b) => b[1] - a[1])[0]?.[0] || 'neutral';
  const sampleSize = emotionRecords.length + voices.length;
  const averageIntensity = sampleSize > 0 ? intensitySum / sampleSize : 0;
  const riskRate = sampleSize > 0 ? riskCount / sampleSize : 0;

  const preferenceSignals = {
    prefersDirectAdvice: averageIntensity > 0.6,
    prefersVoice: voices.length >= letters.length,
    prefersPrivateWriting: letters.length >= posts.length,
    openToPublicInteraction: posts.filter((p) => p.allow_comments).length > 0,
    safetySensitive: riskRate > 0.15
  };

  const stateVector = {
    valence: clamp(0.5 + (dominantEmotion === 'happy' ? 0.3 : dominantEmotion === 'sad' ? -0.3 : dominantEmotion === 'angry' ? -0.2 : dominantEmotion === 'anxious' ? -0.15 : 0), 0, 1),
    arousal: clamp(averageIntensity, 0, 1),
    dominance: clamp(preferenceSignals.prefersDirectAdvice ? 0.6 : 0.4, 0, 1),
    social: clamp((posts.length + voices.length) / 20, 0, 1),
    cognitive: clamp((letters.length + emotionRecords.length) / 30, 0, 1)
  };

  const signalSummary = `最近主要情绪是${dominantEmotion}，平均强度${averageIntensity.toFixed(2)}，风险率${riskRate.toFixed(2)}。`;

  return {
    user_id: userId,
    dominant_emotion: dominantEmotion,
    average_intensity: averageIntensity,
    risk_rate: riskRate,
    signal_summary: signalSummary,
    preference_signals: preferenceSignals,
    state_vector: stateVector,
    counts,
    risk_count: riskCount
  };
}

router.post('/snapshot', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const snapshot = await computeSnapshot(userId);
    const now = new Date().toISOString();
    const snapshotId = `${userId}-${now.slice(0, 10)}`;

    await execute(
      `INSERT INTO user_profile_snapshots (
        id, user_id, dominant_emotion, average_intensity, risk_rate, signal_summary,
        preference_signals, state_vector, counts, risk_count, created_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7::jsonb, $8::jsonb, $9::jsonb, $10, $11)
      ON CONFLICT (user_id, snapshot_date) DO UPDATE SET
        dominant_emotion = EXCLUDED.dominant_emotion,
        average_intensity = EXCLUDED.average_intensity,
        risk_rate = EXCLUDED.risk_rate,
        signal_summary = EXCLUDED.signal_summary,
        preference_signals = EXCLUDED.preference_signals,
        state_vector = EXCLUDED.state_vector,
        counts = EXCLUDED.counts,
        risk_count = EXCLUDED.risk_count,
        updated_at = $11`,
      [
        snapshotId,
        userId,
        snapshot.dominant_emotion,
        snapshot.average_intensity,
        snapshot.risk_rate,
        snapshot.signal_summary,
        JSON.stringify(snapshot.preference_signals),
        JSON.stringify(snapshot.state_vector),
        JSON.stringify(snapshot.counts),
        snapshot.risk_count,
        now
      ]
    );

    res.json({ success: true, snapshot });
  } catch (error) {
    console.error('Create profile snapshot error:', error);
    res.status(500).json({ error: 'Failed to create profile snapshot' });
  }
});

router.get('/timeline', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const days = Math.min(parseInt(req.query.days as string) || 14, 90);

    const rows = await query<any>(
      `SELECT snapshot_date, dominant_emotion, average_intensity, risk_rate, signal_summary, state_vector, counts, created_at
       FROM user_profile_snapshots
       WHERE user_id = $1
       ORDER BY snapshot_date DESC
       LIMIT $2`,
      [userId, days]
    );

    res.json({ timeline: rows });
  } catch (error) {
    console.error('Get profile timeline error:', error);
    res.status(500).json({ error: 'Failed to get profile timeline' });
  }
});

router.get('/overview', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const snapshot = await computeSnapshot(req.user!.id);
    res.json(snapshot);
  } catch (error) {
    console.error('Get profile overview error:', error);
    res.status(500).json({ error: 'Failed to get profile overview' });
  }
});

export default router;
