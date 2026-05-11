import request from 'supertest';
import express from 'express';
import authRouter from '../routes/auth';

// Mock DB
jest.mock('../db', () => ({
  execute: jest.fn().mockResolvedValue(true),
  queryOne: jest.fn(),
}));

import { queryOne, execute } from '../db';

const app = express();
app.use(express.json());
app.use('/api/auth', authRouter);

describe('Auth Module', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should send verification code', async () => {
    const res = await request(app)
      .post('/api/auth/send-code')
      .send({ account: 'test@example.com', type: 'register' });
    
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(execute).toHaveBeenCalledTimes(1);
  });

  it('should fail registration if password is too weak', async () => {
    const res = await request(app)
      .post('/api/auth/register')
      .send({ account: 'test@example.com', password: '123', code: '123456' });
    
    expect(res.status).toBe(400);
    expect(res.body.error).toContain('密码太弱');
  });

  it('should fail login if account is locked', async () => {
    (queryOne as jest.Mock).mockResolvedValueOnce({
      id: 'user1',
      email: 'test@example.com',
      password_hash: 'mock_hash',
      account_status: 'active',
      locked_until: new Date(Date.now() + 10000).toISOString() // locked
    });

    const res = await request(app)
      .post('/api/auth/login')
      .send({ account: 'test@example.com', password: 'Valid1Password' });
    
    expect(res.status).toBe(403);
    expect(res.body.error).toContain('账号已锁定');
  });

  it('should generate anonymous user successfully', async () => {
    (queryOne as jest.Mock).mockResolvedValueOnce({
      id: 'anon1',
      is_anonymous: true,
      role: 'anonymous',
      nickname: '树洞_1234xx'
    });

    const res = await request(app)
      .post('/api/auth/anonymous')
      .send({ campus: 'Main Campus' });
    
    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
    expect(res.body.refreshToken).toBeDefined();
    expect(res.body.user.role).toBe('anonymous');
  });
});