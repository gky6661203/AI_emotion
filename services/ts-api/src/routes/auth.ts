import { Router, Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { execute, queryOne } from '../db';
import { User } from '../models';

const router = Router();

function generateToken(): string {
  return Array.from({ length: 64 }, () =>
    Math.random().toString(36).charAt(2)
  ).join('');
}

router.post('/anonymous', async (req: Request, res: Response) => {
  try {
    const { campus, enrollment_year } = req.body;

    const userId = uuidv4();
    const token = generateToken();
    const stateVectorId = uuidv4();
    const now = new Date().toISOString();

    execute(
      `INSERT INTO users (id, anonymous_token, campus, enrollment_year, risk_level, state_vector_id, total_interactions, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, token, campus || null, enrollment_year || null, 'low', stateVectorId, 0, now, now]
    );

    execute(
      `INSERT INTO user_state_vectors (id, user_id, dimension_valence, dimension_arousal, dimension_dominance, dimension_social, dimension_cognitive, computed_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [stateVectorId, userId, 0.5, 0.5, 0.5, 0.5, 0.5, now]
    );

    const user = queryOne<User>(
      'SELECT * FROM users WHERE id = ?',
      [userId]
    );

    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Create anonymous user error:', error);
    res.status(500).json({ error: 'Failed to create anonymous user' });
  }
});

export default router;
