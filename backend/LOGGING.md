# FluentFly Backend Logging and Monitoring

This document describes the logging and health monitoring infrastructure for the FluentFly backend API.

## Overview

The FluentFly backend uses a comprehensive logging and monitoring system built with:
- **Winston** - Structured logging with multiple transports
- **NestJS Logger** - Framework-integrated logging
- **Logging Interceptor** - Automatic HTTP request/response logging
- **Health Module** - Service health checks and monitoring

## Winston Logger Configuration

The Winston logger is configured in `src/config/logger.config.ts` and provides:

### Features

1. **Structured JSON Logging** - All logs are formatted as JSON for easy parsing
2. **Multiple Transports** - Console and file-based logging
3. **Log Rotation** - Automatic log file rotation (5MB max, 5 files)
4. **Environment-Specific** - Different behavior for dev/prod/test
5. **Colorized Console Output** - Easy-to-read console logs in development

### Log Levels

- `error` - Error events that might still allow the application to continue
- `warn` - Warning messages for potentially harmful situations
- `info` - Informational messages highlighting progress
- `http` - HTTP request/response logs
- `debug` - Detailed debugging information

### Usage

```typescript
import { Logger } from '@nestjs/common';

export class MyService {
  private readonly logger = new Logger(MyService.name);

  someMethod() {
    this.logger.log('Info message');
    this.logger.debug('Debug message');
    this.logger.warn('Warning message');
    this.logger.error('Error message', error.stack);
  }
}
```

### Log Files (Production)

- `logs/error.log` - Error-level logs only
- `logs/combined.log` - All logs

## Logging Interceptor

The `LoggingInterceptor` (`src/common/interceptors/logging.interceptor.ts`) automatically logs all HTTP requests and responses.

### Features

1. **Request Logging** - Method, URL, user ID
2. **Response Logging** - Status code, duration
3. **Error Logging** - Full error details with stack traces
4. **Slow Request Detection** - Warns on requests > 3 seconds
5. **Development Mode** - Additional query params and body logging

### Log Format

```
→ GET /api/lessons [User: 123]
← GET /api/lessons 200 - 150ms

→ POST /api/chat/turn [User: 456]
← POST /api/chat/turn 200 - 2500ms

→ GET /api/progress [User: 789]
← GET /api/progress 500 - 1200ms [Internal Server Error]
```

### Slow Request Warning

Requests taking longer than 3 seconds are automatically flagged:

```
← GET /api/lessons/123 200 - 3500ms [SLOW REQUEST]
```

## Health Monitoring

The Health Module (`src/modules/health/`) provides comprehensive service health checks.

### Endpoints

#### GET /health

Returns overall system health status with individual service checks.

**Response:**

```json
{
  "status": "healthy",
  "timestamp": "2025-11-12T10:30:00.000Z",
  "services": {
    "database": true,
    "redis": true,
    "azureSpeech": true,
    "gemini": true,
    "openai": true
  }
}
```

**Status Values:**
- `healthy` - All services operational
- `degraded` - Non-critical services down (AI providers)
- `unhealthy` - Critical services down (database, Redis)

#### GET /health/ready

Kubernetes readiness probe endpoint.

**Response:**

```json
{
  "ready": true
}
```

#### GET /health/live

Kubernetes liveness probe endpoint.

**Response:**

```json
{
  "alive": true
}
```

### Service Checks

1. **Database** - Executes `SELECT 1` query
2. **Redis** - Sets and retrieves test key
3. **Azure Speech** - Checks API key configuration
4. **Gemini** - Checks API key configuration
5. **OpenAI** - Checks API key configuration

### Critical vs Non-Critical Services

**Critical Services** (cause `unhealthy` status):
- PostgreSQL Database
- Redis Cache

**Non-Critical Services** (cause `degraded` status):
- Azure Speech Services
- Gemini API
- OpenAI API

## Error Handling and Logging

The `AllExceptionsFilter` (`src/common/filters/http-exception.filter.ts`) catches all exceptions and logs them with full context.

### Error Log Format

```typescript
{
  message: 'Request failed',
  method: 'POST',
  url: '/api/chat/turn',
  userId: 123,
  error: 'Gemini API timeout',
  stack: '...',
  timestamp: '2025-11-12T10:30:00.000Z'
}
```

## Best Practices

### 1. Use Appropriate Log Levels

```typescript
// ✅ Good
this.logger.debug('Cache hit for lesson 123');
this.logger.log('User authenticated successfully');
this.logger.warn('High memory usage detected');
this.logger.error('Database connection failed', error.stack);

// ❌ Bad
this.logger.error('User clicked button'); // Should be debug
this.logger.log('Critical database error'); // Should be error
```

