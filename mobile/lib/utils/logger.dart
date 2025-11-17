import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Centralized logger utility for FluentFly mobile app
/// Provides structured logging with different log levels and error tracking
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  late final Logger _logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    _logger = Logger(
      filter: _AppLogFilter(),
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: _AppLogOutput(),
    );
  }

  /// Log debug message
  void debug(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    // Track error for analytics/monitoring
    _trackError(message, error, stackTrace);
  }

  /// Log fatal error message
  void fatal(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.f(message, error: error, stackTrace: stackTrace);

    // Track fatal error for analytics/monitoring
    _trackError(message, error, stackTrace, isFatal: true);
  }

  /// Track error for monitoring and analytics
  void _trackError(
    String message,
    dynamic error,
    StackTrace? stackTrace, {
    bool isFatal = false,
  }) {
    // In production, this would send to error tracking service (e.g., Sentry, Firebase Crashlytics)
    if (kReleaseMode) {
      // TODO: Integrate with error tracking service
      // Example: FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: isFatal);
      debugPrint('Error tracked: $message');
    }
  }

  /// Log HTTP request
  void logRequest(String method, String url, {Map<String, dynamic>? data}) {
    _logger.i('→ $method $url', error: data != null ? 'Data: $data' : null);
  }

  /// Log HTTP response
  void logResponse(String method, String url, int statusCode, {int? duration}) {
    final durationStr = duration != null ? ' - ${duration}ms' : '';
    if (statusCode >= 200 && statusCode < 300) {
      _logger.i('← $method $url $statusCode$durationStr');
    } else if (statusCode >= 400) {
      _logger.e('← $method $url $statusCode$durationStr');
    } else {
      _logger.w('← $method $url $statusCode$durationStr');
    }
  }

  /// Log user action
  void logUserAction(String action, {Map<String, dynamic>? properties}) {
    _logger.i(
      'User Action: $action',
      error: properties != null ? properties : null,
    );
  }

  /// Log performance metric
  void logPerformance(String operation, int durationMs) {
    if (durationMs > 3000) {
      _logger.w('Performance: $operation took ${durationMs}ms [SLOW]');
    } else {
      _logger.d('Performance: $operation took ${durationMs}ms');
    }
  }
}

/// Custom log filter to control which logs are shown
class _AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only show warnings and errors
    if (kReleaseMode) {
      return event.level.index >= Level.warning.index;
    }
    // In debug mode, show all logs
    return true;
  }
}

/// Custom log output to handle different environments
class _AppLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (var line in event.lines) {
      // In debug mode, print to console
      if (kDebugMode) {
        debugPrint(line);
      }

      // In release mode, could send to remote logging service
      if (kReleaseMode) {
        // TODO: Send to remote logging service
        // Example: Send to CloudWatch, Datadog, etc.
      }
    }
  }
}

/// Global logger instance for easy access
final logger = AppLogger();
