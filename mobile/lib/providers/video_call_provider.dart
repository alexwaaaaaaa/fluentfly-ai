import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/livekit_service.dart';

/// Enum for video call connection state
enum VideoCallConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  failed,
}

/// Extension to check if reconnecting
extension VideoCallConnectionStateExtension on VideoCallConnectionState {
  bool get isReconnecting => this == VideoCallConnectionState.reconnecting;
}

/// Model for conversation turn
class ConversationTurn {
  final String speaker; // 'user' or 'ai'
  final String text;
  final DateTime timestamp;

  ConversationTurn({
    required this.speaker,
    required this.text,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'speaker': speaker,
    'text': text,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Video call state model
class VideoCallState {
  final VideoCallConnectionState connectionState;
  final bool isMuted;
  final bool isCameraOn;
  final Duration callDuration;
  final List<ConversationTurn> conversationTurns;
  final ConnectionQuality connectionQuality;
  final String? errorMessage;
  final int lessonId;
  final String? roomName;
  final int? sessionId;
  final List<String> connectionEvents;
  final bool showQualityWarning;

  VideoCallState({
    required this.connectionState,
    required this.isMuted,
    required this.isCameraOn,
    required this.callDuration,
    required this.conversationTurns,
    required this.connectionQuality,
    this.errorMessage,
    required this.lessonId,
    this.roomName,
    this.sessionId,
    this.connectionEvents = const [],
    this.showQualityWarning = false,
  });

  VideoCallState copyWith({
    VideoCallConnectionState? connectionState,
    bool? isMuted,
    bool? isCameraOn,
    Duration? callDuration,
    List<ConversationTurn>? conversationTurns,
    ConnectionQuality? connectionQuality,
    String? errorMessage,
    int? lessonId,
    String? roomName,
    int? sessionId,
    List<String>? connectionEvents,
    bool? showQualityWarning,
  }) {
    return VideoCallState(
      connectionState: connectionState ?? this.connectionState,
      isMuted: isMuted ?? this.isMuted,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      callDuration: callDuration ?? this.callDuration,
      conversationTurns: conversationTurns ?? this.conversationTurns,
      connectionQuality: connectionQuality ?? this.connectionQuality,
      errorMessage: errorMessage,
      lessonId: lessonId ?? this.lessonId,
      roomName: roomName ?? this.roomName,
      sessionId: sessionId ?? this.sessionId,
      connectionEvents: connectionEvents ?? this.connectionEvents,
      showQualityWarning: showQualityWarning ?? this.showQualityWarning,
    );
  }

  factory VideoCallState.initial(int lessonId) {
    return VideoCallState(
      connectionState: VideoCallConnectionState.disconnected,
      isMuted: false,
      isCameraOn: true,
      callDuration: Duration.zero,
      conversationTurns: [],
      connectionQuality: ConnectionQuality.unknown,
      lessonId: lessonId,
    );
  }

  int get turnCount => conversationTurns.length;

  Duration get userSpeakingTime {
    // Calculate total time user was speaking
    // For now, estimate based on turn count (can be improved with actual timing)
    final userTurns = conversationTurns
        .where((t) => t.speaker == 'user')
        .length;
    return Duration(seconds: userTurns * 5); // Rough estimate
  }

  Duration get aiSpeakingTime {
    final aiTurns = conversationTurns.where((t) => t.speaker == 'ai').length;
    return Duration(seconds: aiTurns * 5); // Rough estimate
  }
}

/// Video call state notifier
class VideoCallNotifier extends StateNotifier<VideoCallState> {
  final LiveKitService _liveKitService;
  Timer? _durationTimer;
  StreamSubscription<ConnectionState>? _connectionStateSubscription;
  StreamSubscription<ConnectionQuality>? _connectionQualitySubscription;
  StreamSubscription<String>? _connectionEventSubscription;

  VideoCallNotifier(this._liveKitService, int lessonId)
    : super(VideoCallState.initial(lessonId));

  /// Connect to video call room
  Future<void> connect(
    String token,
    String url,
    String roomName,
    int sessionId,
  ) async {
    try {
      state = state.copyWith(
        connectionState: VideoCallConnectionState.connecting,
        roomName: roomName,
        sessionId: sessionId,
      );

      // Connect to room
      await _liveKitService.connectToRoom(token, url);

      // Publish tracks
      await _liveKitService.publishTracks();

      // Subscribe to remote tracks
      _liveKitService.subscribeToRemoteTracks();

      // Set up listeners
      _setupListeners();

      // Start duration timer
      _startDurationTimer();

      state = state.copyWith(
        connectionState: VideoCallConnectionState.connected,
      );
    } catch (e) {
      state = state.copyWith(
        connectionState: VideoCallConnectionState.failed,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Set up event listeners
  void _setupListeners() {
    // Listen to connection state changes
    _connectionStateSubscription = _liveKitService.connectionStateStream.listen(
      (connectionState) {
        if (connectionState == ConnectionState.connected) {
          state = state.copyWith(
            connectionState: VideoCallConnectionState.connected,
            errorMessage: null,
          );
        } else if (connectionState == ConnectionState.disconnected) {
          state = state.copyWith(
            connectionState: VideoCallConnectionState.disconnected,
          );
        } else if (connectionState == ConnectionState.reconnecting) {
          state = state.copyWith(
            connectionState: VideoCallConnectionState.reconnecting,
          );
        }
      },
    );

    // Listen to connection quality changes
    _connectionQualitySubscription = _liveKitService.connectionQualityStream
        .listen((quality) {
          // Show warning for poor or lost connection
          final showWarning =
              quality == ConnectionQuality.poor ||
              quality == ConnectionQuality.lost;

          state = state.copyWith(
            connectionQuality: quality,
            showQualityWarning: showWarning,
          );
        });

    // Listen to connection events for debugging (with memory optimization)
    _connectionEventSubscription = _liveKitService.connectionEventStream.listen((
      event,
    ) {
      final updatedEvents = List<String>.from(state.connectionEvents)
        ..add(event);

      // Memory optimization: Keep only last 30 events to minimize memory usage
      if (updatedEvents.length > 30) {
        updatedEvents.removeRange(0, updatedEvents.length - 30);
      }

      state = state.copyWith(connectionEvents: updatedEvents);
    });
  }

  /// Start call duration timer
  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Check if provider is still mounted before updating state
      if (!mounted) {
        timer.cancel();
        return;
      }

      state = state.copyWith(
        callDuration: Duration(seconds: state.callDuration.inSeconds + 1),
      );

      // Auto-end call after 30 minutes
      if (state.callDuration.inMinutes >= 30) {
        disconnect();
      }
    });
  }

  /// Toggle microphone mute
  Future<void> toggleMicrophone() async {
    await _liveKitService.toggleMicrophone();
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Toggle camera on/off
  Future<void> toggleCamera() async {
    await _liveKitService.toggleCamera();
    state = state.copyWith(isCameraOn: !state.isCameraOn);
  }

  /// Switch camera (front/back)
  Future<void> switchCamera() async {
    await _liveKitService.switchCamera();
  }

  /// Add conversation turn with memory optimization
  void addConversationTurn(String speaker, String text) {
    final turn = ConversationTurn(
      speaker: speaker,
      text: text,
      timestamp: DateTime.now(),
    );

    final updatedTurns = List<ConversationTurn>.from(state.conversationTurns)
      ..add(turn);

    // Memory optimization: Keep only last 50 turns to prevent memory issues
    if (updatedTurns.length > 50) {
      updatedTurns.removeRange(0, updatedTurns.length - 50);
    }

    state = state.copyWith(conversationTurns: updatedTurns);
  }

  /// Disconnect from call
  Future<void> disconnect() async {
    _durationTimer?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionQualitySubscription?.cancel();
    _connectionEventSubscription?.cancel();

    await _liveKitService.disconnect();

    state = state.copyWith(
      connectionState: VideoCallConnectionState.disconnected,
    );
  }

  /// Handle app going to background
  Future<void> handleAppPaused() async {
    await _liveKitService.handleAppPaused();
  }

  /// Handle app resuming from background
  Future<void> handleAppResumed() async {
    await _liveKitService.handleAppResumed();

    // Update state based on current connection
    if (_liveKitService.isConnected) {
      state = state.copyWith(
        connectionState: VideoCallConnectionState.connected,
        isCameraOn:
            _liveKitService.room?.localParticipant?.isCameraEnabled() ?? false,
        isMuted:
            !(_liveKitService.room?.localParticipant?.isMicrophoneEnabled() ??
                true),
      );
    } else {
      state = state.copyWith(
        connectionState: VideoCallConnectionState.disconnected,
      );
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _connectionStateSubscription?.cancel();
    _connectionQualitySubscription?.cancel();
    _connectionEventSubscription?.cancel();
    _liveKitService.dispose();
    super.dispose();
  }
}

/// Provider for LiveKit service
final liveKitServiceProvider = Provider<LiveKitService>((ref) {
  final service = LiveKitService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for video call state
final videoCallProvider =
    StateNotifierProvider.family<VideoCallNotifier, VideoCallState, int>((
      ref,
      lessonId,
    ) {
      final liveKitService = ref.watch(liveKitServiceProvider);
      return VideoCallNotifier(liveKitService, lessonId);
    });
