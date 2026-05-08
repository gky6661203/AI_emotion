import { Router, Response } from 'express';
import { query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { Recommendation } from '../models';

const router = Router();

router.use(authMiddleware);

router.get('/current', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const limit = parseInt(req.query.limit as string) || 5;

    const recentEmotions = await query<{ emotion: string; intensity: number }>(
      `SELECT emotion, intensity FROM emotion_records
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 10`,
      [userId]
    );

    if (recentEmotions.length === 0) {
      const defaultRecommendations: Recommendation[] = [
        { recommendation_type: 'companion', title: '找人聊聊', description: '和朋友或家人谈谈你的感受', priority: 1 },
        { recommendation_type: 'treehole', title: '写树洞', description: '把你的心事写下来', priority: 2 },
        { recommendation_type: 'relaxation', title: '放松一下', description: '深呼吸，休息一会儿', priority: 3 },
      ];
      res.json({ recommendations: defaultRecommendations });
      return;
    }

    const dominantEmotionCount: Record<string, number> = {};
    for (const rec of recentEmotions) {
      dominantEmotionCount[rec.emotion] = (dominantEmotionCount[rec.emotion] || 0) + 1;
    }

    const topEmotion = Object.entries(dominantEmotionCount).sort((a, b) => b[1] - a[1])[0]?.[0] || 'neutral';

    const emotionRecommendations: Record<string, Recommendation[]> = {
      happy: [
        { recommendation_type: 'companion', title: '分享快乐', description: '和朋友分享你的好心情！', priority: 1 },
        { recommendation_type: 'treehole', title: '记录美好', description: '写下今天的美好时刻', priority: 2 },
      ],
      sad: [
        { recommendation_type: 'companion', title: '找人聊聊', description: '和朋友或家人谈谈你的感受', priority: 1 },
        { recommendation_type: 'treehole', title: '写下来', description: '把心情写下来可能会好些', priority: 2 },
      ],
      angry: [
        { recommendation_type: 'relaxation', title: '深呼吸', description: '深呼吸，试着冷静下来', priority: 1 },
        { recommendation_type: 'companion', title: '倾诉', description: '找信任的人说说', priority: 2 },
      ],
      anxious: [
        { recommendation_type: 'relaxation', title: '放松练习', description: '深呼吸，专注于当下', priority: 1 },
        { recommendation_type: 'companion', title: '寻求支持', description: '和身边的人谈谈你的担忧', priority: 2 },
      ],
      lonely: [
        { recommendation_type: 'companion', title: '联系他人', description: '给朋友或家人发消息', priority: 1 },
        { recommendation_type: 'treehole', title: '写树洞', description: '在这里倾诉你的心事', priority: 2 },
      ],
      neutral: [
        { recommendation_type: 'treehole', title: '写树洞', description: '记录一下今天的想法', priority: 1 },
        { recommendation_type: 'relaxation', title: '休息一下', description: '给自己一点放松时间', priority: 2 },
      ]
    };

    const recommendations = emotionRecommendations[topEmotion] || emotionRecommendations.neutral;

    res.json({ recommendations: recommendations.slice(0, limit) });
  } catch (error) {
    console.error('Get recommendations error:', error);
    res.status(500).json({ error: 'Failed to get recommendations' });
  }
});

export default router;
