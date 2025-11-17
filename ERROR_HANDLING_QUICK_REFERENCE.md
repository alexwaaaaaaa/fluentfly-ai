# Error Handling Quick Reference

## Backend (NestJS)

### Throw User-Friendly Errors
```typescript
throw new HttpException('User-friendly message', HttpStatus.BAD_REQUEST);
```

### Log Errors
```typescript
this.logger.error('Operation failed', {
  userId,
  operation: 'fetchData',
  error: error.message,
});
```

### Service with Fallback
```typescript
try {
  return await this.primaryService.execute();
} catch (error) {
  this.logger.warn('Primary failed, using fallback');
  return await this.fallbackService.execute();
}
```

### Check Health
```bash
curl http://localhost:3000/health
```

## Mobile (Flutter)

### Display Error
```dart
ErrorDisplay(
  error: error,
  onRetry: () => fetchData(),
)
```

### Get User Message
```dart
final message = ErrorHandler.getUserMessage(error);
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(message)),
);
```

### Execute with Retry
```dart
final result = await ErrorHandler.withRetry(
  () => apiService.get('/data'),
  maxAttempts: 3,
);
```

### Execute with Fallback
```dart
final data = await ErrorHandler.withErrorHandling(
  () => apiService.get('/data'),
  fallback: cachedData,
);
```

### Safe Animation
```dart
FallbackAnimation(
  assetPath: 'assets/lottie/animation.json',
  fallbackWidget: Icon(Icons.animation),
)
```

### Service Pattern
```dart
try {
  final response = await _apiService.get(
    '/endpoint',
    enableRetry: true,
  );
  return parseResponse(response.data);
} catch (e, stackTrace) {
  _logger.e('Failed', error: e, stackTrace: stackTrace);
  throw Exception('User-friendly message');
}
```

## Common Patterns

### Backend: Try-Catch with Logging
```typescript
async someMethod() {
  try {
    return await this.riskyOperation();
  } catch (error) {
    this.logger.error('Operation failed', error.message);
    throw new HttpException(
      'User-friendly message',
      HttpStatus.INTERNAL_SERVER_ERROR,
    );
  }
}
```

### Mobile: Try-Catch with Fallback
```dart
Future<List<Item>> getItems() async {
  try {
    if (_connectivityService.isOnline) {
      final response = await _apiService.get('/items', enableRetry: true);
      final items = parseItems(response.data);
      await _cacheService.cacheItems(items);
      return items;
    }
  } catch (e) {
    _logger.e('Error fetching items', error: e);
  }

  // Fallback to cache
  final cached = await _cacheService.getCachedItems();
  if (cached != null && cached.isNotEmpty) {
    return cached;
  }

  throw Exception('Unable to load items. Please check your connection.');
}
```

## Error Status Codes

| Code | Meaning | Retryable |
|------|---------|-----------|
| 400 | Bad Request | ❌ |
| 401 | Unauthorized | ❌ |
| 403 | Forbidden | ❌ |
| 404 | Not Found | ❌ |
| 408 | Request Timeout | ✅ |
| 429 | Too Many Requests | ✅ |
| 500 | Internal Server Error | ✅ |
| 502 | Bad Gateway | ✅ |
| 503 | Service Unavailable | ✅ |
| 504 | Gateway Timeout | ✅ |

## Retry Strategy

### Exponential Backoff
- Attempt 1: 1 second delay
- Attempt 2: 2 seconds delay
- Attempt 3: 4 seconds delay
- Maximum: 3 attempts

### When to Retry
✅ Network timeouts  
✅ Connection errors  
✅ 5xx server errors  
✅ 408, 429 status codes  

❌ 4xx client errors (except 408, 429)  
❌ Authentication errors  
❌ Validation errors  

## Health Check Endpoints

| Endpoint | Purpose |
|----------|---------|
| `GET /health` | Overall health status |
| `GET /health/ready` | Readiness probe |
| `GET /health/live` | Liveness probe |

## Logging Best Practices

### Backend
```typescript
// Log with context
this.logger.log('User logged in', { userId, timestamp });

// Log errors with stack
this.logger.error('Operation failed', error.stack);

// Warn on degraded performance
this.logger.warn('Slow query detected', { duration, query });
```

### Mobile
```dart
// Log errors
ErrorHandler.logError(
  error,
  stackTrace: stackTrace,
  context: 'Fetching data',
  additionalData: {'userId': userId},
);

// Use logger
_logger.d('Debug message');
_logger.i('Info message');
_logger.w('Warning message');
_logger.e('Error message', error: e, stackTrace: st);
```

## UI Components

| Component | Use Case |
|-----------|----------|
| `ErrorDisplay` | Full-screen errors |
| `InlineErrorWidget` | Inline errors |
| `LoadingWidget` | Loading states |
| `EmptyStateWidget` | Empty states |
| `NetworkErrorBanner` | Network errors |
| `FallbackAnimation` | Safe animations |

## Testing

### Backend
```bash
# Test error handling
curl http://localhost:3000/api/nonexistent

# Test health
curl http://localhost:3000/health
```

### Mobile
```dart
// Test retry logic
test('should retry on timeout', () async {
  final result = await ErrorHandler.withRetry(
    () => throwsTimeout(),
    maxAttempts: 3,
  );
  expect(result, isNotNull);
});

// Test error messages
test('should return user-friendly message', () {
  final message = ErrorHandler.getUserMessage(error);
  expect(message, contains('timeout'));
});
```
