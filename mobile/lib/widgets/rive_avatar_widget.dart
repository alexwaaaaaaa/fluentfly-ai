import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rive/rive.dart' hide LinearGradient;
import '../utils/logger.dart';
import '../services/face_tracking_service.dart';

/// Interactive Rive avatar widget for video calls
/// Shows animated girl face that responds to AI speech and tracks user's face
class RiveAvatarWidget extends StatefulWidget {
  final bool isSpeaking;
  final bool isListening;
  final double size;
  final FaceTrackingService? faceTrackingService;

  const RiveAvatarWidget({
    super.key,
    this.isSpeaking = false,
    this.isListening = false,
    this.size = 200,
    this.faceTrackingService,
  });

  @override
  State<RiveAvatarWidget> createState() => _RiveAvatarWidgetState();
}

class _RiveAvatarWidgetState extends State<RiveAvatarWidget> {
  final _logger = AppLogger();

  // Rive animation controller
  Artboard? _riveArtboard;
  StateMachineController? _controller;

  // State machine inputs
  SMIBool? _isSpeakingInput;
  SMIBool? _isListeningInput;
  SMITrigger? _blinkTrigger;
  SMINumber? _eyeXInput;
  SMINumber? _eyeYInput;
  SMINumber? _mouthOpenInput;

  StreamSubscription<FacePosition>? _facePositionSubscription;
  Timer? _lipSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadRiveFile();
    _setupFaceTracking();
  }

  /// Load the Rive file and set up state machine
  Future<void> _loadRiveFile() async {
    try {
      final data = await rootBundle.load(
        'assets/girl-character-eye-mouse-tracking.riv',
      );
      final file = RiveFile.import(data);

      final artboard = file.mainArtboard;

      // Try to find and attach state machine
      // Common state machine names: 'State Machine 1', 'Main', 'Controller'
      var controller = StateMachineController.fromArtboard(
        artboard,
        'State Machine 1', // Change this if your state machine has a different name
      );

      if (controller != null) {
        artboard.addController(controller);
        _controller = controller;

        // Try to find inputs (adjust names based on your Rive file)
        _isSpeakingInput = controller.findInput<bool>('isSpeaking') as SMIBool?;
        _isListeningInput =
            controller.findInput<bool>('isListening') as SMIBool?;
        _blinkTrigger = controller.findInput<bool>('blink') as SMITrigger?;

        // Eye tracking inputs (if available in Rive file)
        _eyeXInput = controller.findInput<double>('eyeX') as SMINumber?;
        _eyeYInput = controller.findInput<double>('eyeY') as SMINumber?;

        // Lip sync input (if available in Rive file)
        _mouthOpenInput =
            controller.findInput<double>('mouthOpen') as SMINumber?;

        _logger.info('Rive avatar loaded successfully');
        _logger.info(
          'Available inputs: ${controller.inputs.map((i) => i.name).join(", ")}',
        );
        _logger.info(
          'Eye tracking available: ${_eyeXInput != null && _eyeYInput != null}',
        );
        _logger.info('Lip sync available: ${_mouthOpenInput != null}');
      } else {
        _logger.warning('State machine not found, using default animation');
      }

      if (mounted) {
        setState(() {
          _riveArtboard = artboard;
        });
      }

      // Start periodic blinking
      _startBlinking();
    } catch (e) {
      _logger.error('Failed to load Rive file', error: e);
    }
  }

  /// Start periodic blinking animation
  void _startBlinking() {
    if (_blinkTrigger == null) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _blinkTrigger != null) {
        _blinkTrigger!.fire();
        _startBlinking(); // Schedule next blink
      }
    });
  }

  /// Setup face tracking subscription
  void _setupFaceTracking() {
    if (widget.faceTrackingService != null) {
      _facePositionSubscription = widget.faceTrackingService!.facePositionStream
          .listen(_updateEyePosition);
    }
  }

  /// Update avatar eye position based on user's face
  void _updateEyePosition(FacePosition position) {
    if (_eyeXInput != null && _eyeYInput != null) {
      // Invert X for natural eye contact (user moves left, avatar looks right)
      _eyeXInput!.value = -position.x;
      _eyeYInput!.value = position.y;
    }
  }

  /// Setup lip sync animation
  void _setupLipSync() {
    if (widget.isSpeaking && _mouthOpenInput != null) {
      // Simulate lip movement during speech
      _lipSyncTimer?.cancel();
      _lipSyncTimer = Timer.periodic(const Duration(milliseconds: 100), (
        timer,
      ) {
        if (!widget.isSpeaking) {
          timer.cancel();
          _mouthOpenInput!.value = 0.0;
          return;
        }

        // Random mouth movement for natural speech
        final mouthValue =
            (DateTime.now().millisecondsSinceEpoch % 1000) / 1000.0;
        _mouthOpenInput!.value = mouthValue * 0.8; // 0 to 0.8 range
      });
    } else {
      _lipSyncTimer?.cancel();
      if (_mouthOpenInput != null) {
        _mouthOpenInput!.value = 0.0;
      }
    }
  }

  @override
  void didUpdateWidget(RiveAvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update speaking state
    if (widget.isSpeaking != oldWidget.isSpeaking) {
      _isSpeakingInput?.value = widget.isSpeaking;
      _setupLipSync(); // Start/stop lip sync
      _logger.info('Avatar speaking: ${widget.isSpeaking}');
    }

    // Update listening state
    if (widget.isListening != oldWidget.isListening) {
      _isListeningInput?.value = widget.isListening;
      _logger.info('Avatar listening: ${widget.isListening}');
    }

    // Update face tracking if service changed
    if (oldWidget.faceTrackingService != widget.faceTrackingService) {
      _facePositionSubscription?.cancel();
      _setupFaceTracking();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _lipSyncTimer?.cancel();
    _facePositionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_riveArtboard == null) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Rive(artboard: _riveArtboard!, fit: BoxFit.cover),
      ),
    );
  }
}

/// Fallback avatar if Rive file fails to load
class FallbackAvatar extends StatelessWidget {
  final bool isSpeaking;
  final double size;

  const FallbackAvatar({super.key, this.isSpeaking = false, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).colorScheme.secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.5),
            blurRadius: isSpeaking ? 30 : 20,
            spreadRadius: isSpeaking ? 10 : 5,
          ),
        ],
      ),
      child: Icon(Icons.person, size: size * 0.6, color: Colors.white),
    );
  }
}
