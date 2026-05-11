import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { queryOne } from '../db';
import { User } from '../models';

export interface AuthenticatedRequest extends Request {
  user?: User;
}

export async function authMiddleware(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing or invalid authorization header' });
    return;
  }

  const token = authHeader.substring(7);
  const jwtSecret = process.env.JWT_SECRET || 'fallback_secret_for_dev_only';

  try {
    let user: User | null = null;

    // 1. Try JWT verification first
    try {
      const decoded = jwt.verify(token, jwtSecret) as { userId: string };
      user = await queryOne<User>(
        'SELECT * FROM users WHERE id = $1 AND deleted_at IS NULL',
        [decoded.userId]
      );
    } catch (jwtError) {
      // 2. Fallback to old anonymous_token mechanism for backward compatibility
      user = await queryOne<User>(
        'SELECT * FROM users WHERE anonymous_token = $1 AND deleted_at IS NULL',
        [token]
      );
    }

    if (!user) {
      res.status(401).json({ error: 'Invalid or expired token' });
      return;
    }

    if (user.account_status === 'disabled') {
      res.status(403).json({ error: 'Account is disabled' });
      return;
    }

    req.user = user;
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Authentication failed' });
  }
}

export function requireRole(role: string) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      res.status(401).json({ error: 'Unauthorized' });
      return;
    }
    if (req.user.role !== role && req.user.role !== 'admin') {
      res.status(403).json({ error: `Forbidden: requires ${role} role` });
      return;
    }
    next();
  };
}
