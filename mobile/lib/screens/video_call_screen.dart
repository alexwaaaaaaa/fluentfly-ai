import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/video_call_provider.dart';
import '../services/api_service.dart';
import '../services/livekit_service.dart';
import '../config/theme.dart';
import '../utils/logger.dart';
import '../widgets/rive_avatar_widget.dart';
import 'call_summary_screen.dart';

/// Video call screen for AI tutor conversations
class VideoCallScreen extends ConsumerStatefulWidget {
  final int lessonId;
  final String topic;

  const VideoCallScreen({
    super.key,
    required this.lessonId,
    required this.topic,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen>
    with WidgetsBindingObserver {
  final AppLogger _logger = AppLogger();
  bool _isInitializing = true;
  String? _errorMessage;
  bool _isInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCall();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _logger.info('App lifecycle state changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.paused:
        _handleAppPaused();
        break;
      case AppLifecycleState.inactive:
        // App is transitioning, do nothing
        break;
      case AppLifecycleState.detached:
        // App is being terminated
        break;
      case AppLifecycleState.hidden:
        // App is hidden (iOS specific)
        break;
    }
  }

  Future<void> _handleAppResumed() async {
    if (!_isInBackground) return;

    _logger.info(
      'App resumed from background - attempting to restore video call',
    );
    _isInBackground = false;

    try {
      // Re-enable camera if it was on before
      final videoCallState = ref.read(videoCallProvider(widget.lessonId));
      if (videoCallState.isCameraOn) {
        await ref
            .read(videoCallProvider(widget.lessonId).notifier)
            .toggleCamera(); // Turn off
        await Future.delayed(const Duration(milliseconds: 500));
        await ref
            .read(videoCallProvider(widget.lessonId).notifier)
            .toggleCamera(); // Turn back on
        _logger.info('Camera restored after app resume');
      }

      // Check connection state
      if (videoCallState.connectionState ==
          VideoCallConnectionState.disconnected) {
        _logger.warning('Connection lost while in background');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Connection lost. Please rejoin the call.'),
              backgroundColor: AppTheme.errorColor,
              action: SnackBarAction(
                label: 'Rejoin',
                textColor: Colors.white,
                onPressed: () => _initializeCall(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      _logger.error('Failed to restore video call after resume', error: e);
    }
  }

  void _handleAppPaused() {
    _logger.info('App paused - going to background');
    _isInBackground = true;

    // Optionally pause camera to save battery
    // Note: LiveKit will automatically handle this, but we track the state
  }

  Future<void> _initializeCall() async {
    try {
      setState(() {
        _isInitializing = true;
        _errorMessage = null;
      });

      // Check permissions first
      final liveKitService = ref.read(liveKitServiceProvider);
      final permissionStatus = await liveKitService.checkPermissions();

      if (permissionStatus != PermissionResult.granted) {
        // Show permission dialog
        final shouldRequest = await _showPermissionDialog(permissionStatus);
        if (!shouldRequest) {
          setState(() {
            _isInitializing = false;
            _errorMessage = 'Permissions are required for video calls';
          });
          return;
        }

        // Request permissions
        final result = await liveKitService.requestPermissions();
        if (result != PermissionResult.granted) {
          setState(() {
            _isInitializing = false;
            _errorMessage = PermissionException(result).toString();
          });

          // If permanently denied, show settings dialog
          if (result == PermissionResult.permanentlyDenied && mounted) {
            _showSettingsDialog();
          }
          return;
        }
      }

      // Get token from backend
      final apiService = ApiService();
      final response = await apiService.get(
        '/rtc/token?lessonId=${widget.lessonId}',
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      var url = data['url'] as String;
      final roomName = data['roomName'] as String;
      final sessionId = data['sessionId'] as int;

      // Replace localhost with laptop IP for physical device (or 10.0.2.2 for emulator)
      url = url.replaceAll('localhost', '192.168.31.73');

      _logger.info(
        'Got RTC token, session: $sessionId, room: $roomName, url: $url',
      );

      // Connect to video call
      await ref
          .read(videoCallProvider(widget.lessonId).notifier)
          .connect(token, url, roomName, sessionId);

      // Spawn AI agent
      await apiService.post(
        '/rtc/agent',
        data: {
          'roomName': roomName,
          'lessonId': widget.lessonId,
          'topic': widget.topic,
        },
      );

      _logger.info('AI agent spawned for room: $roomName');

      setState(() {
        _isInitializing = false;
      });
    } on PermissionException catch (e) {
      _logger.error('Permission error', error: e);
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });

      // Show settings dialog if permanently denied
      if (e.result == PermissionResult.permanentlyDenied && mounted) {
        _showSettingsDialog();
      }
    } catch (e) {
      _logger.error('Failed to initialize call', error: e);
      setState(() {
        _isInitializing = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Disconnect when leaving screen
    ref.read(videoCallProvider(widget.lessonId).notifier).disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoCallState = ref.watch(videoCallProvider(widget.lessonId));

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? _buildLoadingView()
            : _errorMessage != null
            ? _buildErrorView()
            : _buildCallView(videoCallState),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 24),
          Text(
            'Connecting to AI Tutor...',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppTheme.errorColor,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Connection Failed',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unable to connect to video call',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallView(VideoCallState state) {
    return Stack(
      children: [
        // AI avatar (full screen background)
        _buildAIAvatarFullScreen(state),

        // Header with topic and duration
        _buildHeader(state),

        // User video (small, picture-in-picture)
        _buildUserVideoOverlay(state),

        // Captions
        _buildCaptions(state),

        // Call controls
        _buildCallControls(state),

        // Connection quality indicator
        if (state.showQualityWarning) _buildConnectionWarning(state),

        // Reconnecting indicator
        if (state.connectionState == VideoCallConnectionState.reconnecting)
          _buildReconnectingIndicator(),
      ],
    );
  }

  Widget _buildAIAvatarFullScreen(VideoCallState state) {
    // Check if AI is speaking
    final isAISpeaking =
        state.conversationTurns.isNotEmpty &&
        state.conversationTurns.last.speaker == 'ai' &&
        DateTime.now()
                .difference(state.conversationTurns.last.timestamp)
                .inSeconds <
            5;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A0E12),
            const Color(0xFF1A1F2E),
            const Color(0xFF0A0E12),
          ],
        ),
      ),
      child: Center(
        child: RiveAvatarWidget(
          isSpeaking: isAISpeaking,
          isListening: !isAISpeaking && state.conversationTurns.isNotEmpty,
          size: MediaQuery.of(context).size.width * 0.8, // 80% of screen width
        ),
      ),
    );
  }

  Widget _buildUserVideoOverlay(VideoCallState state) {
    final liveKitService = ref.read(liveKitServiceProvider);
    final localVideoTrack = liveKitService.localVideoTrack;

    return Positioned(
      top: 100,
      right: 16,
      child: GestureDetector(
        onTap: () {
          // Optional: tap to expand user video
        },
        child: Container(
          width: 120,
          height: 160,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: localVideoTrack == null
                ? const Center(
                    child: Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 32,
                    ),
                  )
                : VideoTrackRenderer(
                    localVideoTrack,
                    fit: VideoViewFit.cover,
                    mirrorMode: VideoViewMirrorMode.mirror,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(VideoCallState state) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => _handleEndCall(),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.topic,
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatDuration(state.callDuration),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                // Camera switch button
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                  onPressed: () => _handleSwitchCamera(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptions(VideoCallState state) {
    // Show the last conversation turn as caption
    if (state.conversationTurns.isEmpty) {
      return const SizedBox.shrink();
    }

    final lastTurn = state.conversationTurns.last;
    final timeSinceLastTurn = DateTime.now().difference(lastTurn.timestamp);

    // Auto-hide captions after 5 seconds
    if (timeSinceLastTurn.inSeconds > 5) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 140, // Above call controls
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: timeSinceLastTurn.inSeconds > 4 ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 500),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: lastTurn.speaker == 'ai'
                  ? AppTheme.primaryColor
                  : AppTheme.accentColor,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    lastTurn.speaker == 'ai' ? Icons.smart_toy : Icons.person,
                    color: lastTurn.speaker == 'ai'
                        ? AppTheme.primaryColor
                        : AppTheme.accentColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lastTurn.speaker == 'ai' ? 'AI Tutor' : 'You',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: lastTurn.speaker == 'ai'
                          ? AppTheme.primaryColor
                          : AppTheme.accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                lastTurn.text,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallControls(VideoCallState state) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Mute button
            _buildControlButton(
              icon: state.isMuted ? Icons.mic_off : Icons.mic,
              label: state.isMuted ? 'Unmute' : 'Mute',
              onPressed: () => _handleToggleMicrophone(),
              backgroundColor: state.isMuted
                  ? AppTheme.errorColor
                  : AppTheme.surfaceColor,
            ),

            // Camera button
            _buildControlButton(
              icon: state.isCameraOn ? Icons.videocam : Icons.videocam_off,
              label: state.isCameraOn ? 'Camera Off' : 'Camera On',
              onPressed: () => _handleToggleCamera(),
              backgroundColor: !state.isCameraOn
                  ? AppTheme.errorColor
                  : AppTheme.surfaceColor,
            ),

            // End call button
            _buildControlButton(
              icon: Icons.call_end,
              label: 'End Call',
              onPressed: () => _handleEndCall(),
              backgroundColor: AppTheme.errorColor,
              isLarge: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    bool isLarge = false,
  }) {
    final size = isLarge ? 72.0 : 56.0;
    final iconSize = isLarge ? 32.0 : 24.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          elevation: 4,
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildConnectionWarning(VideoCallState state) {
    final warningText = state.connectionQuality == ConnectionQuality.lost
        ? 'Connection lost - Attempting to reconnect'
        : 'Poor connection quality';

    final warningColor = state.connectionQuality == ConnectionQuality.lost
        ? AppTheme.errorColor
        : AppTheme.warningColor;

    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: AnimatedOpacity(
        opacity: state.showQualityWarning ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: warningColor.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                state.connectionQuality == ConnectionQuality.lost
                    ? Icons.signal_wifi_off
                    : Icons.warning,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warningText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReconnectingIndicator() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Reconnecting...',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we restore your connection',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _handleSwitchCamera() async {
    try {
      await ref
          .read(videoCallProvider(widget.lessonId).notifier)
          .switchCamera();
    } catch (e) {
      _logger.error('Failed to switch camera', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to switch camera')),
        );
      }
    }
  }

  Future<void> _handleToggleMicrophone() async {
    try {
      await ref
          .read(videoCallProvider(widget.lessonId).notifier)
          .toggleMicrophone();
    } catch (e) {
      _logger.error('Failed to toggle microphone', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle microphone')),
        );
      }
    }
  }

  Future<void> _handleToggleCamera() async {
    try {
      await ref
          .read(videoCallProvider(widget.lessonId).notifier)
          .toggleCamera();
    } catch (e) {
      _logger.error('Failed to toggle camera', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to toggle camera')),
        );
      }
    }
  }

  Future<void> _handleEndCall() async {
    final shouldEnd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Call?'),
        content: const Text('Are you sure you want to end this call?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('End Call'),
          ),
        ],
      ),
    );

    if (shouldEnd == true && mounted) {
      try {
        final videoCallState = ref.read(videoCallProvider(widget.lessonId));
        final sessionId = videoCallState.sessionId;
        final roomName = videoCallState.roomName;

        if (sessionId != null && roomName != null) {
          // End session on backend
          final apiService = ApiService();
          final response = await apiService.post(
            '/rtc/session/end',
            data: {'sessionId': sessionId, 'roomName': roomName},
          );

          _logger.info('Session ended: $sessionId');

          // Disconnect from call
          await ref
              .read(videoCallProvider(widget.lessonId).notifier)
              .disconnect();

          // Navigate to summary screen
          if (mounted) {
            final responseData = response.data as Map<String, dynamic>;
            final analytics = responseData['analytics'] as Map<String, dynamic>;
            final summaryData = CallSummaryData(
              sessionId: sessionId,
              duration: Duration(seconds: responseData['duration'] as int),
              totalSpeakingTime: analytics['totalSpeakingTime'] as int,
              wordsPerMinute: analytics['wordsPerMinute'] as int,
              pauseCount: analytics['pauseCount'] as int,
              averagePauseLength: (analytics['averagePauseLength'] as num)
                  .toDouble(),
              fluencyScore: analytics['fluencyScore'] as int,
              turnCount: analytics['turnCount'] as int,
              conversationTurns: videoCallState.conversationTurns
                  .map(
                    (turn) => ConversationTurnData(
                      speaker: turn.speaker,
                      text: turn.text,
                      timestamp: turn.timestamp,
                    ),
                  )
                  .toList(),
            );

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => CallSummaryScreen(
                  summaryData: summaryData,
                  lessonId: widget.lessonId,
                  topic: widget.topic,
                  markAsComplete: true,
                ),
              ),
            );
          }
        } else {
          // No session to end, just disconnect
          await ref
              .read(videoCallProvider(widget.lessonId).notifier)
              .disconnect();
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        _logger.error('Failed to end call properly', error: e);
        // Still disconnect and go back
        await ref
            .read(videoCallProvider(widget.lessonId).notifier)
            .disconnect();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<bool> _showPermissionDialog(PermissionResult status) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.videocam, color: AppTheme.primaryColor),
            SizedBox(width: 8),
            Text('Camera & Microphone Access'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To have a video call with your AI tutor, we need access to:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.videocam, size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Expanded(child: Text('Camera - to show your video')),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.mic, size: 20, color: AppTheme.primaryColor),
                SizedBox(width: 8),
                Expanded(child: Text('Microphone - to hear you speak')),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your privacy is important. Video calls are not recorded.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow Access'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _showSettingsDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permissions Required'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Camera and microphone permissions have been permanently denied.',
            ),
            SizedBox(height: 16),
            Text(
              'To use video calls, please enable these permissions in your device settings:',
            ),
            SizedBox(height: 12),
            Text(
              '1. Open Settings\n2. Find FluentFly\n3. Enable Camera and Microphone',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
