import {
  Injectable,
  OnModuleInit,
  OnModuleDestroy,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';
import type { RedisOptions } from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private client?: Redis;
  private readonly logger = new Logger(RedisService.name);
  private lastErrorMessage?: string;
  private connected = false;
  private disabled = false;

  constructor(private configService: ConfigService) {}

  onModuleInit() {
    const redisOptions = this.configService.get<RedisOptions | null>('redis');

    if (!redisOptions) {
      this.disabled = true;
      this.logger.log('Redis disabled (no REDIS_URL/REDIS_HOST configured)');
      return;
    }

    this.client = new Redis(redisOptions);

    this.client.on('connect', () => this.logger.log('Redis connected'));
    this.client.on('ready', () => {
      this.connected = true;
      this.lastErrorMessage = undefined;
      this.logger.log('Redis ready');
    });
    this.client.on('close', () => {
      this.connected = false;
    });
    this.client.on('end', () => {
      this.connected = false;
      if (!this.disabled) {
        this.disabled = true;
        this.logger.warn(
          'Redis unreachable after retries — caching disabled for this session',
        );
      }
    });
    this.client.on('error', (err) => {
      this.connected = false;
      const message = err instanceof Error ? err.message : String(err);
      if (message === this.lastErrorMessage) return;

      this.lastErrorMessage = message;
      this.logger.warn(`Redis error: ${message}`);
    });

    this.client.connect().catch((err) => this.logCacheError(err));
  }

  async onModuleDestroy() {
    try {
      await this.client?.quit();
    } catch {
      // ignore
    }
  }

  getClient(): Redis | undefined {
    return this.client;
  }

  /** Cache with TTL (seconds) */
  async set(key: string, value: unknown, ttl = 300): Promise<void> {
    if (this.disabled || !this.connected || !this.client) return;

    try {
      await this.client.set(key, JSON.stringify(value), 'EX', ttl);
    } catch (err) {
      this.logCacheError(err);
    }
  }

  async get<T = unknown>(key: string): Promise<T | null> {
    if (this.disabled || !this.connected || !this.client) return null;

    try {
      const data = await this.client.get(key);
      return data ? (JSON.parse(data) as T) : null;
    } catch (err) {
      this.logCacheError(err);
      return null;
    }
  }

  async del(key: string): Promise<void> {
    if (this.disabled || !this.connected || !this.client) return;

    try {
      await this.client.del(key);
    } catch (err) {
      this.logCacheError(err);
    }
  }

  /** Delete all keys matching a pattern */
  async delPattern(pattern: string): Promise<void> {
    if (this.disabled || !this.connected || !this.client) return;

    try {
      const keys = await this.client.keys(pattern);
      if (keys.length > 0) {
        await this.client.del(...keys);
      }
    } catch (err) {
      this.logCacheError(err);
    }
  }

  private logCacheError(err: unknown): void {
    const message = err instanceof Error ? err.message : String(err);
    if (message === this.lastErrorMessage) return;

    this.lastErrorMessage = message;
    this.logger.warn(`Redis cache unavailable: ${message}`);
  }
}
