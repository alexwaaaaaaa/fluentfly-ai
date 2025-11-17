import { ConfigService } from '@nestjs/config';
import { Redis } from 'ioredis';

export const getRedisConfig = (configService: ConfigService): Redis => {
  return new Redis(configService.get<string>('REDIS_URL') || 'redis://localhost:6379', {
    maxRetriesPerRequest: 3,
    retryStrategy: (times) => {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
  });
};
