import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../utils/logger.dart';

/// Service for tracking user's face and eye position
class FaceTrackingService {
  final _logger = AppLogger();
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableLandmarks: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  bool _isProcessing = false;
  StreamController<FacePosition>? _facePositionController;

  Stream<FacePosition> get facePositionStream =>
      _facePositionController!.stream;

  void initialize() {
    _facePositionController = StreamController<FacePosition>.broadcast();
  }

  /// Process camera frame to detect face and eye position
  Future<void> processFrame(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final inputImage = _convertCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        final face = faces.first;
        final position = _calculateFacePosition(face);
        _facePositionController?.add(position);
      }
    } catch (e) {
      _logger.error('Face detection error', error: e);
    } finally {
      _isProcessing = false;
    }
  }

  /// Convert CameraImage to InputImage for ML Kit
  InputImage? _convertCameraImage(CameraImage image) {
    try {
      final WriteBuffer allBytes = WriteBuffer();
      for (final plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      const imageRotation = InputImageRotation.rotation0deg;

      final inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ??
          InputImageFormat.nv21;

      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    } catch (e) {
      _logger.error('Error converting camera image', error: e);
      return null;
    }
  }

  /// Calculate normalized face position (-1 to 1 for x and y)
  FacePosition _calculateFacePosition(Face face) {
    final boundingBox = face.boundingBox;

    // Normalize position to -1 to 1 range
    // Assuming camera resolution is known or can be estimated
    final centerX = boundingBox.center.dx;
    final centerY = boundingBox.center.dy;

    // Normalize (assuming 1920x1080 camera, adjust as needed)
    final normalizedX = (centerX - 960) / 960; // -1 to 1
    final normalizedY = (centerY - 540) / 540; // -1 to 1

    // Get head rotation
    final headEulerAngleY = face.headEulerAngleY ?? 0.0; // Left/right
    final headEulerAngleZ = face.headEulerAngleZ ?? 0.0; // Tilt

    return FacePosition(
      x: normalizedX.clamp(-1.0, 1.0),
      y: normalizedY.clamp(-1.0, 1.0),
      headRotationY: headEulerAngleY,
      headRotationZ: headEulerAngleZ,
    );
  }

  void dispose() {
    _faceDetector.close();
    _facePositionController?.close();
  }
}

/// Model for face position data
class FacePosition {
  final double x; // -1 (left) to 1 (right)
  final double y; // -1 (top) to 1 (bottom)
  final double headRotationY; // Head turn left/right
  final double headRotationZ; // Head tilt

  FacePosition({
    required this.x,
    required this.y,
    required this.headRotationY,
    required this.headRotationZ,
  });
}
