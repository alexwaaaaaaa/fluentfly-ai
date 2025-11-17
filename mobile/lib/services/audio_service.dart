import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final Logger _logger = Logger();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _currentRecordingPath;

  // Stream controllers for waveform visualization
  final StreamController<RecordState> _recordingStateController =
      StreamController<RecordState>.broadcast();

  Stream<RecordState> get recordingStateStream =>
      _recordingStateController.stream;

  bool get isRecording => _isRecording;
  bool get isPlaying => _isPlaying;

  AudioService() {
    _initializeAudioPlayer();
  }

  void _initializeAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
    });
  }

  /// Request microphone permission
  Future<bool> requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      if (status.isGranted) {
        _logger.i('Microphone permission granted');
        return true;
      } else if (status.isDenied) {
        _logger.w('Microphone permission denied');
        return false;
      } else if (status.isPermanentlyDenied) {
        _logger.e('Microphone permission permanently denied');
        // Open app settings
        await openAppSettings();
        return false;
      }
      return false;
    } catch (e) {
      _logger.e('Error requesting microphone permission', error: e);
      return false;
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Start audio recording
  Future<void> startRecording() async {
    try {
      // Check permission
      final hasPermission = await hasMicrophonePermission();
      if (!hasPermission) {
        final granted = await requestMicrophonePermission();
        if (!granted) {
          throw Exception('Microphone permission not granted');
        }
      }

      // Check if already recording
      if (_isRecording) {
        _logger.w('Already recording');
        return;
      }

      // Get temporary directory for recording
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/recording_$timestamp.m4a';

      // Start recording
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingStateController.add(RecordState.record);
      _logger.i('Recording started: $_currentRecordingPath');

      // Start amplitude stream for waveform visualization
      _startAmplitudeStream();
    } catch (e) {
      _logger.e('Error starting recording', error: e);
      _isRecording = false;
      rethrow;
    }
  }

  /// Stop audio recording and return file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        _logger.w('Not currently recording');
        return null;
      }

      final path = await _audioRecorder.stop();
      _isRecording = false;
      _recordingStateController.add(RecordState.stop);
      _logger.i('Recording stopped: $path');

      return path;
    } catch (e) {
      _logger.e('Error stopping recording', error: e);
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _audioRecorder.stop();
        _isRecording = false;
        _recordingStateController.add(RecordState.stop);

        // Delete the recording file
        if (_currentRecordingPath != null) {
          final file = File(_currentRecordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        }
        _logger.i('Recording cancelled');
      }
    } catch (e) {
      _logger.e('Error cancelling recording', error: e);
    }
  }

  /// Start amplitude stream for waveform visualization
  void _startAmplitudeStream() {
    _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen(
          (amplitude) {
            // Amplitude data can be used for waveform visualization
            // The amplitude.current value ranges from -160 dB to 0 dB
            _logger.d('Amplitude: ${amplitude.current}');
          },
          onError: (error) {
            _logger.e('Amplitude stream error', error: error);
          },
        );
  }

  /// Play audio from URL
  Future<void> playAudio(String url) async {
    try {
      _logger.i('Playing audio: $url');
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      _logger.e('Error playing audio', error: e);
      rethrow;
    }
  }

  /// Play audio from local file
  Future<void> playAudioFile(String filePath) async {
    try {
      _logger.i('Playing audio file: $filePath');
      await _audioPlayer.play(DeviceFileSource(filePath));
    } catch (e) {
      _logger.e('Error playing audio file', error: e);
      rethrow;
    }
  }

  /// Stop audio playback
  Future<void> stopAudio() async {
    try {
      await _audioPlayer.stop();
      _logger.i('Audio playback stopped');
    } catch (e) {
      _logger.e('Error stopping audio', error: e);
    }
  }

  /// Pause audio playback
  Future<void> pauseAudio() async {
    try {
      await _audioPlayer.pause();
      _logger.i('Audio playback paused');
    } catch (e) {
      _logger.e('Error pausing audio', error: e);
    }
  }

  /// Resume audio playback
  Future<void> resumeAudio() async {
    try {
      await _audioPlayer.resume();
      _logger.i('Audio playback resumed');
    } catch (e) {
      _logger.e('Error resuming audio', error: e);
    }
  }

  /// Get current playback position
  Future<Duration?> getCurrentPosition() async {
    try {
      return await _audioPlayer.getCurrentPosition();
    } catch (e) {
      _logger.e('Error getting current position', error: e);
      return null;
    }
  }

  /// Get audio duration
  Future<Duration?> getDuration() async {
    try {
      return await _audioPlayer.getDuration();
    } catch (e) {
      _logger.e('Error getting duration', error: e);
      return null;
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      _logger.i('Seeked to: $position');
    } catch (e) {
      _logger.e('Error seeking', error: e);
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _logger.e('Error setting volume', error: e);
    }
  }

  /// Listen to player state changes
  Stream<PlayerState> get playerStateStream =>
      _audioPlayer.onPlayerStateChanged;

  /// Listen to position changes
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  /// Listen to duration changes
  Stream<Duration> get durationStream => _audioPlayer.onDurationChanged;

  /// Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    _recordingStateController.close();
    _logger.i('AudioService disposed');
  }
}
