import { CacheModuleOptions } from '@nestjs/cache-manager';
import { ConfigService } from '@nestjs/config';
import { redisStore } from 'cache-manager-redis-yet';

export const getCacheConfig = async (
  configService: ConfigService,
): Promise<CacheModuleOptions> => {
  const redisUrl = configService.get<string>('REDIS_URL');
  
  if (!redisUrl) {
    // Fallback to in-memory cache for development
    return {
      ttl: 300, // 5 minutes default
      max: 100, // max items in cache
    };
  }

  return {
    store: await redisStore({
      url: redisUrl,
      ttl: 300 * 1000, // 5 minutes in milliseconds
    }),
    max: 10000, // max items in cache
  };
};

// Cache TTL constants (in seconds)
export const CACHE_TTL = {
  LESSONS_LIST: 3600, // 1 hour
  LESSON_DETAIL: 1800, // 30 minutes
  USER_PROFILE: 600, // 10 minutes
  LEADERBOARD: 300, // 5 minutes
  BADGES: 3600, // 1 hour
  PROGRESS: 60, // 1 minute
  EXERCISES: 1800, // 30 minutes
} as const;

// Cache key prefixes
export const CACHE_KEYS = {
  LESSONS_LIST: (level?: string) => `lessons:list:${level || 'all'}`,
  LESSON_DETAIL: (id: number) => `lesson:${id}`,
  USER_PROFILE: (userId: number) => `user:profile:${userId}`,
  USER_PROGRESS: (userId: number) => `user:progress:${userId}`,
  LEADERBOARD: (period: string) => `leaderboard:${period}`,
  BADGES: (userId: number) => `user:badges:${userId}`,
  EXERCISES: (lessonId: number) => `lesson:exercises:${lessonId}`,
} as const;
