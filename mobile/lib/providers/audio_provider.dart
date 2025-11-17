import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_service.dart';

/// Provider for AudioService singleton
final audioServiceProvider = Provider<AudioService>((ref) {
  final audioService = AudioService();

  // Dispose when provider is disposed
  ref.onDispose(() {
    audioService.dispose();
  });

  return audioService;
});

/// Provider for recording state
final isRecordingProvider = StateProvider<bool>((ref) => false);

/// Provider for playing state
final isPlayingProvider = StateProvider<bool>((ref) => false);