### 2. Include Context

```typescript
// ✅ Good
this.logger.error('Failed to generate TTS', error.stack);
this.logger.log('Lesson created', { lessonId: lesson.id, userId: user.id });

// ❌ Bad
this.logger.error('Error occurred');
this.logger.log('Success');
```

### 3. Avoid Logging Sensitive Data

```typescript
// ✅ Good
this.logger.log('User authenticated', { userId: user.id });

// ❌ Bad
this.logger.log('User authenticated', {
  email: user.email,
  password: password,
  token: jwtToken,
});
```

### 4. Use Structured Logging

```typescript
// ✅ Good
this.logger.log('Lesson completed', {
  userId: user.id,
  lessonId: lesson.id,
  score: 85,
  duration: 300,
});

// ❌ Bad
this.logger.log(`User ${user.id} completed lesson ${lesson.id} with score 85`);
```

## Monitoring Integration

### Production Monitoring

In production, logs should be aggregated and monitored using:

1. **CloudWatch Logs** (AWS)
2. **Datadog** (APM and logging)
3. **New Relic** (APM)
4. **ELK Stack** (Elasticsearch, Logstash, Kibana)
5. **Grafana + Loki** (Open source)

### Example: CloudWatch Integration

```typescript
// Add CloudWatch transport to Winston
import WinstonCloudWatch from 'winston-cloudwatch';

transports.push(
  new WinstonCloudWatch({
    logGroupName: 'fluentfly-api',
    logStreamName: `${process.env.NODE_ENV}-${new Date().toISOString().split('T')[0]}`,
    awsRegion: process.env.AWS_REGION,
    jsonMessage: true,
  })
);
```

### Metrics to Monitor

1. **Request Rate** - Requests per minute
2. **Error Rate** - Percentage of failed requests
3. **Response Time** - P50, P95, P99 latencies
4. **Slow Requests** - Requests > 3 seconds
5. **Service Health** - Database, Redis, external APIs
6. **Memory Usage** - Heap size, GC frequency
7. **CPU Usage** - Process CPU percentage

## Alerting

Set up alerts for:

1. **High Error Rate** - > 5% of requests failing
2. **Slow Responses** - P95 latency > 3 seconds
3. **Service Degradation** - Health status not "healthy"
4. **Database Issues** - Connection failures
5. **Memory Leaks** - Increasing heap size
6. **API Rate Limits** - Approaching external API limits

## Log Analysis Queries

### Find Slow Requests

```bash
# In logs/combined.log
grep "SLOW REQUEST" logs/combined.log
```

### Find Errors by Endpoint

```bash
grep "← POST /api/chat/turn 500" logs/error.log
```

### Count Requests by Status Code

```bash
grep "←" logs/combined.log | awk '{print $4}' | sort | uniq -c
```

## Testing

### Health Check Testing

```bash
# Check overall health
curl http://localhost:3000/health

# Check readiness
curl http://localhost:3000/health/ready

# Check liveness
curl http://localhost:3000/health/live
```

### Log Testing

```typescript
// In test files
import { Test } from '@nestjs/testing';
import { Logger } from '@nestjs/common';

describe('MyService', () => {
  let service: MyService;
  let logger: Logger;

  beforeEach(async () => {
    const module = await Test.createTestingModule({
      providers: [MyService],
    }).compile();

    service = module.get<MyService>(MyService);
    logger = new Logger();
    jest.spyOn(logger, 'error');
  });

  it('should log errors', async () => {
    await service.methodThatFails();
    expect(logger.error).toHaveBeenCalled();
  });
});
```

## Environment Variables

```env
# Logging
LOG_LEVEL=info              # Log level (error, warn, info, http, debug)
NODE_ENV=production         # Environment (development, production, test)

# Health Checks
AZURE_SPEECH_KEY=xxx        # Azure Speech API key
GEMINI_API_KEY=xxx          # Gemini API key
OPENAI_API_KEY=xxx          # OpenAI API key
```

## Performance Considerations

1. **Async Logging** - Winston uses async transports to avoid blocking
2. **Log Sampling** - Consider sampling high-volume logs in production
3. **Log Rotation** - Automatic rotation prevents disk space issues
4. **Structured Logging** - JSON format enables efficient parsing and querying

## Future Enhancements

- [ ] Distributed tracing with OpenTelemetry
- [ ] Real-time log streaming dashboard
- [ ] Automated anomaly detection
- [ ] Log-based alerting rules
- [ ] Performance profiling integration
- [ ] User session tracking across requests
