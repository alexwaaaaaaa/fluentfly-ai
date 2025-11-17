import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/providers/video_call_provider.dart';
import 'package:livekit_client/livekit_client.dart';

void main() {
  group('ConversationTurn', () {
    test('should create conversation turn', () {
      final turn = ConversationTurn(
        speaker: 'user',
        text: 'Hello',
        timestamp: DateTime.now(),
      );

      expect(turn.speaker, equals('user'));
      expect(turn.text, equals('Hello'));
      expect(turn.timestamp, isNotNull);
    });

    test('should convert to JSON', () {
      final timestamp = DateTime.now();
      final turn = ConversationTurn(
        speaker: 'ai',
        text: 'Hi there',
        timestamp: timestamp,
      );

      final json = turn.toJson();

      expect(json['speaker'], equals('ai'));
      expect(json['text'], equals('Hi there'));
      expect(json['timestamp'], equals(timestamp.toIso8601String()));
    });
  });

  group('VideoCallState', () {
    test('should create initial state', () {
      final state = VideoCallState.initial(5);

      expect(
        state.connectionState,
        equals(VideoCallConnectionState.disconnected),
      );
      expect(state.isMuted, isFalse);
      expect(state.isCameraOn, isTrue);
      expect(state.callDuration, equals(Duration.zero));
      expect(state.conversationTurns, isEmpty);
      expect(state.connectionQuality, equals(ConnectionQuality.unknown));
      expect(state.lessonId, equals(5));
      expect(state.roomName, isNull);
      expect(state.sessionId, isNull);
    });

    test('should copy with new values', () {
      final state = VideoCallState.initial(5);
      final newState = state.copyWith(
        connectionState: VideoCallConnectionState.connected,
        isMuted: true,
        callDuration: const Duration(seconds: 30),
      );

      expect(
        newState.connectionState,
        equals(VideoCallConnectionState.connected),
      );
      expect(newState.isMuted, isTrue);
      expect(newState.callDuration, equals(const Duration(seconds: 30)));
      expect(newState.lessonId, equals(5)); // Unchanged
    });

    test('should calculate turn count', () {
      final state = VideoCallState.initial(5).copyWith(
        conversationTurns: [
          ConversationTurn(
            speaker: 'user',
            text: 'Hello',
            timestamp: DateTime.now(),
          ),
          ConversationTurn(
            speaker: 'ai',
            text: 'Hi',
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(state.turnCount, equals(2));
    });

    test('should estimate user speaking time', () {
      final state = VideoCallState.initial(5).copyWith(
        conversationTurns: [
          ConversationTurn(
            speaker: 'user',
            text: 'Hello',
            timestamp: DateTime.now(),
          ),
          ConversationTurn(
            speaker: 'user',
            text: 'How are you',
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(
        state.userSpeakingTime.inSeconds,
        equals(10),
      ); // 2 turns * 5 seconds
    });

    test('should estimate AI speaking time', () {
      final state = VideoCallState.initial(5).copyWith(
        conversationTurns: [
          ConversationTurn(
            speaker: 'ai',
            text: 'Hello',
            timestamp: DateTime.now(),
          ),
          ConversationTurn(
            speaker: 'ai',
            text: 'How can I help',
            timestamp: DateTime.now(),
          ),
          ConversationTurn(
            speaker: 'ai',
            text: 'Let me know',
            timestamp: DateTime.now(),
          ),
        ],
      );

      expect(state.aiSpeakingTime.inSeconds, equals(15)); // 3 turns * 5 seconds
    });

    test('should handle empty conversation turns', () {
      final state = VideoCallState.initial(5);

      expect(state.turnCount, equals(0));
      expect(state.userSpeakingTime.inSeconds, equals(0));
      expect(state.aiSpeakingTime.inSeconds, equals(0));
    });

    test('should set error message', () {
      final state = VideoCallState.initial(
        5,
      ).copyWith(errorMessage: 'Connection failed');

      expect(state.errorMessage, equals('Connection failed'));
    });

    test('should track connection events', () {
      final state = VideoCallState.initial(
        5,
      ).copyWith(connectionEvents: ['Event 1', 'Event 2', 'Event 3']);

      expect(state.connectionEvents.length, equals(3));
      expect(state.connectionEvents[0], equals('Event 1'));
    });

    test('should show quality warning', () {
      final state = VideoCallState.initial(
        5,
      ).copyWith(showQualityWarning: true);

      expect(state.showQualityWarning, isTrue);
    });
  });

  group('VideoCallConnectionState', () {
    test('should have all expected states', () {
      expect(VideoCallConnectionState.disconnected, isNotNull);
      expect(VideoCallConnectionState.connecting, isNotNull);
      expect(VideoCallConnectionState.connected, isNotNull);
      expect(VideoCallConnectionState.reconnecting, isNotNull);
      expect(VideoCallConnectionState.failed, isNotNull);
    });

    test('isReconnecting extension should work correctly', () {
      expect(VideoCallConnectionState.reconnecting.isReconnecting, isTrue);
      expect(VideoCallConnectionState.connected.isReconnecting, isFalse);
      expect(VideoCallConnectionState.disconnected.isReconnecting, isFalse);
    });
  });
}
