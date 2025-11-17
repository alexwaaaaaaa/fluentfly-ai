import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Centralized error handling utility for the FluentFly app
class ErrorHandler {
  /// Convert any error to a user-friendly message
  static String getUserMessage(dynamic error, {String? fallbackMessage}) {
    if (error is DioException) {
      return _handleDioError(error);
    } else if (error is FormatException) {
      return 'Invalid data format received. Please try again.';
    } else if (error is TypeError) {
      return 'Data processing error. Please try again.';
    } else if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    } else if (error is String) {
      return error;
    }

    return fallbackMessage ?? 'Something went wrong. Please try again.';
  }

  /// Handle Dio-specific errors
  static String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';

      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';

      case DioExceptionType.receiveTimeout:
        return 'Server response timeout. Please try again.';

      case DioExceptionType.badResponse:
        return _parseApiError(error.response);

      case DioExceptionType.cancel:
        return 'Request was cancelled.';

      case DioExceptionType.connectionError:
        return 'No internet connection. Please check your network.';

      case DioExceptionType.badCertificate:
        return 'Security certificate error. Please try again.';

      case DioExceptionType.unknown:
        if (error.message?.contains('SocketException') ?? false) {
          return 'Network error. Please check your internet connection.';
        }
        return 'Network error occurred. Please try again.';
    }
  }

  /// Parse API error response
  static String _parseApiError(Response? response) {
    if (response == null) {
      return 'Server error occurred. Please try again.';
    }

    final statusCode = response.statusCode ?? 500;

    // Try to extract message from response data
    if (response.data is Map) {
      final data = response.data as Map;
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
    }

    // Return status-based message
    return _getStatusMessage(statusCode);
  }

  /// Get user-friendly message based on HTTP status code
  static String _getStatusMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Please log in to continue.';
      case 403:
        return 'You do not have permission to access this.';
      case 404:
        return 'Resource not found.';
      case 408:
        return 'Request timeout. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      case 502:
        return 'Service temporarily unavailable.';
      case 503:
        return 'Service temporarily unavailable. Please try again later.';
      case 504:
        return 'Gateway timeout. Please try again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  /// Check if error is retryable
  static bool isRetryable(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;

        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          // Retry on 5xx errors, 408, and 429
          return statusCode >= 500 || statusCode == 408 || statusCode == 429;

        default:
          return false;
      }
    }
    return false;
  }

  /// Execute operation with error handling and optional fallback
  static Future<T> withErrorHandling<T>(
    Future<T> Function() operation, {
    T? fallback,
    Function(dynamic error)? onError,
  }) async {
    try {
      return await operation();
    } catch (e, stackTrace) {
      // Log error in debug mode
      if (kDebugMode) {
        print('Error in operation: $e');
        print('Stack trace: $stackTrace');
      }

      // Call error callback if provided
      if (onError != null) {
        onError(e);
      }

      // Return fallback if provided
      if (fallback != null) {
        return fallback;
      }

      // Rethrow if no fallback
      rethrow;
    }
  }

  /// Execute operation with retry logic
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempt++;

        // Check if we should retry
        final canRetry = shouldRetry?.call(e) ?? isRetryable(e);

        if (attempt >= maxAttempts || !canRetry) {
          rethrow;
        }

        // Log retry attempt in debug mode
        if (kDebugMode) {
          print(
            'Retry attempt $attempt/$maxAttempts after ${delay.inSeconds}s',
          );
        }

        // Wait before retrying
        await Future.delayed(delay);

        // Increase delay for next attempt (exponential backoff)
        delay = Duration(
          milliseconds: (delay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }

  /// Log error for debugging and analytics
  static void logError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      print('=== ERROR LOG ===');
      if (context != null) {
        print('Context: $context');
      }
      print('Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
      if (additionalData != null) {
        print('Additional data: $additionalData');
      }
      print('=================');
    }

    // TODO: Send to analytics/crash reporting service in production
    // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
}
