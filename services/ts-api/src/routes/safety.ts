import { Router, Response } from 'express';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

router.get('/resources', async (req: AuthenticatedRequest, res: Response) => {
  try {
    res.json({
      message: '如果你现在感到很难撑住，请优先联系现实中的可信任的人。',
      resources: [
        {
          title: '联系可信任的人',
          description: '先发消息或打电话给家人、朋友、辅导员或室友，告诉对方你现在需要陪伴。'
        },
        {
          title: '学校心理支持',
          description: '如果你所在学校有心理中心或辅导员资源，可以尽快联系。'
        },
        {
          title: '本地紧急求助',
          description: '如果你担心自己会立刻受伤或处在危险中，请联系当地紧急电话。'
        },
        {
          title: '先做稳定呼吸',
          description: '缓慢吸气、停顿、呼气，重复几轮，让身体先稳定下来。'
        }
      ]
    });
  } catch (error) {
    console.error('Get safety resources error:', error);
    res.status(500).json({ error: 'Failed to get safety resources' });
  }
});

export default router;
