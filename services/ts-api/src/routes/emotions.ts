import { Router, Response } from 'express';
import { query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { EmotionRecord, EmotionDistributionItem } from '../models';

const router = Router();

router.use(authMiddleware);

router.get('/report', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const days = parseInt(req.query.days as string) || 7;

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    const periodStart = startDate.toISOString();
    const periodEnd = new Date().toISOString();

    const records = query<EmotionRecord>(
      `SELECT * FROM emotion_records
       WHERE user_id = ? AND created_at >= ? AND created_at <= ?
       ORDER BY created_at DESC`,
      [userId, periodStart, periodEnd]
    );

    if (records.length === 0) {
      res.json({
        user_id: userId,
        period_start: periodStart,
        period_end: periodEnd,
        dominant_emotion: 'neutral',
        average_intensity: 0,
        total_records: 0,
        risk_events_count: 0,
        emotion_distribution: [],
        recent_records: []
      });
      return;
    }

    const emotionCounts: Record<string, number> = {};
    let totalIntensity = 0;
    let riskCount = 0;

    for (const record of records) {
      emotionCounts[record.emotion] = (emotionCounts[record.emotion] || 0) + 1;
      totalIntensity += record.intensity;
      if (record.risk_detected) riskCount++;
    }

    const emotionDistribution: EmotionDistributionItem[] = Object.entries(emotionCounts).map(
      ([emotion, count]) => ({ emotion, count })
    );

    const dominantEmotion = emotionDistribution.reduce((max, curr) =>
      curr.count > max.count ? curr : max
    ).emotion;

    const recentRecords = records.slice(0, 10);

    res.json({
      user_id: userId,
      period_start: periodStart,
      period_end: periodEnd,
      dominant_emotion: dominantEmotion,
      average_intensity: totalIntensity / records.length,
      total_records: records.length,
      risk_events_count: riskCount,
      emotion_distribution: emotionDistribution,
      recent_records: recentRecords
    });
  } catch (error) {
    console.error('Get emotion report error:', error);
    res.status(500).json({ error: 'Failed to get emotion report' });
  }
});

export default router;
