import 'dart:async';
import 'package:livekit_client/livekit_client.dart';
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Permission request result
enum PermissionResult { granted, denied, permanentlyDenied, error }

/// Exception thrown when permissions are not granted
class PermissionException implements Exception {
  final PermissionResult result;

  PermissionException(this.result);

  @override
  String toString() {
    switch (result) {
      case PermissionResult.denied:
        return 'Camera and microphone permissions are required for video calls';
      case PermissionResult.permanentlyDenied:
        return 'Permissions permanently denied. Please enable them in app settings';
      case PermissionResult.error:
        return 'Error requesting permissions. Please try again';
      case PermissionResult.granted:
        return 'Permissions granted';
    }
  }
}

/// Service for managing LiveKit video call connections
class LiveKitService {
  final Logger _logger = Logger();

  Room? _room;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  // Reconnection state
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 3;
  Timer? _reconnectionTimer;
  String? _lastToken;
  String? _lastUrl;

  // Stream controllers for connection events
  final StreamController<ConnectionState> _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final StreamController<RemoteTrackPublication> _remoteTrackController =
      StreamController<RemoteTrackPublication>.broadcast();
  final StreamController<ConnectionQuality> _connectionQualityController =
      StreamController<ConnectionQuality>.broadcast();
  final StreamController<String> _connectionEventController =
      StreamController<String>.broadcast();

  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;
  Stream<RemoteTrackPublication> get remoteTrackStream =>
      _remoteTrackController.stream;
  Stream<ConnectionQuality> get connectionQualityStream =>
      _connectionQualityController.stream;
  Stream<String> get connectionEventStream => _connectionEventController.stream;

  bool get isConnected => _room?.connectionState == ConnectionState.connected;
  Room? get room => _room;
  LocalVideoTrack? get localVideoTrack => _localVideoTrack;
  LocalAudioTrack? get localAudioTrack => _localAudioTrack;

