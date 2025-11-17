import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';

/// Provider for ApiService singleton
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

/// Provider for AiService
final aiServiceProvider = Provider<AiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AiService(apiService);
});

/// Provider for chat messages in current session
final chatMessagesProvider = StateProvider<List<ChatMessage>>((ref) => []);

/// Provider for current session ID
final chatSessionIdProvider = StateProvider<String?>((ref) => null);

/// Provider for AI speaking state
final aiSpeakingProvider = StateProvider<bool>((ref) => false);

/// Provider for current AI emotion
final aiEmotionProvider = StateProvider<String>((ref) => 'neutral');
