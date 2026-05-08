import { createClient } from 'redis';
import dotenv from 'dotenv';

dotenv.config();

const redisClient = createClient({
  url: process.env.REDIS_URL || 'redis://localhost:6379',
});

redisClient.on('connect', () => {
  console.log('Connected to Redis');
});

redisClient.on('error', (err) => {
  console.error('Redis error:', err);
});

export async function initRedis(): Promise<void> {
  if (!redisClient.isOpen) {
    await redisClient.connect();
  }
}

export async function getCache<T>(key: string): Promise<T | null> {
  const value = await redisClient.get(key);
  return value ? JSON.parse(value) : null;
}

export async function setCache(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
  const serialized = JSON.stringify(value);
  if (ttlSeconds) {
    await redisClient.setEx(key, ttlSeconds, serialized);
  } else {
    await redisClient.set(key, serialized);
  }
}

export async function deleteCache(key: string): Promise<void> {
  await redisClient.del(key);
}

export default redisClient;
