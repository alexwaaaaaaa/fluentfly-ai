# FluentFly Logging Utilities

This document describes the logging infrastructure for the FluentFly mobile application.

## Overview

The FluentFly mobile app uses a centralized logging system built on top of the `logger` package. This provides structured logging with different log levels, error tracking, and performance monitoring.

## Logger Utility

The `AppLogger` class (`lib/utils/logger.dart`) provides a singleton instance for consistent logging across the application.

### Usage

```dart
import '../utils/logger.dart';

// Debug logging (development only)
logger.debug('User tapped lesson card', error: {'lessonId': 123});

// Info logging
logger.info('Lesson loaded successfully');

// Warning logging
logger.warning('Slow network detected');

// Error logging
logger.error('Failed to load lesson', error: error, stackTrace: stackTrace);

// Fatal error logging
logger.fatal('Critical error occurred', error: error, stackTrace: stackTrace);
```

### Specialized Logging Methods

#### HTTP Request/Response Logging

```dart
// Log HTTP request
logger.logRequest('GET', '/api/lessons/123');

// Log HTTP response
logger.logResponse('GET', '/api/lessons/123', 200, duration: 150);
```

#### User Action Logging

```dart
logger.logUserAction('lesson_completed', properties: {
  'lessonId': 123,
  'score': 85,
  'duration': 300,
});
```

#### Performance Logging

```dart
final stopwatch = Stopwatch()..start();
// ... perform operation ...
stopwatch.stop();
logger.logPerformance('load_lesson', stopwatch.elapsedMilliseconds);
```

## Log Levels

The logger supports the following log levels:

1. **Debug** - Detailed information for debugging (development only)
2. **Info** - General informational messages
3. **Warning** - Warning messages for potentially harmful situations
4. **Error** - Error messages for error events
5. **Fatal** - Critical errors that may cause app failure

## Environment-Specific Behavior

### Debug Mode
- All log levels are shown
- Logs are printed to console with colors and emojis
- Stack traces include up to 8 method calls

### Release Mode
- Only warnings, errors, and fatal logs are shown
- Logs can be sent to remote logging service
- Errors are tracked for monitoring

## Error Tracking

Errors logged with `error()` or `fatal()` methods are automatically tracked for monitoring and analytics. In production, these should be integrated with services like:

- Firebase Crashlytics
- Sentry
- Datadog
- Custom logging backend

### Integration Example

```dart
// In lib/utils/logger.dart, update _trackError method:
void _trackError(String message, dynamic error, StackTrace? stackTrace, {bool isFatal = false}) {
  if (kReleaseMode) {
    // Send to Firebase Crashlytics
    FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: isFatal,
      reason: message,
    );
    
    // Or send to custom backend
    // analyticsService.trackError(message, error, stackTrace);
  }
}
```

## Best Practices

### 1. Use Appropriate Log Levels

```dart
// ✅ Good
logger.debug('Cache hit for lesson ${lessonId}');
logger.info('User logged in successfully');
logger.warning('Network latency is high: ${latency}ms');
logger.error('Failed to save progress', error: e);

// ❌ Bad
logger.error('User tapped button'); // Should be debug or info
logger.debug('Critical database error'); // Should be error or fatal
```

### 2. Include Context

```dart
// ✅ Good
logger.error('Failed to load lesson', error: e, stackTrace: st);

// ❌ Bad
logger.error('Error occurred');
```

### 3. Avoid Logging Sensitive Data

```dart
// ✅ Good
logger.info('User authenticated', error: {'userId': user.id});

// ❌ Bad
logger.info('User authenticated', error: {
  'email': user.email,
  'password': password,
  'token': authToken,
});
```

### 4. Use Structured Logging

```dart
// ✅ Good
logger.logUserAction('lesson_completed', properties: {
  'lessonId': lesson.id,
  'score': score,
  'duration': duration,
});

// ❌ Bad
logger.info('User completed lesson ${lesson.id} with score $score in $duration seconds');
```

## Performance Considerations

- Logging is lightweight and should not impact app performance
- In release mode, debug logs are filtered out before processing
- Consider using lazy evaluation for expensive log messages:

```dart
// ✅ Good - only evaluated if debug logging is enabled
if (kDebugMode) {
  logger.debug('Expensive computation: ${expensiveFunction()}');
}

// ❌ Bad - always evaluated even if not logged
logger.debug('Expensive computation: ${expensiveFunction()}');
```

## Integration with Services

The centralized logger is already integrated with:

- **ApiService** - HTTP request/response logging
- **AuthService** - Authentication event logging
- **LessonService** - Lesson loading and caching
- **AudioService** - Audio recording and playback
- **CacheService** - Cache operations
- **ConnectivityService** - Network status changes

## Monitoring and Analytics

In production, logs can be aggregated and analyzed using:

1. **Error Tracking**: Firebase Crashlytics, Sentry
2. **Analytics**: Firebase Analytics, Mixpanel
3. **APM**: Datadog, New Relic
4. **Custom Backend**: Send logs to your own logging service

## Testing

When writing tests, you can mock the logger to verify logging behavior:

```dart
// In test file
import 'package:mockito/mockito.dart';
import 'package:mobile/utils/logger.dart';

class MockLogger extends Mock implements AppLogger {}

void main() {
  test('should log error when API call fails', () async {
    final mockLogger = MockLogger();
    // ... test implementation
    verify(mockLogger.error(any, error: any, stackTrace: any)).called(1);
  });
}
```

## Future Enhancements

- [ ] Remote logging service integration
- [ ] Log aggregation and search
- [ ] Real-time error alerts
- [ ] Performance monitoring dashboard
- [ ] User session replay
- [ ] A/B testing integration
