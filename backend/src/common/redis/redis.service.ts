import { Injectable, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';
import { getRedisConfig } from '../../config/redis.config';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly client: Redis;

  constructor(private configService: ConfigService) {
    this.client = getRedisConfig(configService);
  }

  getClient(): Redis {
    return this.client;
  }

  async get<T>(key: string): Promise<T | null> {
    const cached = await this.client.get(key);
    if (!cached) return null;
    
    // For simple strings (like OTP codes), return as-is without JSON parsing
    // Only try JSON parsing if the value looks like JSON (starts with { or [)
    if (cached.startsWith('{') || cached.startsWith('[')) {
      try {
        return JSON.parse(cached);
      } catch {
        return cached as any;
      }
    }
    
    // Return string values as-is
    return cached as any;
  }

  async set(key: string, value: any, ttl: number = 3600): Promise<void> {
    const stringValue = typeof value === 'string' ? value : JSON.stringify(value);
    await this.client.setex(key, ttl, stringValue);
  }

  async del(key: string): Promise<void> {
    await this.client.del(key);
  }

  async invalidate(pattern: string): Promise<void> {
    const keys = await this.client.keys(pattern);
    if (keys.length > 0) {
      await this.client.del(...keys);
    }
  }

  onModuleDestroy() {
    this.client.disconnect();
  }
}
