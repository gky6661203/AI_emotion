import { Router, Request, Response } from 'express';
import { randomBytes, pbkdf2Sync, timingSafeEqual } from 'crypto';
import { v4 as uuidv4 } from 'uuid';
import jwt from 'jsonwebtoken';
import { execute, queryOne } from '../db';
import { User } from '../models';
import { AuthenticatedRequest, authMiddleware } from '../middleware/auth';

const router = Router();
const JWT_SECRET = process.env.JWT_SECRET || 'fallback_secret_for_dev_only';
const REFRESH_SECRET = process.env.REFRESH_SECRET || 'fallback_refresh_secret_for_dev_only';
const MAX_LOGIN_FAILURES = 5;
const LOCKOUT_MINUTES = 30;

function generateLegacyToken(): string {
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

function checkPasswordStrength(password: string): boolean {
  // At least 8 chars, 1 letter, 1 number
  const regex = /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{8,}$/;
  return regex.test(password);
}

function isEmail(account: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(account);
}

function isPhone(account: string): boolean {
  return /^1[3-9]\d{9}$/.test(account);
}

function generateTokens(userId: string, role: string) {
  const accessToken = jwt.sign({ userId, role }, JWT_SECRET, { expiresIn: '2h' });
  const refreshToken = jwt.sign({ userId, role }, REFRESH_SECRET, { expiresIn: '7d' });
  return { accessToken, refreshToken };
}

async function createDefaultsForUser(userId: string, displayName: string, campus?: string | null, enrollmentYear?: number | null): Promise<void> {
  await execute(
    `INSERT INTO anonymous_profiles (user_id, display_name, campus, enrollment_year) VALUES ($1, $2, $3, $4) ON CONFLICT (user_id) DO NOTHING`,
    [userId, displayName, campus || null, enrollmentYear || null]
  );
  await execute(`INSERT INTO user_privacy_settings (user_id) VALUES ($1) ON CONFLICT (user_id) DO NOTHING`, [userId]);
}

async function createStateVector(userId: string, stateVectorId: string, now: string): Promise<void> {
  await execute(
    `INSERT INTO user_state_vectors (id, user_id, dimension_valence, dimension_arousal, dimension_dominance, dimension_social, dimension_cognitive, computed_at) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [stateVectorId, userId, 0.5, 0.5, 0.5, 0.5, 0.5, now]
  );
}

// 1. 发送验证码 (Mock)
router.post('/send-code', async (req: Request, res: Response) => {
  const account = normalizeAccount(req.body.account);
  const type = req.body.type; // register, login, reset_password
  if (!account || !type) {
    res.status(400).json({ error: 'Account and type are required' }); return;
  }
  const code = Math.floor(100000 + Math.random() * 900000).toString(); // 6 digits
  const expiresAt = new Date(Date.now() + 10 * 60000).toISOString(); // 10 mins
  await execute(
    `INSERT INTO verification_codes (target, code, type, expires_at) VALUES ($1, $2, $3, $4)`,
    [account, code, type, expiresAt]
  );
  // Mock sending email/sms
  console.log(`[Mock SMS/Email] Send code ${code} to ${account}`);
  res.json({ success: true, message: 'Code sent (mock)' });
});

// 2. 注册（简化版：无需验证码）
router.post('/register', async (req: Request, res: Response) => {
  try {
    const account = normalizeAccount(req.body.account ?? req.body.email);
    const password = String(req.body.password || '');
    const nickname = typeof req.body.nickname === 'string' ? req.body.nickname.trim() : '';

    if (!account) { res.status(400).json({ error: 'account is required' }); return; }
    if (!checkPasswordStrength(password)) {
      res.status(400).json({ error: '密码太弱，至少8位且包含字母和数字' }); return; }

    const is_email = isEmail(account);
    const is_phone = isPhone(account);
    const checkField = (is_email ? 'email' : (is_phone ? 'phone' : 'email'));

    // Check duplicate
    const existing = await queryOne(`SELECT id FROM users WHERE ${checkField} = $1 AND deleted_at IS NULL`, [account]);
    if (existing) { res.status(409).json({ error: '该账号已被注册' }); return; }

    const userId = uuidv4();
    const stateVectorId = uuidv4();
    const now = new Date().toISOString();
    const displayName = nickname || `User_${Math.random().toString(36).substring(2, 8)}`;

    const emailVal = is_email ? account : null;
    const phoneVal = is_phone ? account : null;

    await execute(
      `INSERT INTO users (id, anonymous_token, email, phone, password_hash, account_status, is_anonymous, role, nickname, risk_level, state_vector_id, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, 'active', false, 'user', $6, 'low', $7, $8, $9)`,
      [userId, generateLegacyToken(), emailVal, phoneVal, hashPassword(password), displayName, stateVectorId, now, now]
    );

    await createStateVector(userId, stateVectorId, now);
    await createDefaultsForUser(userId, displayName);

    const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
    if (!user) { res.status(500).json({ error: '用户创建失败' }); return; }
    const { accessToken, refreshToken } = generateTokens(user.id, user.role);
    res.status(201).json({ user, token: accessToken, refreshToken });
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({ error: '注册失败' });
  }
});

// 2b. 检查账号是否已存在（用于注册时实时校验）
router.post('/check-account', async (req: Request, res: Response) => {
  const account = normalizeAccount(req.body.account);
  if (!account) { res.status(400).json({ error: 'account is required' }); return; }

  const is_email = isEmail(account);
  const is_phone = isPhone(account);
  const checkField = (is_email ? 'email' : (is_phone ? 'phone' : 'email'));

  const existing = await queryOne(`SELECT id FROM users WHERE ${checkField} = $1 AND deleted_at IS NULL`, [account]);
  res.json({ exists: !!existing });
});

// 2c. 忘记密码 - 发送重置验证码（Mock）
router.post('/forgot-password/send-code', async (req: Request, res: Response) => {
  const account = normalizeAccount(req.body.account);
  if (!account) { res.status(400).json({ error: 'account is required' }); return; }

  const is_email = isEmail(account);
  const is_phone = isPhone(account);
  const checkField = (is_email ? 'email' : (is_phone ? 'phone' : 'email'));

  const user = await queryOne(`SELECT id FROM users WHERE ${checkField} = $1 AND deleted_at IS NULL`, [account]);
  if (!user) { res.status(404).json({ error: '账号不存在' }); return; }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = new Date(Date.now() + 10 * 60000).toISOString();
  await execute(
    `INSERT INTO verification_codes (target, code, type, expires_at) VALUES ($1, $2, $3, $4)`,
    [account, code, 'reset_password', expiresAt]
  );
  console.log(`[Mock] Password reset code ${code} for ${account}`);
  res.json({ success: true, message: '重置码已发送（Mock）' });
});

// 2d. 重置密码
router.post('/forgot-password/reset', async (req: Request, res: Response) => {
  const account = normalizeAccount(req.body.account);
  const code = req.body.code;
  const newPassword = String(req.body.new_password || '');

  if (!account || !code || !newPassword) {
    res.status(400).json({ error: 'account, code, new_password are required' }); return;
  }
  if (!checkPasswordStrength(newPassword)) {
    res.status(400).json({ error: '密码太弱，至少8位且包含字母和数字' }); return;
  }

  const verifyRecord = await queryOne(
    `SELECT * FROM verification_codes WHERE target = $1 AND code = $2 AND type = 'reset_password' AND used = false AND expires_at > NOW() ORDER BY created_at DESC LIMIT 1`,
    [account, code]
  );
  if (!verifyRecord) { res.status(400).json({ error: '验证码无效或已过期' }); return; }
  await execute(`UPDATE verification_codes SET used = true WHERE id = $1`, [(verifyRecord as any).id]);

  const is_email = isEmail(account);
  const is_phone = isPhone(account);
  const checkField = (is_email ? 'email' : (is_phone ? 'phone' : 'email'));

  const user = await queryOne<User>(`SELECT id FROM users WHERE ${checkField} = $1 AND deleted_at IS NULL`, [account]);
  if (!user) { res.status(404).json({ error: '账号不存在' }); return; }

  await execute(`UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3`, [hashPassword(newPassword), new Date().toISOString(), user.id]);
  res.json({ success: true, message: '密码重置成功' });
});

// 2e. 修改密码（已登录用户）
router.patch('/password', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  const oldPassword = String(req.body.old_password || '');
  const newPassword = String(req.body.new_password || '');

  if (!oldPassword || !newPassword) {
    res.status(400).json({ error: 'old_password and new_password are required' }); return;
  }
  if (!checkPasswordStrength(newPassword)) {
    res.status(400).json({ error: '密码太弱，至少8位且包含字母和数字' }); return;
  }

  const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [req.user!.id]);
  if (!user || !verifyPassword(oldPassword, user.password_hash)) {
    res.status(401).json({ error: '原密码错误' }); return;
  }

  await execute(`UPDATE users SET password_hash = $1, updated_at = $2 WHERE id = $3`, [hashPassword(newPassword), new Date().toISOString(), user.id]);
  res.json({ success: true, message: '密码修改成功' });
});

// 3. 登录
router.post('/login', async (req: Request, res: Response) => {
  try {
    const account = normalizeAccount(req.body.account ?? req.body.email);
    const password = String(req.body.password || '');

    const is_email = isEmail(account);
    const is_phone = isPhone(account);
    const checkField = is_email ? 'email' : (is_phone ? 'phone' : 'email');

    const user = await queryOne<User>(`SELECT * FROM users WHERE ${checkField} = $1 AND deleted_at IS NULL`, [account]);
    
    if (!user) { res.status(401).json({ error: '账号或密码错误' }); return; }
    if (user.account_status === 'disabled') { res.status(403).json({ error: '账号被禁用' }); return; }

    if (user.locked_until && new Date(user.locked_until) > new Date()) {
      res.status(403).json({ error: '登录失败次数过多，账号已锁定，请稍后再试' }); return;
    }

    if (!verifyPassword(password, user.password_hash)) {
      const failures = (user.login_failures || 0) + 1;
      let lockedUntil = null;
      if (failures >= MAX_LOGIN_FAILURES) {
        lockedUntil = new Date(Date.now() + LOCKOUT_MINUTES * 60000).toISOString();
      }
      await execute(`UPDATE users SET login_failures = $1, locked_until = $2 WHERE id = $3`, [failures, lockedUntil, user.id]);
      res.status(401).json({ error: '账号或密码错误' }); return;
    }

    // Success
    await execute(`UPDATE users SET login_failures = 0, locked_until = NULL WHERE id = $1`, [user.id]);
    
    const { accessToken, refreshToken } = generateTokens(user.id, user.role);
    const deviceInfo = req.headers['user-agent'] || 'unknown';
    
    // Store refresh token
    await execute(`INSERT INTO refresh_tokens (user_id, token, device_info, expires_at) VALUES ($1, $2, $3, $4)`, 
      [user.id, refreshToken, deviceInfo, new Date(Date.now() + 7 * 24 * 3600000).toISOString()]);

    const updatedUser = await queryOne<User>('SELECT * FROM users WHERE id = $1', [user.id]);
    res.json({ user: updatedUser, token: accessToken, refreshToken });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: '登录失败' });
  }
});

// 4. 第三方登录 (Mock)
router.post('/login/third-party', async (req: Request, res: Response) => {
  const { provider, provider_id, provider_data } = req.body;
  if (!provider || !provider_id) { res.status(400).json({ error: 'Provider details required' }); return; }
  
  try {
    const bindRecord = await queryOne(`SELECT user_id FROM third_party_logins WHERE provider = $1 AND provider_id = $2`, [provider, provider_id]);
    
    let userId: string;
    if (bindRecord) {
      userId = (bindRecord as any).user_id;
    } else {
      // Auto register for third party
      userId = uuidv4();
      const stateVectorId = uuidv4();
      const now = new Date().toISOString();
      const nickname = (provider_data?.nickname) || `${provider}_user_${Math.random().toString(36).substring(2, 6)}`;
      
      await execute(
        `INSERT INTO users (id, anonymous_token, account_status, is_anonymous, role, nickname, risk_level, state_vector_id, created_at, updated_at)
         VALUES ($1, $2, 'active', false, 'user', $3, 'low', $4, $5, $6)`,
        [userId, generateLegacyToken(), nickname, stateVectorId, now, now]
      );
      await createStateVector(userId, stateVectorId, now);
      await createDefaultsForUser(userId, nickname);
      await execute(`INSERT INTO third_party_logins (user_id, provider, provider_id, provider_data) VALUES ($1, $2, $3, $4)`, [userId, provider, provider_id, JSON.stringify(provider_data || {})]);
    }

    const { accessToken, refreshToken } = generateTokens(userId, 'user');
    await execute(`INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)`, [userId, refreshToken, new Date(Date.now() + 7 * 24 * 3600000).toISOString()]);
    
    const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
    res.json({ user, token: accessToken, refreshToken });
  } catch (error) {
    res.status(500).json({ error: 'Third-party login failed' });
  }
});

// 5. 匿名用户生成
router.post('/anonymous', async (req: Request, res: Response) => {
  try {
    const { campus, enrollment_year } = req.body;
    const userId = uuidv4();
    const stateVectorId = uuidv4();
    const now = new Date().toISOString();
    const randomNick = `树洞_${Date.now().toString().slice(-4)}${Math.random().toString(36).substring(2, 4)}`;

    await execute(
      `INSERT INTO users (id, anonymous_token, is_anonymous, role, nickname, campus, enrollment_year, risk_level, state_vector_id, total_interactions, created_at, updated_at)
       VALUES ($1, $2, true, 'anonymous', $3, $4, $5, 'low', $6, 0, $7, $8)`,
      [userId, generateLegacyToken(), randomNick, campus || null, enrollment_year || null, stateVectorId, now, now]
    );

    await createStateVector(userId, stateVectorId, now);
    await createDefaultsForUser(userId, randomNick, campus || null, enrollment_year || null);

    const { accessToken, refreshToken } = generateTokens(userId, 'anonymous');
    const user = await queryOne<User>('SELECT * FROM users WHERE id = $1', [userId]);
    res.status(201).json({ user, token: accessToken, refreshToken });
  } catch (error) {
    console.error('Create anonymous user error:', error);
    res.status(500).json({ error: '生成匿名用户失败' });
  }
});

// 6. 刷新 Token
router.post('/refresh', async (req: Request, res: Response) => {
  const { refreshToken } = req.body;
  if (!refreshToken) { res.status(400).json({ error: 'Refresh token required' }); return; }

  try {
    const record = await queryOne(`SELECT * FROM refresh_tokens WHERE token = $1 AND revoked = false AND expires_at > NOW()`, [refreshToken]);
    if (!record) { res.status(401).json({ error: 'Invalid or expired refresh token' }); return; }

    const decoded = jwt.verify(refreshToken, REFRESH_SECRET) as { userId: string, role: string };
    const { accessToken: newAccessToken, refreshToken: newRefreshToken } = generateTokens(decoded.userId, decoded.role);
    
    // Revoke old and insert new
    await execute(`UPDATE refresh_tokens SET revoked = true WHERE id = $1`, [(record as any).id]);
    await execute(`INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)`, [decoded.userId, newRefreshToken, new Date(Date.now() + 7 * 24 * 3600000).toISOString()]);

    res.json({ token: newAccessToken, refreshToken: newRefreshToken });
  } catch (error) {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

router.get('/me', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  // Data masking for privacy
  const user = { ...req.user } as User;
  if (user.phone) user.phone = user.phone.replace(/(\d{3})\d{4}(\d{4})/, '$1****$2');
  if (user.email) user.email = user.email.replace(/(.{2}).*(@.*)/, '$1***$2');
  delete user.password_hash;
  delete user.anonymous_token;
  res.json({ user });
});

router.post('/logout', authMiddleware, async (req: AuthenticatedRequest, res: Response) => {
  const refreshToken = req.body.refreshToken;
  if (refreshToken) {
    await execute(`UPDATE refresh_tokens SET revoked = true WHERE token = $1`, [refreshToken]);
  }
  res.json({ success: true });
});

export default router;