import { Router, Response } from 'express';
import { queryOne, execute } from '../db';
import { AnonymousProfile } from '../models';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

const names = ['微光同学', '月亮信箱', '海盐汽水', '晚风来信', '树洞旅人', '云朵观察员', '橘子星球', '安静小熊'];
const avatars = [
  'avatar://purple-planet',
  'avatar://green-tree',
  'avatar://blue-cloud',
  'avatar://orange-cat',
  'avatar://moon-mail'
];

function randomItem(items: string[]): string {
  return items[Math.floor(Math.random() * items.length)];
}

async function ensureProfile(userId: string): Promise<AnonymousProfile> {
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

router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const profile = await ensureProfile(req.user!.id);
    res.json({ profile });
  } catch (error) {
    console.error('Get anonymous profile error:', error);
    res.status(500).json({ error: 'Failed to get anonymous profile' });
  }
});

router.patch('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    await ensureProfile(userId);

    const displayName = typeof req.body.display_name === 'string' ? req.body.display_name.trim() : undefined;
    const avatarUrl = typeof req.body.avatar_url === 'string' ? req.body.avatar_url.trim() : undefined;
    const bio = typeof req.body.bio === 'string' ? req.body.bio.trim() : undefined;
    const interests = Array.isArray(req.body.interests) ? req.body.interests.map(String).slice(0, 12) : undefined;
    const campus = typeof req.body.campus === 'string' ? req.body.campus.trim() : undefined;
    const enrollmentYear = typeof req.body.enrollment_year === 'number' ? req.body.enrollment_year : undefined;

    if (displayName !== undefined && (displayName.length < 1 || displayName.length > 40)) {
      res.status(400).json({ error: 'display_name length must be 1-40' });
      return;
    }

    const existing = await queryOne<AnonymousProfile>('SELECT * FROM anonymous_profiles WHERE user_id = $1', [userId]);
    await execute(
      `UPDATE anonymous_profiles
       SET display_name = $1, avatar_url = $2, bio = $3, interests = $4, campus = $5, enrollment_year = $6
       WHERE user_id = $7`,
      [
        displayName ?? existing!.display_name,
        avatarUrl ?? existing!.avatar_url ?? null,
        bio ?? existing!.bio ?? null,
        interests ?? existing!.interests ?? [],
        campus ?? existing!.campus ?? null,
        enrollmentYear ?? existing!.enrollment_year ?? null,
        userId
      ]
    );

    if (displayName !== undefined || avatarUrl !== undefined || campus !== undefined || enrollmentYear !== undefined) {
      await execute(
        `UPDATE users SET nickname = $1, avatar_url = $2, campus = $3, enrollment_year = $4, updated_at = $5 WHERE id = $6`,
        [
          displayName ?? existing!.display_name,
          avatarUrl ?? existing!.avatar_url ?? null,
          campus ?? existing!.campus ?? null,
          enrollmentYear ?? existing!.enrollment_year ?? null,
          new Date().toISOString(),
          userId
        ]
      );
    }

    const profile = await queryOne<AnonymousProfile>('SELECT * FROM anonymous_profiles WHERE user_id = $1', [userId]);
    res.json({ profile });
  } catch (error) {
    console.error('Update anonymous profile error:', error);
    res.status(500).json({ error: 'Failed to update anonymous profile' });
  }
});

router.post('/randomize', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const displayName = `${randomItem(names)}${Math.floor(100 + Math.random() * 900)}`;
    const avatarUrl = randomItem(avatars);

    await ensureProfile(userId);
    await execute(
      `UPDATE anonymous_profiles SET display_name = $1, avatar_url = $2 WHERE user_id = $3`,
      [displayName, avatarUrl, userId]
    );
    await execute(
      `UPDATE users SET nickname = $1, avatar_url = $2, updated_at = $3 WHERE id = $4`,
      [displayName, avatarUrl, new Date().toISOString(), userId]
    );

    const profile = await queryOne<AnonymousProfile>('SELECT * FROM anonymous_profiles WHERE user_id = $1', [userId]);
    res.json({ profile });
  } catch (error) {
    console.error('Randomize anonymous profile error:', error);
    res.status(500).json({ error: 'Failed to randomize anonymous profile' });
  }
});

export default router;
