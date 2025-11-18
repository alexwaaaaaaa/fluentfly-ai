import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
  Logger,
} from '@nestjs/common';
import { Observable, throwError } from 'rxjs';
import { tap, catchError } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const request = context.switchToHttp().getRequest<{
      method: string;
      url: string;
      query: Record<string, unknown>;
      params: Record<string, unknown>;
      user?: { id: number };
    }>();
    const { method, url, query, params } = request;
    const userId = request.user?.id;
    const now = Date.now();

    // Log incoming request with context
    const requestLog = `→ ${method} ${url}`;
    if (userId) {
      this.logger.log(`${requestLog} [User: ${userId}]`);
    } else {
      this.logger.log(requestLog);
    }

    // Log query params and body in development
    if (process.env.NODE_ENV === 'development') {
      if (Object.keys(query || {}).length > 0) {
        this.logger.debug(`Query: ${JSON.stringify(query)}`);
      }
      if (Object.keys(params || {}).length > 0) {
        this.logger.debug(`Params: ${JSON.stringify(params)}`);
      }
    }

    return next.handle().pipe(
      tap({
        next: () => {
          const response = context.switchToHttp().getResponse();
          const delay = Date.now() - now;
          const responseLog = `← ${method} ${url} ${response.statusCode} - ${delay}ms`;

          if (delay > 3000) {
            this.logger.warn(`${responseLog} [SLOW REQUEST]`);
          } else {
            this.logger.log(responseLog);
          }
        },
        error: (error: Error & { status?: number; statusCode?: number }) => {
          const delay = Date.now() - now;
          const status = error.status || error.statusCode || 500;
          this.logger.error(
            `← ${method} ${url} ${status} - ${delay}ms [${error.message}]`,
          );
        },
      }),
      catchError((error: Error) => {
        // Additional error logging with stack trace
        this.logger.error({
          message: 'Request failed',
          method,
          url,
          userId,
          error: error.message,
          stack: error.stack,
          timestamp: new Date().toISOString(),
        });

        return throwError(() => error);
      }),
    );
  }
}
