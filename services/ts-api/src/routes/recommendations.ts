import { Router, Response } from 'express';
import { query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { Recommendation } from '../models';

const router = Router();

router.use(authMiddleware);

const safetyRecommendations: Recommendation[] = [
  { recommendation_type: 'safety', title: '先保证此刻安全', description: '请尽量离开危险环境，联系身边可信任的人。', priority: 1 },
  { recommendation_type: 'resource', title: '联系学校心理支持', description: '如果你愿意，可以联系辅导员、校心理中心或当地紧急求助热线。', priority: 2 },
  { recommendation_type: 'breathing', title: '做一次稳定呼吸', description: '先慢慢吸气、停顿、呼气，重复 3 分钟。', priority: 3 }
];

router.get('/current', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const user = req.user!;
    const userId = user.id;
    const limit = Math.min(parseInt(req.query.limit as string) || 5, 10);

    const profileOverview = await query<{ dominant_emotion: string; average_intensity: number; risk_rate: number; preference_signals: string; state_vector: string }>(
      `SELECT
         COALESCE((SELECT emotion FROM emotion_records WHERE user_id = $1 ORDER BY created_at DESC LIMIT 1), 'neutral') AS dominant_emotion,
         COALESCE((SELECT AVG(intensity) FROM emotion_records WHERE user_id = $1), 0) AS average_intensity,
         COALESCE((SELECT AVG(CASE WHEN risk_detected THEN 1 ELSE 0 END) FROM emotion_records WHERE user_id = $1), 0) AS risk_rate,
         '{}'::text AS preference_signals,
         '{}'::text AS state_vector`,
      [userId]
    );
    const profileState = profileOverview[0];

    if (user.risk_level === 'high' || user.risk_level === 'critical' || Number(profileState?.risk_rate || 0) > 0.2) {
      res.json({ recommendations: safetyRecommendations.slice(0, limit), risk_level: user.risk_level || 'high', dominant_emotion: profileState?.dominant_emotion || 'neutral', average_intensity: Number(profileState?.average_intensity || 0) });
      return;
    }

    const recentEmotions = await query<{ emotion: string; intensity: number; risk_detected: boolean }>(
      `SELECT emotion, intensity, risk_detected FROM emotion_records
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 10`,
      [userId]
    );

    if (recentEmotions.some((record) => record.risk_detected)) {
      res.json({ recommendations: safetyRecommendations.slice(0, limit), risk_level: 'medium' });
      return;
    }

    if (recentEmotions.length === 0) {
      const defaultRecommendations: Recommendation[] = [
        { recommendation_type: 'companion', title: '和 AI 说说', description: '从一句简单的心情开始，我会在这里倾听你。', priority: 1 },
        { recommendation_type: 'treehole', title: '写进私密树洞', description: '把今天的想法记录下来，只给自己看。', priority: 2 },
        { recommendation_type: 'voice', title: '录一段心情', description: '不想打字时，可以用语音记录此刻。', priority: 3 },
        { recommendation_type: 'relaxation', title: '短暂放松', description: '做一次深呼吸，给自己一点缓冲。', priority: 4 },
      ];
      res.json({ recommendations: defaultRecommendations.slice(0, limit), risk_level: user.risk_level });
      return;
    }

    const dominantEmotionCount: Record<string, number> = {};
    let averageIntensity = 0;
    for (const rec of recentEmotions) {
      dominantEmotionCount[rec.emotion] = (dominantEmotionCount[rec.emotion] || 0) + 1;
      averageIntensity += Number(rec.intensity);
    }
    averageIntensity = averageIntensity / recentEmotions.length;

    const topEmotion = Object.entries(dominantEmotionCount).sort((a, b) => b[1] - a[1])[0]?.[0] || 'neutral';

    const emotionRecommendations: Record<string, Recommendation[]> = {
      happy: [
        { recommendation_type: 'treehole', title: '记录美好', description: '把今天的美好时刻写下来，留给之后的自己。', priority: 1 },
        { recommendation_type: 'companion', title: '分享这份好心情', description: '和 AI 继续聊聊今天发生的好事。', priority: 2 },
      ],
      sad: [
        { recommendation_type: 'companion', title: '先被好好听见', description: '不用急着变好，可以先把难过说出来。', priority: 1 },
        { recommendation_type: 'treehole', title: '写下来整理一下', description: '把复杂的感受放进私密树洞。', priority: 2 },
        { recommendation_type: 'relaxation', title: '低负担休息', description: '给自己十分钟，不做评价地休息一下。', priority: 3 },
      ],
      angry: [
        { recommendation_type: 'breathing', title: '先让身体慢下来', description: '深呼吸几轮，再决定下一步。', priority: 1 },
        { recommendation_type: 'treehole', title: '写下让你生气的点', description: '先把事情和感受分开。', priority: 2 },
      ],
      anxious: [
        { recommendation_type: 'breathing', title: '3 分钟呼吸练习', description: '把注意力带回当下，先稳定一点。', priority: 1 },
        { recommendation_type: 'plan', title: '拆小任务', description: '把最担心的事拆成一个很小的下一步。', priority: 2 },
        { recommendation_type: 'companion', title: '说说你的担心', description: '我可以陪你一起理清焦虑来源。', priority: 3 },
      ],
      lonely: [
        { recommendation_type: 'companion', title: '先聊一会儿', description: '你不用一个人消化所有感受。', priority: 1 },
        { recommendation_type: 'treehole', title: '写给此刻的自己', description: '把想被听见的话先安全地放下来。', priority: 2 },
      ],
      neutral: [
        { recommendation_type: 'treehole', title: '记录今日状态', description: '简单写几句，也能帮助之后看见变化。', priority: 1 },
        { recommendation_type: 'voice', title: '语音心情记录', description: '用一分钟说说今天的状态。', priority: 2 },
      ]
    };

    const recommendations = emotionRecommendations[topEmotion] || emotionRecommendations.neutral;
    if (averageIntensity > 0.75) {
      recommendations.push({ recommendation_type: 'resource', title: '找现实支持', description: '如果强度持续很高，可以考虑联系可信任的人或校内支持资源。', priority: 4 });
    }

    res.json({ recommendations: recommendations.slice(0, limit), dominant_emotion: topEmotion, average_intensity: averageIntensity, risk_level: user.risk_level });
  } catch (error) {
    console.error('Get recommendations error:', error);
    res.status(500).json({ error: 'Failed to get recommendations' });
  }
});

router.post('/feedback', async (req: AuthenticatedRequest, res: Response) => {
  res.json({ success: true });
});

export default router;
