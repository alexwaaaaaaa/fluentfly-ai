import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/error_handler.dart';

/// Error display widget with retry option
class ErrorDisplay extends StatelessWidget {
  final dynamic error;
  final VoidCallback? onRetry;
  final String? customMessage;
  final bool showRetryButton;

  const ErrorDisplay({
    Key? key,
    required this.error,
    this.onRetry,
    this.customMessage,
    this.showRetryButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? ErrorHandler.getUserMessage(error);
    final isRetryable = ErrorHandler.isRetryable(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error animation
            _buildErrorAnimation(),
            const SizedBox(height: 24),

            // Error message
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
            ),

            // Retry button
            if (showRetryButton && isRetryable && onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorAnimation() {
    return SizedBox(
      width: 200,
      height: 200,
      child: LottieBuilder.asset(
        'assets/lottie/sad_robot_retry.json',
        repeat: false,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if animation fails
          return const Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.redAccent,
          );
        },
      ),
    );
  }
}

/// Compact error widget for inline display
class InlineErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const InlineErrorWidget({Key? key, required this.message, this.onRetry})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white70)),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 12),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              color: Colors.white70,
              tooltip: 'Retry',
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading state with fallback
class LoadingWidget extends StatelessWidget {
  final String? message;

  const LoadingWidget({Key? key, this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: LottieBuilder.asset(
              'assets/lottie/blue_wave_loader.json',
              errorBuilder: (context, error, stackTrace) {
                // Fallback to circular progress indicator
                return const CircularProgressIndicator();
              },
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

/// Empty state widget
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    Key? key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.onAction,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.white30),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network error banner
class NetworkErrorBanner extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkErrorBanner({Key? key, this.onRetry}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.red.shade900,
      child: Row(
        children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'No internet connection',
              style: TextStyle(color: Colors.white),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

/// Fallback animation widget
class FallbackAnimation extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final bool repeat;
  final Widget? fallbackWidget;

  const FallbackAnimation({
    Key? key,
    required this.assetPath,
    this.width,
    this.height,
    this.repeat = true,
    this.fallbackWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: LottieBuilder.asset(
        assetPath,
        repeat: repeat,
        errorBuilder: (context, error, stackTrace) {
          // Try fallback pulse animation
          return LottieBuilder.asset(
            'assets/lottie/fallback_pulse.json',
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              // Final fallback to custom widget or icon
              return fallbackWidget ??
                  const Icon(Icons.animation, size: 48, color: Colors.white30);
            },
          );
        },
      ),
    );
  }
}
