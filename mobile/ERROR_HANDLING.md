# Error Handling and Resilience - Flutter Mobile

This document describes the comprehensive error handling and resilience mechanisms implemented in the FluentFly mobile app.

## Overview

The mobile app implements multiple layers of error handling to ensure reliability and provide a smooth user experience:

1. **Error Handler Utility** - Centralized error processing
2. **Retry Logic** - Automatic retry with exponential backoff
3. **Fallback UI Components** - Graceful error display
4. **Service-Level Error Handling** - Try-catch in all async operations
5. **Offline Support** - Cached data fallbacks

## Error Handler Utility

Located in `lib/utils/error_handler.dart`

### Features

- Converts technical errors to user-friendly messages
- Determines if errors are retryable
- Provides retry logic with exponential backoff
- Logs errors for debugging
- Wraps operations with error handling

### Usage

#### Get User-Friendly Message

```dart
try {
  await someOperation();
} catch (e) {
  final message = ErrorHandler.getUserMessage(e);
  showSnackBar(message);
}
```

#### Check if Retryable

```dart
if (ErrorHandler.isRetryable(error)) {
  // Show retry button
}
```

#### Execute with Retry

```dart
final result = await ErrorHandler.withRetry(
  () => apiService.get('/lessons'),
  maxAttempts: 3,
  initialDelay: Duration(seconds: 1),
);
```

#### Execute with Error Handling

```dart
final result = await ErrorHandler.withErrorHandling(
  () => fetchData(),
  fallback: cachedData,
  onError: (error) => logError(error),
);
```

## Error Messages

### Network Errors

- Connection timeout → "Connection timeout. Please check your internet connection."
- Send timeout → "Request timeout. Please try again."
- Receive timeout → "Server response timeout. Please try again."
- Connection error → "No internet connection. Please check your network."
- Bad certificate → "Security certificate error. Please try again."

### API Errors

- 400 → "Invalid request. Please check your input."
- 401 → "Please log in to continue."
- 403 → "You do not have permission to access this."
- 404 → "Resource not found."
- 408 → "Request timeout. Please try again."
- 429 → "Too many requests. Please wait a moment."
- 500 → "Server error. Please try again later."
- 503 → "Service temporarily unavailable. Please try again later."

## Fallback UI Components

Located in `lib/widgets/error_widgets.dart`

### ErrorDisplay

Full-screen error display with retry option:

```dart
ErrorDisplay(
  error: error,
  onRetry: () => fetchData(),
  customMessage: 'Failed to load lessons',
)
```

Features:
- Animated error illustration (sad_robot_retry.json)
- User-friendly error message
- Retry button (if error is retryable)
- Fallback to icon if animation fails

### InlineErrorWidget

Compact error display for inline use:

```dart
InlineErrorWidget(
  message: 'Failed to load data',
  onRetry: () => fetchData(),
)
```

### LoadingWidget

Loading state with animation:

```dart
LoadingWidget(
  message: 'Loading lessons...',
)
```

Features:
- Animated loader (blue_wave_loader.json)
- Fallback to CircularProgressIndicator
- Optional message

### EmptyStateWidget

Empty state display:

```dart
EmptyStateWidget(
  title: 'No Lessons Yet',
  message: 'Start your learning journey',
  icon: Icons.school,
  onAction: () => navigateToLessons(),
  actionLabel: 'Browse Lessons',
)
```

### NetworkErrorBanner

Banner for network errors:

```dart
NetworkErrorBanner(
  onRetry: () => retryConnection(),
)
```

### FallbackAnimation

Safe Lottie animation with fallback:

```dart
FallbackAnimation(
  assetPath: 'assets/lottie/ai_tutor_talking.json',
  width: 200,
  height: 200,
  fallbackWidget: Icon(Icons.person),
)
```

Fallback chain:
1. Try primary animation
2. Try fallback_pulse.json
3. Show custom widget or icon

## API Service Retry Logic

Located in `lib/services/api_service.dart`

### Features

- Automatic retry for retryable errors
- Exponential backoff (1s, 2s, 4s)
- Maximum 3 retry attempts
- Token refresh on 401 errors
- Comprehensive error logging

### Configuration

```dart
static const int maxRetries = 3;
static const Duration retryDelay = Duration(seconds: 1);
```

### Usage

```dart
// With retry (default)
final response = await apiService.get('/lessons');

// Without retry
final response = await apiService.post(
  '/auth/login',
  data: credentials,
  enableRetry: false,
);
```

## Service-Level Error Handling

### Auth Service

```dart
Future<AuthResponse> googleAuth(String idToken) async {
  try {
    final response = await _apiService.post(
      '/auth/google',
      data: {'idToken': idToken},
      enableRetry: false,
    );
    return AuthResponse.fromJson(response.data);
  } catch (e, stackTrace) {
    _logger.e('Google authentication failed', error: e, stackTrace: stackTrace);
    throw Exception('Failed to authenticate with Google. Please try again.');
  }
}
```

### Lesson Service

```dart
Future<List<Lesson>> getLessons() async {
  try {
    // Try API first
    if (_connectivityService.isOnline) {
      final response = await _apiService.get('/lessons', enableRetry: true);
      final lessons = parseLessons(response.data);
      await _cacheService.cacheLessons(lessons);
      return lessons;
    }
  } catch (e) {
    _logger.e('Error fetching lessons', error: e);
  }

  // Fallback to cache
  final cachedLessons = await _cacheService.getCachedLessons();
  if (cachedLessons != null && cachedLessons.isNotEmpty) {
    return cachedLessons;
  }

  throw Exception('Unable to load lessons. Please check your internet connection.');
}
```

