import type { RedisOptions } from 'ioredis';

function cleanEnv(value?: string): string | undefined {
  const trimmed = value?.trim();
  if (!trimmed) return undefined;
  return trimmed.replace(/^['"]|['"]$/g, '');
}

const baseOptions: Partial<RedisOptions> = {
  lazyConnect: true,
  enableOfflineQueue: false,
  maxRetriesPerRequest: 1,
  // Stop retrying after a few attempts so we don't spam logs
  retryStrategy: (times: number) => {
    if (times > 3) return null;
    return Math.min(times * 1000, 5000);
  },
  reconnectOnError: () => false,
};

export function getRedisOptions(): RedisOptions | null {
  if (cleanEnv(process.env.REDIS_DISABLED) === 'true') return null;

  const redisUrl = cleanEnv(process.env.REDIS_URL);

  if (redisUrl) {
    const parsed = new URL(redisUrl);
    const database = parsed.pathname.replace(/^\//, '');

    return {
      ...baseOptions,
      host: parsed.hostname,
      port: Number(parsed.port || 6379),
      username: parsed.username ? decodeURIComponent(parsed.username) : undefined,
      password: parsed.password ? decodeURIComponent(parsed.password) : undefined,
      db: database ? Number(database) : undefined,
      tls: parsed.protocol === 'rediss:' ? {} : undefined,
    };
  }

  const host = cleanEnv(process.env.REDIS_HOST);
  if (!host) return null;

  return {
    ...baseOptions,
    host,
    port: Number(cleanEnv(process.env.REDIS_PORT) || 6379),
    username: cleanEnv(process.env.REDIS_USERNAME),
    password: cleanEnv(process.env.REDIS_PASSWORD),
    tls: cleanEnv(process.env.REDIS_TLS) === 'true' ? {} : undefined,
  };
}
