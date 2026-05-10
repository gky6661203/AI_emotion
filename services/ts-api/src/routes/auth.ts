import { Router, Request, Response } from 'express';
import { randomBytes, pbkdf2Sync, timingSafeEqual } from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import { execute, queryOne } from '../db';
import { User } from '../models';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();

function generateToken(): string {
  return randomBytes(48).toString('hex');
}

function normalizeAccount(account: unknown): string {
  return String(account || '').trim().toLowerCase();
}

function hashPassword(password: string): string {
  const salt = randomBytes(16).toString('hex');
  const hash = pbkdf2Sync(password, salt, 120000, 64, 'sha512').toString('hex');
  return `pbkdf2_sha512$120000$${salt}$${hash}`;
}

function verifyPassword(password: string, storedHash?: string): boolean {
  if (!storedHash) return false;
  const [algorithm, iterationsText, salt, hash] = storedHash.split('$');
  if (algorithm !== 'pbkdf2_sha512' || !iterationsText || !salt || !hash) return false;

  const iterations = Number(iterationsText);
  if (!Number.isInteger(iterations) || iterations <= 0) return false;

  const candidate = pbkdf2Sync(password, salt, iterations, 64, 'sha512');
  const expected = Buffer.from(hash, 'hex');
  return candidate.length === expected.length && timingSafeEqual(candidate, expected);
}

async function createDefaultsForUser(userId: string, displayName: string, campus?: string | null, enrollmentYear?: number | null): Promise<void> {
  await execute(
    `INSERT INTO anonymous_profiles (user_id, display_name, campus, enrollment_year)
     VALUES ($1, $2, $3, $4)
     ON CONFLICT (user_id) DO NOTHING`,
    [userId, displayName, campus || null, enrollmentYear || null]
  );

  await execute(
    `INSERT INTO user_privacy_settings (user_id)
     VALUES ($1)
     ON CONFLICT (user_id) DO NOTHING`,
    [userId]
  );
}

async function createStateVector(userId: string, stateVectorId: string, now: string): Promise<void> {
  await execute(
    `INSERT INTO user_state_vectors (id, user_id, dimension_valence, dimension_arousal, dimension_dominance, dimension_social, dimension_cognitive, computed_at)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [stateVectorId, userId, 0.5, 0.5, 0.5, 0.5, 0.5, now]
  );
}

router.post('/register', async (req: Request, res: Response) => {
  try {
    const account = normalizeAccount(req.body.account ?? req.body.email);
    const password = String(req.body.password || '');
    const nickname = typeof req.body.nickname === 'string' ? req.body.nickname.trim() : '';
    const campus = typeof req.body.campus === 'string' ? req.body.campus.trim() : null;
    const enrollmentYear = typeof req.body.enrollment_year === 'number' ? req.body.enrollment_year : null;

    if (!account || account.length < 2) {
      res.status(400).json({ error: 'account is required' });
      return;
    }
    if (password.length < 8) {
      res.status(400).json({ error: 'password must be at least 8 characters' });
      return;
    }

    const existing = await queryOne<User>('SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL', [account]);
    if (existing) {
      res.status(409).json({ error: 'account already registered' });
      return;
    }

    const userId = uuidv4();
    const token = generateToken();
    const stateVectorId = uuidv4();
    const now = new Date().toISOString();
    const displayName = nickname || '匿名同学';

    await execute(
      `INSERT INTO users (
        id, anonymous_token, email, password_hash, account_status, nickname, campus,
        enrollment_year, risk_level, state_vector_id, total_interactions, created_at, updated_at
      ) VALUES ($1, $2, $3, $4, 'active', $5, $6, $7, 'low', $8, 0, $9, $10)`,
      [userId, token, account, hashPassword(password), displayName, campus, enrollmentYear, stateVectorId, now, now]
    );

    await createStateVector(userId, stateVectorId, now);
    await createDefaultsForUser(userId, displayName, campus, enrollmentYear);

    const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Register error:', error);
    const message = error instanceof Error ? error.message : 'Unknown register error';
    res.status(500).json({ error: 'Failed to register', detail: message });
  }
});

router.post('/login', async (req: Request, res: Response) => {
  try {
    const account = normalizeAccount(req.body.account ?? req.body.email);
    const password = String(req.body.password || '');

    const user = await queryOne<User>('SELECT * FROM users WHERE email = $1 AND deleted_at IS NULL', [account]);
    if (!user || user.account_status === 'disabled' || !verifyPassword(password, user.password_hash)) {
      res.status(401).json({ error: 'invalid account or password' });
      return;
    }

    const token = generateToken();
    await execute('UPDATE users SET anonymous_token = $1, updated_at = $2 WHERE id = $3', [token, new Date().toISOString(), user.id]);
    await createDefaultsForUser(user.id, user.nickname || '匿名同学', user.campus || null, user.enrollment_year || null);

    const updatedUser = await queryOne<User>('SELECT * FROM users WHERE id = $1', [user.id]);
    res.json({ user: updatedUser, token });
  } catch (error) {
    console.error('Login error:', error);
    const message = error instanceof Error ? error.message : 'Unknown login error';
    res.status(500).json({ error: 'Failed to login', detail: message });
  }
});

router.post('/anonymous', async (req: Request, res: Response) => {
  try {
    const { campus, enrollment_year } = req.body;

    const userId = uuidv4();
    const token = generateToken();
    const stateVectorId = uuidv4();
    const now = new Date().toISOString();

    await execute(
      `INSERT INTO users (id, anonymous_token, campus, enrollment_year, risk_level, state_vector_id, total_interactions, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [userId, token, campus || null, enrollment_year || null, 'low', stateVectorId, 0, now, now]
    );

    await createStateVector(userId, stateVectorId, now);
    await createDefaultsForUser(userId, '匿名同学', campus || null, enrollment_year || null);

    const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
    res.status(201).json({ user, token });
  } catch (error) {
    console.error('Create anonymous user error:', error);
    const message = error instanceof Error ? error.message : 'Unknown anonymous user error';
    res.status(500).json({ error: 'Failed to create anonymous user', detail: message });
  }
});

router.get('/me', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  res.json({ user: req.user });
});

router.post('/logout', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  res.json({ success: true });
});

export default router;
