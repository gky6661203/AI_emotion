import { Router, Response } from 'express';
import { query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value));
}

function dayOfWeekDistribution(records: { created_at: string }[]): Record<string, number> {
  const buckets: Record<string, number> = {
    '0': 0, '1': 0, '2': 0, '3': 0, '4': 0, '5': 0, '6': 0
  };
  for (const record of records) {
    const day = new Date(record.created_at).getDay();
    buckets[String(day)] = (buckets[String(day)] || 0) + 1;
  }
  return buckets;
}

router.get('/overview', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;

    const emotionRecords = await query<{ emotion: string; intensity: number; source: string; risk_detected: boolean; created_at: string }>(
      `SELECT emotion, intensity, source, risk_detected, created_at
       FROM emotion_records
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 90`,
      [userId]
    );

    const posts = await query<{ content: string; topic?: string; created_at: string; risk_level: string; allow_comments: boolean; link_match_request: boolean }>(
      `SELECT content, topic, created_at, risk_level, allow_comments, link_match_request
       FROM public_posts
       WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT 30`,
      [userId]
    );

    const letters = await query<{ content: string; emotion?: string; allow_ai_analysis: boolean; write_to_emotion_profile: boolean; created_at: string }>(
      `SELECT content, emotion, allow_ai_analysis, write_to_emotion_profile, created_at
       FROM private_letters
       WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT 30`,
      [userId]
    );

    const voices = await query<{ emotion?: string; emotion_intensity?: number; risk_level: string; allow_ai_analysis: boolean; created_at: string }>(
      `SELECT emotion, emotion_intensity, risk_level, allow_ai_analysis, created_at
       FROM voice_records
       WHERE user_id = $1 AND deleted_at IS NULL
       ORDER BY created_at DESC
       LIMIT 30`,
      [userId]
    );

    const totalEntries = emotionRecords.length + posts.length + letters.length + voices.length;

    const emotionCounts: Record<string, number> = {};
    let avgIntensitySum = 0;
    let riskCount = 0;
    let activeContentCount = 0;

    for (const item of emotionRecords) {
      emotionCounts[item.emotion] = (emotionCounts[item.emotion] || 0) + 1;
      avgIntensitySum += Number(item.intensity || 0);
      if (item.risk_detected) riskCount++;
    }

    for (const post of posts) {
      if (post.risk_level === 'high' || post.risk_level === 'critical') riskCount++;
      activeContentCount += post.allow_comments ? 1 : 0;
    }

    for (const letter of letters) {
      if (letter.emotion) {
        emotionCounts[letter.emotion] = (emotionCounts[letter.emotion] || 0) + 1;
      }
      if (letter.allow_ai_analysis) activeContentCount++;
    }

    for (const voice of voices) {
      if (voice.emotion) {
        emotionCounts[voice.emotion] = (emotionCounts[voice.emotion] || 0) + 1;
      }
      avgIntensitySum += Number(voice.emotion_intensity || 0);
      if (voice.risk_level === 'high' || voice.risk_level === 'critical') riskCount++;
    }

    const dominantEmotion = Object.entries(emotionCounts).sort((a, b) => b[1] - a[1])[0]?.[0] || 'neutral';
    const averageIntensity = totalEntries > 0 ? avgIntensitySum / totalEntries : 0;
    const riskRate = totalEntries > 0 ? riskCount / totalEntries : 0;

    const dayBuckets = dayOfWeekDistribution([...emotionRecords, ...voices]);
    const bestDay = Object.entries(dayBuckets).sort((a, b) => b[1] - a[1])[0]?.[0] || '1';
    const bestDayLabelMap: Record<string, string> = {
      '0': '周日', '1': '周一', '2': '周二', '3': '周三', '4': '周四', '5': '周五', '6': '周六'
    };

    const preferenceSignals = {
      prefersDirectAdvice: clamp(averageIntensity, 0, 1) > 0.6,
      prefersVoice: voices.length > letters.length,
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

    const summary = `最近主要情绪是${dominantEmotion}，平均强度${averageIntensity.toFixed(2)}，更常在${bestDayLabelMap[bestDay] || '工作日'}留下记录。`;

    res.json({
      user_id: userId,
      dominant_emotion: dominantEmotion,
      average_intensity: averageIntensity,
      risk_rate: riskRate,
      signal_summary: summary,
      preferred_day: bestDayLabelMap[bestDay] || '周一',
      preference_signals: preferenceSignals,
      state_vector: stateVector,
      counts: {
        emotion_records: emotionRecords.length,
        posts: posts.length,
        letters: letters.length,
        voices: voices.length
      },
      highlights: {
        active_content_count: activeContentCount,
        risk_count: riskCount,
        allow_comment_posts: posts.filter((p) => p.allow_comments).length,
        voice_allowed_count: voices.filter((v) => v.allow_ai_analysis).length,
        letter_profile_write_count: letters.filter((l) => l.write_to_emotion_profile).length
      }
    });
  } catch (error) {
    console.error('Get profile overview error:', error);
    res.status(500).json({ error: 'Failed to get profile overview' });
  }
});

export default router;
