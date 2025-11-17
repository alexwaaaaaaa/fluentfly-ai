# Error Handling and Resilience

This document describes the comprehensive error handling and resilience mechanisms implemented in the FluentFly backend.

## Overview

The backend implements multiple layers of error handling to ensure reliability and provide meaningful feedback to clients:

1. **Global Exception Filter** - Catches all unhandled exceptions
2. **Logging Interceptor** - Logs all requests and errors
3. **Service-Level Error Handling** - Graceful degradation and fallbacks
4. **Health Monitoring** - System health checks

## Global Exception Filter

Located in `src/common/filters/http-exception.filter.ts`

### Features

- Catches all exceptions (HTTP and non-HTTP)
- Provides user-friendly error messages
- Logs comprehensive error context
- Indicates if errors are retryable
- Hides sensitive details in production

### Error Response Format

```json
{
  "statusCode": 500,
  "timestamp": "2025-01-01T00:00:00.000Z",
  "path": "/api/endpoint",
  "message": "User-friendly error message",
  "retryable": true,
  "error": "ErrorName",  // Development only
  "details": {}          // Development only
}
```

### User-Friendly Messages

The filter automatically converts technical errors to user-friendly messages:

- `400` → "Invalid request. Please check your input and try again."
- `401` → "Authentication required. Please log in."
- `403` → "You do not have permission to access this resource."
- `404` → "The requested resource was not found."
- `429` → "Too many requests. Please try again later."
- `500` → "An unexpected error occurred. Please try again."
- `503` → "Service temporarily unavailable. Please try again later."

## Logging Interceptor

Located in `src/common/interceptors/logging.interceptor.ts`

### Features

- Logs all incoming requests with context
- Logs response times and status codes
- Warns on slow requests (>3 seconds)
- Logs detailed error information with stack traces
- Includes user ID and request metadata

### Log Format

```
→ GET /api/lessons [User: 123]
← GET /api/lessons 200 - 45ms
```

For errors:
```
← GET /api/lessons 500 - 120ms [Database connection failed]
```

## Service-Level Error Handling

### Chat AI Service

The Chat AI service implements dual-provider fallback:

1. **Primary**: Gemini 1.5 Flash
2. **Fallback**: OpenAI GPT-4o-mini
3. **Final Fallback**: Predefined response

```typescript
try {
  aiResponse = await this.geminiProvider.generate(userText, context);
} catch (geminiError) {
  try {
    aiResponse = await this.openaiProvider.generate(userText, context);
  } catch (openaiError) {
    return await this.getFallbackResponse();
  }
}
```

### Speech Service

The Speech service gracefully handles missing configuration:

```typescript
if (!this.isConfigured) {
  this.logger.warn('Azure Speech not configured - returning placeholder');
  return 'https://placeholder.com/audio.mp3';
}
```

## Health Monitoring

Located in `src/modules/health/`

### Endpoints

#### `GET /health`
Returns comprehensive health status:

```json
{
  "status": "healthy",
  "timestamp": "2025-01-01T00:00:00.000Z",
  "services": {
    "database": true,
    "redis": true,
    "azureSpeech": true,
    "gemini": true,
    "openai": true
  }
}
```

Status values:
- `healthy` - All services operational
- `degraded` - Non-critical services down
- `unhealthy` - Critical services down

#### `GET /health/ready`
Kubernetes readiness probe:

```json
{
  "ready": true
}
```

#### `GET /health/live`
Kubernetes liveness probe:

```json
{
  "alive": true
}
```

### Critical vs Non-Critical Services

**Critical Services** (must be healthy):
- Database (PostgreSQL)
- Redis

**Non-Critical Services** (degraded if down):
- Azure Speech
- Gemini API
- OpenAI API

## Error Logging

All errors are logged with comprehensive context:

```typescript
this.logger.error({
  message: 'Error description',
  path: '/api/endpoint',
  method: 'POST',
  statusCode: 500,
  error: 'ErrorName',
  userId: 123,
  userAgent: 'Mozilla/5.0...',
  ip: '192.168.1.1',
  timestamp: '2025-01-01T00:00:00.000Z',
  stack: 'Error stack trace...',
  body: { /* request body */ },
  query: { /* query params */ }
});
```

## Best Practices

### 1. Always Use Try-Catch

```typescript
async someMethod() {
  try {
    return await this.riskyOperation();
  } catch (error) {
    this.logger.error('Operation failed', error.message);
    throw new HttpException('User-friendly message', HttpStatus.INTERNAL_SERVER_ERROR);
  }
}
```

### 2. Provide Fallbacks

```typescript
try {
  return await this.primaryService.execute();
} catch (error) {
  this.logger.warn('Primary service failed, using fallback');
  return await this.fallbackService.execute();
}
```

### 3. Log with Context

```typescript
this.logger.error('Operation failed', {
  userId,
  operation: 'processPayment',
  amount: 100,
  error: error.message,
});
```

### 4. Use Appropriate HTTP Status Codes

- `400` - Bad Request (client error)
- `401` - Unauthorized (authentication required)
- `403` - Forbidden (insufficient permissions)
- `404` - Not Found
- `408` - Request Timeout
- `429` - Too Many Requests
- `500` - Internal Server Error
- `502` - Bad Gateway
- `503` - Service Unavailable
- `504` - Gateway Timeout

## Testing Error Handling

### Test Global Exception Filter

```bash
# Test 404
curl http://localhost:3000/api/nonexistent

# Test 500
curl http://localhost:3000/api/test-error
```

### Test Health Endpoints

```bash
# Check overall health
curl http://localhost:3000/health

# Check readiness
curl http://localhost:3000/health/ready

# Check liveness
curl http://localhost:3000/health/live
```

## Monitoring and Alerts

### Recommended Alerts

1. **High Error Rate**: Alert if error rate > 5% over 5 minutes
2. **Slow Requests**: Alert if p95 latency > 3 seconds
3. **Service Degradation**: Alert if health status is "degraded" for > 5 minutes
4. **Service Down**: Alert immediately if health status is "unhealthy"

### Metrics to Track

- Request count by endpoint
- Error count by status code
- Response time percentiles (p50, p95, p99)
- Service availability percentage
- External service failure rate

## Troubleshooting

### Common Issues

#### Database Connection Errors
```
Error: QueryFailedError
Solution: Check DATABASE_URL and ensure PostgreSQL is running
```

#### Redis Connection Errors
```
Error: Redis connection refused
Solution: Check REDIS_URL and ensure Redis is running
```

#### External Service Timeouts
```
Error: Request timeout
Solution: Check network connectivity and API keys
```

### Debug Mode

Enable detailed logging in development:

```bash
NODE_ENV=development npm run start:dev
```

This will include:
- Request/response bodies
- Query parameters
- Error stack traces
- Detailed error information
