// In-memory cache (Redis fallback)
const memoryCache = new Map<string, { value: string; expiry?: number }>();

export async function initRedis(): Promise<void> {
  console.log('Using in-memory cache');
}

export async function getCache<T>(key: string): Promise<T | null> {
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
  memoryCache.set(key, {
    value: serialized,
    expiry: ttlSeconds ? Date.now() + ttlSeconds * 1000 : undefined
  });
}

export async function deleteCache(key: string): Promise<void> {
  memoryCache.delete(key);
}

export default { initRedis, getCache, setCache, deleteCache };
