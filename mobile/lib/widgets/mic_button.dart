import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_provider.dart';

class MicButton extends ConsumerStatefulWidget {
  final VoidCallback? onRecordingStart;
  final Function(String?)? onRecordingStop;
  final VoidCallback? onPressed;
  final bool isRecording;
  final double size;

  const MicButton({
    super.key,
    this.onRecordingStart,
    this.onRecordingStop,
    this.onPressed,
    this.isRecording = false,
    this.size = 80,
  });

  @override
  ConsumerState<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends ConsumerState<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    // If custom onPressed is provided, use it
    if (widget.onPressed != null) {
      widget.onPressed!();
      return;
    }

    // Otherwise use default behavior
    final audioService = ref.read(audioServiceProvider);
    final isRecording = ref.read(isRecordingProvider);

    if (isRecording) {
      // Stop recording
      final filePath = await audioService.stopRecording();
      ref.read(isRecordingProvider.notifier).state = false;
      widget.onRecordingStop?.call(filePath);
    } else {
      // Start recording
      try {
        await audioService.startRecording();
        ref.read(isRecordingProvider.notifier).state = true;
        widget.onRecordingStart?.call();
      } catch (e) {
        // Show error dialog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to start recording: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use widget.isRecording if provided, otherwise use provider
    final isRecording = widget.onPressed != null
        ? widget.isRecording
        : ref.watch(isRecordingProvider);

    return GestureDetector(
      onTap: _toggleRecording,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: isRecording ? _scaleAnimation.value : 1.0,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isRecording
                      ? [Colors.red.shade400, Colors.red.shade700]
                      : [const Color(0xFF00BFFF), const Color(0xFF39FF14)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: isRecording
                        ? Colors.red.withOpacity(0.5)
                        : const Color(0xFF00BFFF).withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          );
        },
      ),
    );
  }
}
