import dotenv from 'dotenv';

dotenv.config();

// In-memory cache fallback
const memoryCache = new Map<string, { value: string; expiry?: number }>();

let redisAvailable = false;

export async function initRedis(): Promise<void> {
  try {
    const { createClient } = await import('redis');
    const redisClient = createClient({
      url: process.env.REDIS_URL || 'redis://localhost:6379',
    });

    await redisClient.connect();
    console.log('Connected to Redis');
    redisAvailable = true;

    redisClient.on('error', () => {
      redisAvailable = false;
    });
  } catch {
    console.log('Redis not available, using in-memory cache');
    redisAvailable = false;
  }
}

export async function getCache<T>(key: string): Promise<T | null> {
  if (redisAvailable) {
    try {
      const { default: redisClient } = await import('redis');
      const client = redisClient.createClient({ url: process.env.REDIS_URL });
      await client.connect();
      const value = await client.get(key);
      await client.quit();
      return value ? JSON.parse(value) : null;
    } catch {
      // Fall through to memory cache
    }
  }

  // Memory cache fallback
  const cached = memoryCache.get(key);
  if (cached) {
    if (cached.expiry && Date.now() > cached.expiry) {
      memoryCache.delete(key);
      return null;
    }
    return JSON.parse(cached.value) as T;
  }
  return null;
}

export async function setCache(key: string, value: unknown, ttlSeconds?: number): Promise<void> {
  const serialized = JSON.stringify(value);

  if (redisAvailable) {
    try {
      const { default: redisClient } = await import('redis');
      const client = redisClient.createClient({ url: process.env.REDIS_URL });
      await client.connect();
      if (ttlSeconds) {
        await client.setEx(key, ttlSeconds, serialized);
      } else {
        await client.set(key, serialized);
      }
      await client.quit();
      return;
    } catch {
      // Fall through to memory cache
    }
  }

  // Memory cache fallback
  memoryCache.set(key, {
    value: serialized,
    expiry: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined
  });
}

export async function deleteCache(key: string): Promise<void> {
  if (redisAvailable) {
    try {
      const { default: redisClient } = await import('redis');
      const client = redisClient.createClient({ url: process.env.REDIS_URL });
      await client.connect();
      await client.del(key);
      await client.quit();
      return;
    } catch {
      // Fall through to memory cache
    }
  }

  memoryCache.delete(key);
}

export default { initRedis, getCache, setCache, deleteCache };
