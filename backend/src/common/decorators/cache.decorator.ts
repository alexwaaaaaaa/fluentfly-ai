import { SetMetadata } from '@nestjs/common';

export const CACHE_KEY_METADATA = 'cache_key';
export const CACHE_TTL_METADATA = 'cache_ttl';

/**
 * Decorator to enable caching for a route handler
 * @param key Cache key or function to generate key from request
 * @param ttl Time to live in seconds
 */
export const CacheResponse = (key: string | ((req: any) => string), ttl: number) => {
  return (target: any, propertyKey: string, descriptor: PropertyDescriptor) => {
    SetMetadata(CACHE_KEY_METADATA, key)(target, propertyKey, descriptor);
    SetMetadata(CACHE_TTL_METADATA, ttl)(target, propertyKey, descriptor);
    return descriptor;
  };
};

/**
 * Decorator to invalidate cache
 * @param keys Array of cache keys or patterns to invalidate
 */
export const InvalidateCache = (...keys: string[]) => {
  return SetMetadata('invalidate_cache', keys);
};
