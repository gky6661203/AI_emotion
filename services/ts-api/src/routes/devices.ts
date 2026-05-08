import { Router, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, query } from '../db';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';
import { Device } from '../models';

const router = Router();

router.use(authMiddleware);

router.post('/bind', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { device_id, device_type, device_name } = req.body;
    const userId = req.user!.id;

    const existing = query<Device>(
      'SELECT * FROM devices WHERE user_id = ? AND device_id = ?',
      [userId, device_id]
    );

    if (existing.length > 0) {
      execute(
        `UPDATE devices SET device_type = ?, device_name = ?, last_sync_at = ?, is_active = 1
         WHERE user_id = ? AND device_id = ?`,
        [device_type, device_name, new Date().toISOString(), userId, device_id]
      );
    } else {
      const deviceId = uuidv4();
      execute(
        `INSERT INTO devices (id, user_id, device_id, device_type, device_name, is_active, created_at)
         VALUES (?, ?, ?, ?, ?, 1, ?)`,
        [deviceId, userId, device_id, device_type || null, device_name || null, new Date().toISOString()]
      );
    }

    const device = query<Device>(
      'SELECT * FROM devices WHERE user_id = ? AND device_id = ?',
      [userId, device_id]
    );

    res.status(201).json({ device: device[0] });
  } catch (error) {
    console.error('Bind device error:', error);
    res.status(500).json({ error: 'Failed to bind device' });
  }
});

router.get('/', async (req: AuthenticatedRequest, res: Response) => {
  try {
    const userId = req.user!.id;
    const devices = query<Device>(
      'SELECT * FROM devices WHERE user_id = ? AND is_active = 1 ORDER BY last_sync_at DESC',
      [userId]
    );
    res.json({ devices });
  } catch (error) {
    console.error('List devices error:', error);
    res.status(500).json({ error: 'Failed to list devices' });
  }
});

export default router;
