import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';

/// Utility class for managing Lottie animations with preloading and error handling
class AnimationUtils {
  // Animation paths
  static const String appIntroPlane = 'assets/lottie/app_intro_plane.json';
  static const String aiTutorTalking = 'assets/lottie/ai_tutor_talking.json';
  static const String successConfetti = 'assets/lottie/success_confetti.json';
  static const String blueWaveLoader = 'assets/lottie/blue_wave_loader.json';
  static const String flyingXpCoins = 'assets/lottie/flying_xp_coins.json';
  static const String audioWaveMic = 'assets/lottie/audio_wave_mic.json';
  static const String happyFeedbackStar =
      'assets/lottie/happy_feedback_star.json';
  static const String sadRobotRetry = 'assets/lottie/sad_robot_retry.json';
  static const String floatingShapesBg =
      'assets/lottie/floating_shapes_bg.json';
  static const String progressTrophy = 'assets/lottie/progress_trophy.json';
  static const String fallbackPulse = 'assets/lottie/fallback_pulse.json';

  // Cache for preloaded animations
  static final Map<String, LottieComposition> _compositionCache = {};

  /// Preload critical animations on app startup
  static Future<void> preloadAnimations() async {
    final criticalAnimations = [
      appIntroPlane,
      aiTutorTalking,
      blueWaveLoader,
      fallbackPulse,
      audioWaveMic,
    ];

    await Future.wait(
      criticalAnimations.map((path) => _preloadAnimation(path)),
    );
  }

  /// Preload a single animation
  static Future<void> _preloadAnimation(String path) async {
    try {
      final data = await rootBundle.load(path);
      final composition = await LottieComposition.fromByteData(data);
      _compositionCache[path] = composition;
      debugPrint('Preloaded animation: $path');
    } catch (e) {
      debugPrint('Failed to preload animation $path: $e');
    }
  }

  /// Get a preloaded composition or null if not cached
  static LottieComposition? getCachedComposition(String path) {
    return _compositionCache[path];
  }

  /// Build a Lottie animation with error handling and fallback
  static Widget buildAnimation({
    required String path,
    double? width,
    double? height,
    BoxFit? fit,
    bool repeat = true,
    bool reverse = false,
    AnimationController? controller,
    VoidCallback? onLoaded,
  }) {
    return LottieBuilder.asset(
      path,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      repeat: repeat,
      reverse: reverse,
      controller: controller,
      onLoaded: (composition) {
        if (onLoaded != null) {
          onLoaded();
        }
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error loading animation $path: $error');
        // Return fallback animation
        return _buildFallbackAnimation(width: width, height: height, fit: fit);
      },
    );
  }

  /// Build fallback animation when primary animation fails
  static Widget _buildFallbackAnimation({
    double? width,
    double? height,
    BoxFit? fit,
  }) {
    return LottieBuilder.asset(
      fallbackPulse,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      repeat: true,
      errorBuilder: (context, error, stackTrace) {
        // If even fallback fails, show a simple loading indicator
        return SizedBox(
          width: width ?? 100,
          height: height ?? 100,
          child: const Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  /// Build animation with audio sync capability
  static Widget buildSyncedAnimation({
    required String path,
    required bool isPlaying,
    double? width,
    double? height,
    BoxFit? fit,
    VoidCallback? onComplete,
  }) {
    return LottieBuilder.asset(
      path,
      width: width,
      height: height,
      fit: fit ?? BoxFit.contain,
      repeat: isPlaying,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackAnimation(width: width, height: height, fit: fit);
      },
    );
  }

  /// Clear animation cache to free memory
  static void clearCache() {
    _compositionCache.clear();
    debugPrint('Animation cache cleared');
  }

  /// Get cache size for debugging
  static int getCacheSize() {
    return _compositionCache.length;
  }
}

/// Extension for easy animation building
extension AnimationExtension on String {
  /// Build a Lottie animation from this path with error handling
  Widget toLottie({
    double? width,
    double? height,
    BoxFit? fit,
    bool repeat = true,
    bool reverse = false,
  }) {
    return AnimationUtils.buildAnimation(
      path: this,
      width: width,
      height: height,
      fit: fit,
      repeat: repeat,
      reverse: reverse,
    );
  }
}
