import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/livekit_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  group('LiveKitService', () {
    late LiveKitService service;

    setUp(() {
      service = LiveKitService();
    });

    tearDown(() {
      service.dispose();
    });

    test('should be instantiated', () {
      expect(service, isNotNull);
      expect(service.isConnected, isFalse);
      expect(service.room, isNull);
    });

    test('should have null tracks initially', () {
      expect(service.localVideoTrack, isNull);
      expect(service.localAudioTrack, isNull);
    });

    test('should provide connection state stream', () {
      expect(service.connectionStateStream, isNotNull);
    });

    test('should provide remote track stream', () {
      expect(service.remoteTrackStream, isNotNull);
    });

    test('should provide connection quality stream', () {
      expect(service.connectionQualityStream, isNotNull);
    });

    test('should provide connection event stream', () {
      expect(service.connectionEventStream, isNotNull);
    });

    group('Permission handling', () {
      test('PermissionException should have correct message for denied', () {
        final exception = PermissionException(PermissionResult.denied);
        expect(
          exception.toString(),
          contains('Camera and microphone permissions are required'),
        );
      });

      test(
        'PermissionException should have correct message for permanently denied',
        () {
          final exception = PermissionException(
            PermissionResult.permanentlyDenied,
          );
          expect(
            exception.toString(),
            contains('Permissions permanently denied'),
          );
        },
      );

      test('PermissionException should have correct message for error', () {
        final exception = PermissionException(PermissionResult.error);
        expect(exception.toString(), contains('Error requesting permissions'));
      });
    });

    group('Connection state', () {
      test('isConnected should return false when not connected', () {
        expect(service.isConnected, isFalse);
      });

      test('room should be null initially', () {
        expect(service.room, isNull);
      });
    });

    group('Cleanup', () {
      test('dispose should clean up resources', () {
        service.dispose();
        // Should not throw error
        expect(true, isTrue);
      });

      test('disconnect should handle null room', () async {
        await service.disconnect();
        // Should not throw error
        expect(true, isTrue);
      });
    });
  });

  group('PermissionResult', () {
    test('should have all expected values', () {
      expect(PermissionResult.granted, isNotNull);
      expect(PermissionResult.denied, isNotNull);
      expect(PermissionResult.permanentlyDenied, isNotNull);
      expect(PermissionResult.error, isNotNull);
    });
  });
}
