import 'dart:io';
import 'package:dio/dio.dart';
import '../models/chat_message.dart';
import '../models/feedback.dart';
import 'api_service.dart';

class AiService {
  final ApiService _apiService;

  AiService(this._apiService);

  /// Process a chat turn with the AI tutor
  /// Sends user text and receives AI response with TTS audio
  Future<ChatResponse> processChatTurn({
    required String text,
    String? sessionId,
  }) async {
    try {
      final response = await _apiService.post(
        '/chat/turn',
        data: {'text': text, if (sessionId != null) 'sessionId': sessionId},
        enableRetry: true,
      );

      return ChatResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      print('Error processing chat turn: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Unable to connect to AI tutor. Please try again.');
    }
  }

  /// Upload audio file and get transcription + AI response
  Future<ChatResponse> processChatTurnWithAudio({
    required File audioFile,
    String? sessionId,
  }) async {
    try {
      // First, upload audio and get transcription
      final sttResponse = await _uploadAudioForSTT(audioFile);

      if (sttResponse['text'] == null ||
          (sttResponse['text'] as String).isEmpty) {
        throw Exception(
          'Could not understand audio. Please try speaking again.',
        );
      }

      final transcribedText = sttResponse['text'] as String;

      // Then process the transcribed text through chat
      return await processChatTurn(text: transcribedText, sessionId: sessionId);
    } catch (e, stackTrace) {
      print('Error processing audio chat turn: $e');
      print('Stack trace: $stackTrace');

      if (e.toString().contains('Could not understand audio')) {
        rethrow;
      }
      throw Exception('Failed to process your speech. Please try again.');
    }
  }

  /// Upload audio file for speech-to-text conversion
  Future<Map<String, dynamic>> _uploadAudioForSTT(File audioFile) async {
    try {
      final formData = FormData.fromMap({
        'audio': await MultipartFile.fromFile(
          audioFile.path,
          filename: 'recording.m4a',
        ),
      });

      final response = await _apiService.post(
        '/speech/stt',
        data: formData,
        enableRetry: true,
      );

      return response.data;
    } catch (e, stackTrace) {
      print('Error uploading audio for STT: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  /// Generate feedback for a conversation session
  Future<FeedbackResponse> generateFeedback({
    required String sessionId,
    required List<ChatMessage> messages,
  }) async {
    try {
      final response = await _apiService.post(
        '/chat/feedback',
        data: {
          'sessionId': sessionId,
          'transcript': messages
              .map(
                (msg) => {
                  'role': msg.isUser ? 'user' : 'assistant',
                  'text': msg.text,
                  'timestamp': msg.timestamp.toIso8601String(),
                },
              )
              .toList(),
        },
      );

      return FeedbackResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to generate feedback: $e');
    }
  }

  /// Get text-to-speech audio URL for a given text
  Future<String> getTextToSpeech(String text) async {
    try {
      final response = await _apiService.post(
        '/speech/tts',
        data: {'text': text},
      );

      return response.data['audioUrl'] as String;
    } catch (e) {
      throw Exception('Failed to get TTS audio: $e');
    }
  }
}