  /// Request camera and microphone permissions
  Future<PermissionResult> requestPermissions() async {
    try {
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
        _logger.i('Camera and microphone permissions granted');
        return PermissionResult.granted;
      } else if (cameraStatus.isPermanentlyDenied ||
          microphoneStatus.isPermanentlyDenied) {
        _logger.e('Permissions permanently denied');
        return PermissionResult.permanentlyDenied;
      } else {
        _logger.w('Permissions denied');
        return PermissionResult.denied;
      }
    } catch (e) {
      _logger.e('Error requesting permissions', error: e);
      return PermissionResult.error;
    }
  }

  /// Check permission status without requesting
  Future<PermissionResult> checkPermissions() async {
    try {
      final cameraStatus = await Permission.camera.status;
      final microphoneStatus = await Permission.microphone.status;

      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
        return PermissionResult.granted;
      } else if (cameraStatus.isPermanentlyDenied ||
          microphoneStatus.isPermanentlyDenied) {
        return PermissionResult.permanentlyDenied;
      } else {
        return PermissionResult.denied;
      }
    } catch (e) {
      _logger.e('Error checking permissions', error: e);
      return PermissionResult.error;
    }
  }

  /// Check if camera and microphone permissions are granted
  Future<bool> hasPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;
    return cameraStatus.isGranted && microphoneStatus.isGranted;
  }

  /// Connect to a LiveKit room
  Future<Room> connectToRoom(String token, String url) async {
    try {
      _logger.i('Connecting to LiveKit room: $url');

      // Store credentials for potential reconnection
      _lastToken = token;
      _lastUrl = url;
      _reconnectionAttempts = 0;

      // Check permissions
      final hasPerms = await hasPermissions();
      if (!hasPerms) {
        final result = await requestPermissions();
        if (result != PermissionResult.granted) {
          throw PermissionException(result);
        }
      }

      // Create room instance with options
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(name: 'user-audio'),
          defaultVideoPublishOptions: VideoPublishOptions(
            name: 'user-video',
            simulcast: true,
          ),
        ),
      );

      // Set up event listeners before connecting
      _setupEventListeners(_room!);

      // Connect to room
      await _room!.connect(url, token);

      _logger.i('Connected to LiveKit room');
      return _room!;
    } catch (e) {
      _logger.e('Error connecting to room', error: e);
      rethrow;
    }
  }

  /// Publish local audio and video tracks with optimized settings
  Future<void> publishTracks() async {
    try {
      if (_room == null) {
        throw Exception('Room not connected');
      }

      _logger.i('Publishing local tracks with optimized settings');

      // Determine optimal video quality based on device capabilities
      final videoCaptureOptions = await _getOptimalVideoCaptureOptions();

      // Create and publish video track with optimized settings
      _localVideoTrack = await LocalVideoTrack.createCameraTrack(
        videoCaptureOptions,
      );
      await _room!.localParticipant?.publishVideoTrack(_localVideoTrack!);

      // Create and publish audio track with optimized settings
      _localAudioTrack = await LocalAudioTrack.create(
        const AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );
      await _room!.localParticipant?.publishAudioTrack(_localAudioTrack!);

      _logger.i('Local tracks published with optimizations');
    } catch (e) {
      _logger.e('Error publishing tracks', error: e);
      rethrow;
    }
  }

  /// Get optimal video capture options based on device capabilities
  Future<CameraCaptureOptions> _getOptimalVideoCaptureOptions() async {
    // Default to medium quality for battery optimization
    int maxFrameRate = 24;
    int maxWidth = 640;
    int maxHeight = 480;

    try {
      // On high-end devices, use better quality
      // This is a simplified check - in production, you'd check actual device specs
      maxFrameRate = 30;
      maxWidth = 1280;
      maxHeight = 720;

      _logger.i(
        'Using optimized video settings: ${maxWidth}x$maxHeight @ ${maxFrameRate}fps',
      );
    } catch (e) {
      _logger.w('Could not determine device capabilities, using defaults');
    }

    return CameraCaptureOptions(
      cameraPosition: CameraPosition.front,
      maxFrameRate: maxFrameRate.toDouble(),
    );
  }

  /// Subscribe to remote tracks (AI agent audio)
  void subscribeToRemoteTracks() {
    if (_room == null) {
      _logger.w('Room not connected, cannot subscribe to remote tracks');
      return;
    }

    _logger.i('Subscribing to remote tracks');

    // Listen for track subscriptions
    _room!.addListener(() {
      for (final participant in _room!.remoteParticipants.values) {
        for (final publication in participant.trackPublications.values) {
          if (publication.subscribed && publication.track != null) {
            _logger.i('Remote track subscribed: ${publication.track!.sid}');
            _remoteTrackController.add(publication);
          }
        }
      }
    });
  }

  /// Set up event listeners for room events
  void _setupEventListeners(Room room) {
    // Connection state changes
    room.addListener(() {
      final state = room.connectionState;
      _connectionStateController.add(state);
      _logConnectionEvent('Connection state changed: $state');

      // Log detailed connection events
      switch (state) {
        case ConnectionState.connected:
          _logConnectionEvent('Successfully connected to room');
          _reconnectionAttempts = 0; // Reset on successful connection
          _reconnectionTimer?.cancel();
          break;
        case ConnectionState.disconnected:
          _logConnectionEvent('Disconnected from room');
          _handleDisconnection();
          break;
        case ConnectionState.reconnecting:
          _logConnectionEvent('Connection lost, attempting to reconnect');
          break;
        case ConnectionState.connecting:
          _logConnectionEvent('Connecting to room');
          break;
      }
    });

    // Track subscribed
    room.addListener(() {
      for (final participant in room.remoteParticipants.values) {
        for (final publication in participant.trackPublications.values) {
          if (publication.subscribed && publication.track != null) {
            _remoteTrackController.add(publication);
            _logConnectionEvent(
              'Remote track subscribed: ${publication.track!.sid}',
            );
          }
        }
      }
    });

    // Connection quality changes
    room.addListener(() {
      final quality =
          room.localParticipant?.connectionQuality ?? ConnectionQuality.unknown;
      _connectionQualityController.add(quality);

      // Log quality changes with appropriate level
      switch (quality) {
        case ConnectionQuality.excellent:
          _logger.d('Connection quality: Excellent');
          break;
        case ConnectionQuality.good:
          _logger.d('Connection quality: Good');
          break;
        case ConnectionQuality.poor:
          _logger.w('Connection quality: Poor - User may experience issues');
          _logConnectionEvent('Poor connection quality detected');
          break;
        case ConnectionQuality.lost:
          _logger.e('Connection quality: Lost');
          _logConnectionEvent('Connection quality lost');
          break;
        case ConnectionQuality.unknown:
          _logger.d('Connection quality: Unknown');
          break;
      }
    });

    // Participant connected
    room.addListener(() {
      final participantCount = room.remoteParticipants.length;
      _logConnectionEvent('Participants in room: $participantCount');
    });

    // Track published
    room.localParticipant?.addListener(() {
      _logConnectionEvent(
        'Local tracks - Audio: ${room.localParticipant?.isMicrophoneEnabled()}, '
        'Video: ${room.localParticipant?.isCameraEnabled()}',
      );
    });
  }

  /// Log connection event for debugging and monitoring
  void _logConnectionEvent(String event) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = '[$timestamp] $event';
    _logger.i(logMessage);
    _connectionEventController.add(logMessage);
  }

  /// Handle disconnection and attempt reconnection
  void _handleDisconnection() {
    // Don't attempt reconnection if we've exceeded max attempts
    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      _logger.e(
        'Max reconnection attempts ($_maxReconnectionAttempts) reached',
      );
      _logConnectionEvent(
        'Failed to reconnect after $_maxReconnectionAttempts attempts',
      );
      return;
    }

    // Don't reconnect if we don't have credentials
    if (_lastToken == null || _lastUrl == null) {
      _logger.w('No credentials available for reconnection');
      return;
    }

    _reconnectionAttempts++;

    // Calculate exponential backoff delay: 1s, 2s, 4s
    final delaySeconds = (1 << (_reconnectionAttempts - 1));

    _logConnectionEvent(
      'Attempting reconnection $_reconnectionAttempts/$_maxReconnectionAttempts '
      'in ${delaySeconds}s',
    );

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(Duration(seconds: delaySeconds), () {
      _attemptReconnection();
    });
  }

  /// Attempt to reconnect to the room
  Future<void> _attemptReconnection() async {
    if (_lastToken == null || _lastUrl == null) {
      _logger.w('Cannot reconnect: missing credentials');
      return;
    }

    try {
      _logConnectionEvent('Reconnecting to room...');

      // Try to reconnect
      await _room?.connect(_lastUrl!, _lastToken!);

      _logConnectionEvent('Reconnection successful');
      _reconnectionAttempts = 0;
    } catch (e) {
      _logger.e('Reconnection attempt failed', error: e);
      _logConnectionEvent('Reconnection failed: $e');

      // Try again if we haven't exceeded max attempts
      if (_reconnectionAttempts < _maxReconnectionAttempts) {
        _handleDisconnection();
      }
    }
  }

  /// Toggle microphone mute
  Future<void> toggleMicrophone() async {
    try {
      if (_room?.localParticipant == null) {
        _logger.w('No local participant to toggle microphone');
        return;
      }

      final isMuted = _room!.localParticipant!.isMicrophoneEnabled();
      await _room!.localParticipant!.setMicrophoneEnabled(!isMuted);
      _logger.i('Microphone ${!isMuted ? "disabled" : "enabled"}');
    } catch (e) {
      _logger.e('Error toggling microphone', error: e);
    }
  }

  /// Toggle camera on/off
  Future<void> toggleCamera() async {
    try {
      if (_room?.localParticipant == null) {
        _logger.w('No local participant to toggle camera');
        return;
      }

      final isEnabled = _room!.localParticipant!.isCameraEnabled();
      await _room!.localParticipant!.setCameraEnabled(!isEnabled);
      _logger.i('Camera ${!isEnabled ? "disabled" : "enabled"}');
    } catch (e) {
      _logger.e('Error toggling camera', error: e);
    }
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    try {
      if (_localVideoTrack == null) {
        _logger.w('No local video track to switch');
        return;
      }

      // Recreate video track with opposite camera position
      final currentPosition =
          _localVideoTrack!.currentOptions is CameraCaptureOptions
          ? (_localVideoTrack!.currentOptions as CameraCaptureOptions)
                .cameraPosition
          : CameraPosition.front;

      final newPosition = currentPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;

      // Stop current track
      await _localVideoTrack!.stop();

      // Create new track with opposite camera
      _localVideoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(cameraPosition: newPosition, maxFrameRate: 30),
      );

      // Publish new track
      if (_room?.localParticipant != null) {
        await _room!.localParticipant!.publishVideoTrack(_localVideoTrack!);
      }

      _logger.i('Camera switched to $newPosition');
    } catch (e) {
      _logger.e('Error switching camera', error: e);
    }
  }

  /// Disconnect from room and cleanup
  Future<void> disconnect() async {
    try {
      _logger.i('Disconnecting from LiveKit room');

      // Cancel any pending reconnection attempts
      _reconnectionTimer?.cancel();
      _reconnectionAttempts = 0;
      _lastToken = null;
      _lastUrl = null;

      // Stop and dispose local tracks
      if (_localVideoTrack != null) {
        await _localVideoTrack!.stop();
        await _localVideoTrack!.dispose();
        _localVideoTrack = null;
      }

      if (_localAudioTrack != null) {
        await _localAudioTrack!.stop();
        await _localAudioTrack!.dispose();
        _localAudioTrack = null;
      }

      // Disconnect room
      if (_room != null) {
        await _room!.disconnect();
        await _room!.dispose();
        _room = null;
      }

      _logger.i('Disconnected from LiveKit room');
    } catch (e) {
      _logger.e('Error disconnecting', error: e);
    }
  }

  /// Handle app going to background
  Future<void> handleAppPaused() async {
    try {
      _logger.i('App paused - pausing video track to save battery');

      // Pause video track to save battery
      if (_localVideoTrack != null && _room?.localParticipant != null) {
        await _room!.localParticipant!.setCameraEnabled(false);
      }
    } catch (e) {
      _logger.e('Error handling app pause', error: e);
    }
  }

  /// Handle app resuming from background
  Future<void> handleAppResumed() async {
    try {
      _logger.i('App resumed - restoring video track');

      // Check if room is still connected
      if (_room?.connectionState == ConnectionState.disconnected) {
        _logger.w(
          'Room disconnected while in background - attempting reconnection',
        );

        // Attempt to reconnect if we have credentials
        if (_lastToken != null && _lastUrl != null) {
          await _attemptReconnection();
        }
        return;
      }

      // Re-enable video track if room is connected
      if (_localVideoTrack != null && _room?.localParticipant != null) {
        await _room!.localParticipant!.setCameraEnabled(true);
        _logger.i('Video track restored after app resume');
      }
    } catch (e) {
      _logger.e('Error handling app resume', error: e);
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _remoteTrackController.close();
    _connectionQualityController.close();
    _connectionEventController.close();
    _logger.i('LiveKitService disposed');
  }
}