### AI Service

```dart
Future<ChatResponse> processChatTurn({required String text}) async {
  try {
    final response = await _apiService.post(
      '/chat/turn',
      data: {'text': text},
      enableRetry: true,
    );
    return ChatResponse.fromJson(response.data);
  } catch (e, stackTrace) {
    _logger.e('Error processing chat turn', error: e, stackTrace: stackTrace);
    throw Exception('Unable to connect to AI tutor. Please try again.');
  }
}
```

## Retry Strategy

### Exponential Backoff

```dart
Duration delay = initialDelay;
for (int attempt = 0; attempt < maxAttempts; attempt++) {
  try {
    return await operation();
  } catch (e) {
    if (!shouldRetry(e) || attempt == maxAttempts - 1) {
      rethrow;
    }
    await Future.delayed(delay);
    delay = Duration(milliseconds: (delay.inMilliseconds * 2.0).round());
  }
}
```

Retry delays:
- Attempt 1: 1 second
- Attempt 2: 2 seconds
- Attempt 3: 4 seconds

### Retryable Errors

Automatically retried:
- Connection timeout
- Send timeout
- Receive timeout
- Connection error
- 5xx server errors
- 408 Request Timeout
- 429 Too Many Requests

Not retried:
- 4xx client errors (except 408, 429)
- Authentication errors (401, 403)
- Validation errors (400)
- Not found errors (404)

## Error Logging

### Debug Mode

```dart
ErrorHandler.logError(
  error,
  stackTrace: stackTrace,
  context: 'Fetching lessons',
  additionalData: {
    'userId': userId,
    'lessonId': lessonId,
  },
);
```

Output:
```
=== ERROR LOG ===
Context: Fetching lessons
Error: DioException [connection timeout]
Stack trace: ...
Additional data: {userId: 123, lessonId: 456}
=================
```

### Production

In production, errors should be sent to a crash reporting service:

```dart
// TODO: Integrate with Firebase Crashlytics
// FirebaseCrashlytics.instance.recordError(error, stackTrace);
```

## Best Practices

### 1. Always Use Try-Catch for Async Operations

```dart
Future<void> fetchData() async {
  try {
    final data = await apiService.get('/data');
    setState(() => this.data = data);
  } catch (e) {
    setState(() => error = e);
  }
}
```

### 2. Provide Fallbacks

```dart
// Try API, fallback to cache
final data = await ErrorHandler.withErrorHandling(
  () => apiService.get('/data'),
  fallback: await cacheService.getCachedData(),
);
```

### 3. Show User-Friendly Messages

```dart
catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(ErrorHandler.getUserMessage(e))),
  );
}
```

### 4. Use Appropriate UI Components

```dart
// Full screen error
if (error != null) {
  return ErrorDisplay(error: error, onRetry: fetchData);
}

// Inline error
if (error != null) {
  return InlineErrorWidget(
    message: ErrorHandler.getUserMessage(error),
    onRetry: fetchData,
  );
}

// Loading state
if (isLoading) {
  return LoadingWidget(message: 'Loading...');
}
```

### 5. Handle Animation Failures

```dart
FallbackAnimation(
  assetPath: 'assets/lottie/animation.json',
  fallbackWidget: Icon(Icons.animation),
)
```

## Testing Error Handling

### Simulate Network Errors

```dart
// In development, use Dio interceptor to simulate errors
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    if (simulateError) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        ),
      );
    }
    return handler.next(options);
  },
));
```

### Test Retry Logic

```dart
test('should retry on timeout', () async {
  int attempts = 0;
  final result = await ErrorHandler.withRetry(
    () async {
      attempts++;
      if (attempts < 3) {
        throw DioException(
          requestOptions: RequestOptions(path: '/test'),
          type: DioExceptionType.connectionTimeout,
        );
      }
      return 'success';
    },
    maxAttempts: 3,
  );
  
  expect(attempts, 3);
  expect(result, 'success');
});
```

### Test Error Messages

```dart
test('should return user-friendly message', () {
  final error = DioException(
    requestOptions: RequestOptions(path: '/test'),
    type: DioExceptionType.connectionTimeout,
  );
  
  final message = ErrorHandler.getUserMessage(error);
  expect(message, contains('Connection timeout'));
});
```

## Troubleshooting

### Common Issues

#### Infinite Retry Loop
```
Problem: App keeps retrying failed requests
Solution: Check shouldRetry logic and maxAttempts
```

#### Missing Error Messages
```
Problem: Generic error messages shown
Solution: Ensure error types are properly handled in ErrorHandler
```

#### Animation Not Loading
```
Problem: Lottie animations fail to load
Solution: Use FallbackAnimation widget with fallback
```

### Debug Checklist

1. ✅ All async operations wrapped in try-catch
2. ✅ User-friendly error messages displayed
3. ✅ Retry logic enabled for appropriate requests
4. ✅ Fallback UI components used
5. ✅ Errors logged with context
6. ✅ Offline fallbacks implemented
7. ✅ Animation fallbacks in place
