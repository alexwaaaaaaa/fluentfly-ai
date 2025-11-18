import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Inject,
} from '@nestjs/common';
import { Observable, of } from 'rxjs';
import { tap } from 'rxjs/operators';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { Reflector } from '@nestjs/core';
import {
  CACHE_KEY_METADATA,
  CACHE_TTL_METADATA,
} from '../decorators/cache.decorator';

@Injectable()
export class CacheInterceptor implements NestInterceptor {
  constructor(
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
    private reflector: Reflector,
  ) {}

  async intercept(
    context: ExecutionContext,
    next: CallHandler,
  ): Promise<Observable<any>> {
    const cacheKey = this.reflector.get<string | ((req: any) => string)>(
      CACHE_KEY_METADATA,
      context.getHandler(),
    );

    const cacheTTL = this.reflector.get<number>(
      CACHE_TTL_METADATA,
      context.getHandler(),
    );

    if (!cacheKey) {
      return next.handle();
    }

    const request = context.switchToHttp().getRequest();
    const key = typeof cacheKey === 'function' ? cacheKey(request) : cacheKey;

    // Try to get from cache
    const cachedResponse = await this.cacheManager.get<unknown>(key);
    if (cachedResponse) {
      return of(cachedResponse);
    }

    // If not in cache, execute handler and cache result
    return next.handle().pipe(
      tap((response) => {
        void this.cacheManager.set(key, response, cacheTTL * 1000);
      }),
    );
  }
}
