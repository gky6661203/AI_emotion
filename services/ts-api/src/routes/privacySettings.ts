import { Router, Response } from 'express';
import { execute, queryOne } from '../db';
import { UserPrivacySettings } from '../models';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

const editableFields = [
  'allow_chat_analysis',
  'allow_letter_analysis',
  'allow_voice_analysis',
  'allow_profile_update',
  'allow_recommendation_use',
  'allow_match_use',
  'allow_voice_text_retention',
  'allow_multi_device_sync',
  'allow_emotion_reminders'
] as const;

type PrivacyField = typeof editableFields[number];

async function ensureSettings(userId: string): Promise<UserPrivacySettings> {
  let settings = await queryOne<UserPrivacySettings>('SELECT * FROM user_privacy_settings WHERE user_id = $1', [userId]);
  if (settings) return settings;

  await execute(
    `INSERT INTO user_privacy_settings (user_id)
     VALUES ($1)
     ON CONFLICT (user_id) DO NOTHING`,
    [userId]
  );

  settings = await queryOne<UserPrivacySettings>('SELECT * FROM user_privacy_settings WHERE user_id = $1', [userId]);
  if (!settings) throw new Error('Failed to create privacy settings');
  return settings;
}

router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const settings = await ensureSettings(req.user!.id);
    res.json({ settings });
  } catch (error) {
    console.error('Get privacy settings error:', error);
    res.status(500).json({ error: 'Failed to get privacy settings' });
  }
});

router.patch('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const current = await ensureSettings(userId);
    const next: Record<PrivacyField, boolean> = {} as Record<PrivacyField, boolean>;

    for (const field of editableFields) {
      next[field] = typeof req.body[field] === 'boolean' ? req.body[field] : current[field];
    }

    await execute(
      `UPDATE user_privacy_settings
       SET allow_chat_analysis = $1,
           allow_letter_analysis = $2,
           allow_voice_analysis = $3,
           allow_profile_update = $4,
           allow_recommendation_use = $5,
           allow_match_use = $6,
           allow_voice_text_retention = $7,
           allow_multi_device_sync = $8,
           allow_emotion_reminders = $9
       WHERE user_id = $10`,
      [
        next.allow_chat_analysis,
        next.allow_letter_analysis,
        next.allow_voice_analysis,
        next.allow_profile_update,
        next.allow_recommendation_use,
        next.allow_match_use,
        next.allow_voice_text_retention,
        next.allow_multi_device_sync,
        next.allow_emotion_reminders,
        userId
      ]
    );

    const settings = await queryOne<UserPrivacySettings>('SELECT * FROM user_privacy_settings WHERE user_id = $1', [userId]);
    res.json({ settings });
  } catch (error) {
    console.error('Update privacy settings error:', error);
    res.status(500).json({ error: 'Failed to update privacy settings' });
  }
});

export default router;
