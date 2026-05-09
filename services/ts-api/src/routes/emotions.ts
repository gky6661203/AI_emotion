import { Router, Response } from 'express';
import { query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { EmotionRecord, EmotionDistributionItem } from '../models';

const router = Router();

router.use(authMiddleware);

function startOfToday(): string {
  const date = new Date();
  date.setHours(0, 0, 0, 0);
  return date.toISOString();
}

function summarize(records: EmotionRecord[]) {
  if (records.length === 0) {
    return {
      dominant_emotion: 'neutral',
      average_intensity: 0,
      total_records: 0,
      risk_events_count: 0,
      emotion_distribution: [] as EmotionDistributionItem[],
      keywords: [] as string[],
      summary: '暂无情绪记录，可以从一次聊天、树洞或语音记录开始。'
    };
  }

  const emotionCounts: Record<string, number> = {};
  const keywordCounts: Record<string, number> = {};
  let totalIntensity = 0;
  let riskCount = 0;

  for (const record of records) {
    emotionCounts[record.emotion] = (emotionCounts[record.emotion] || 0) + 1;
    totalIntensity += Number(record.intensity);
    if (record.risk_detected) riskCount++;
    for (const keyword of record.keywords || []) {
      keywordCounts[keyword] = (keywordCounts[keyword] || 0) + 1;
    }
  }

  const emotionDistribution = Object.entries(emotionCounts).map(([emotion, count]) => ({ emotion, count }));
  const dominantEmotion = emotionDistribution.reduce((max, curr) => curr.count > max.count ? curr : max).emotion;
  const keywords = Object.entries(keywordCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 8)
    .map(([keyword]) => keyword);
  const averageIntensity = totalIntensity / records.length;

  return {
    dominant_emotion: dominantEmotion,
    average_intensity: averageIntensity,
    total_records: records.length,
    risk_events_count: riskCount,
    emotion_distribution: emotionDistribution,
    keywords,
    summary: `这段时间主要情绪是 ${dominantEmotion}，平均强度 ${averageIntensity.toFixed(2)}。${riskCount > 0 ? '系统检测到需要更多关注的风险表达，请优先照顾安全。' : '整体记录可作为自我观察参考。'}`
  };
}

router.get('/today', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const records = await query<EmotionRecord>(
      `SELECT * FROM emotion_records WHERE user_id = $1 AND created_at >= $2 ORDER BY created_at DESC`,
      [userId, startOfToday()]
    );
    res.json({ user_id: userId, date: new Date().toISOString().slice(0, 10), ...summarize(records), recent_records: records.slice(0, 5) });
  } catch (error) {
    console.error('Get today emotion error:', error);
    res.status(500).json({ error: 'Failed to get today emotion' });
  }
});

router.get('/trends', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const days = Math.min(parseInt(req.query.days as string) || 7, 30);
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days + 1);
    startDate.setHours(0, 0, 0, 0);

    const rows = await query<{ date: string; average_intensity: number; count: number; risk_count: number }>(
      `SELECT DATE(created_at) AS date,
              AVG(intensity) AS average_intensity,
              COUNT(*) AS count,
              SUM(CASE WHEN risk_detected THEN 1 ELSE 0 END) AS risk_count
       FROM emotion_records
       WHERE user_id = $1 AND created_at >= $2
       GROUP BY DATE(created_at)
       ORDER BY date ASC`,
      [userId, startDate.toISOString()]
    );

    res.json({ trends: rows });
  } catch (error) {
    console.error('Get emotion trends error:', error);
    res.status(500).json({ error: 'Failed to get emotion trends' });
  }
});

router.get('/report', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const days = Math.min(parseInt(req.query.days as string) || 7, 30);

    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);
    const periodStart = startDate.toISOString();
    const periodEnd = new Date().toISOString();

    const records = await query<EmotionRecord>(
      `SELECT * FROM emotion_records
       WHERE user_id = $1 AND created_at >= $2 AND created_at <= $3
       ORDER BY created_at DESC`,
      [userId, periodStart, periodEnd]
    );

    res.json({
      user_id: userId,
      period_start: periodStart,
      period_end: periodEnd,
      ...summarize(records),
      recent_records: records.slice(0, 10)
    });
  } catch (error) {
    console.error('Get emotion report error:', error);
    res.status(500).json({ error: 'Failed to get emotion report' });
  }
});

export default router;
