import 'dart:async';
import 'package:camera/camera.dart';
import 'face_tracking_service.dart';
import '../utils/logger.dart';

/// Service to capture camera frames and track face for avatar
class CameraFaceTracker {
  final _logger = AppLogger();
  final FaceTrackingService _faceTrackingService;

  CameraController? _cameraController;
  bool _isInitialized = false;
  bool _isProcessing = false;

  CameraFaceTracker(this._faceTrackingService);

  /// Initialize camera for face tracking (separate from video call camera)
  Future<void> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _logger.warning('No cameras available for face tracking');
        return;
      }

      // Use front camera for face tracking
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Low resolution for face tracking
        enableAudio: false,
      );

      await _cameraController!.initialize();
      _isInitialized = true;

      // Start image stream for face detection
      await _cameraController!.startImageStream(_processCameraImage);

      _logger.info('Camera face tracker initialized');
    } catch (e) {
      _logger.error('Failed to initialize camera face tracker', error: e);
    }
  }

  /// Process camera image for face detection
  void _processCameraImage(CameraImage image) {
    if (_isProcessing) return;
    _isProcessing = true;

    // Process in background to avoid blocking UI
    _faceTrackingService
        .processFrame(image)
        .then((_) {
          _isProcessing = false;
        })
        .catchError((error) {
          _logger.error('Face processing error', error: error);
          _isProcessing = false;
        });
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    if (_cameraController != null) {
      await _cameraController!.stopImageStream();
      await _cameraController!.dispose();
      _cameraController = null;
    }
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
}
