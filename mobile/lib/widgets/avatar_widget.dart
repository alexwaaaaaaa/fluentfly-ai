import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AvatarWidget extends StatefulWidget {
  final bool isAnimating;
  final String animationPath;
  final String emotion;

  const AvatarWidget({
    super.key,
    required this.isAnimating,
    this.animationPath = 'assets/lottie/ai_tutor_talking.json',
    this.emotion = 'neutral',
  });

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _currentAnimationPath;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _currentAnimationPath = widget.animationPath;
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update animation based on isAnimating state
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.stop();
      _controller.reset();
    }

    // Update animation path if emotion changed
    if (widget.emotion != oldWidget.emotion) {
      setState(() {
        _currentAnimationPath = _getAnimationPathForEmotion(widget.emotion);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getAnimationPathForEmotion(String emotion) {
    switch (emotion) {
      case 'happy':
        return 'assets/lottie/happy_feedback_star.json';
      case 'encouraging':
        return 'assets/lottie/ai_tutor_talking.json';
      case 'neutral':
      default:
        return 'assets/lottie/ai_tutor_talking.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00BFFF).withOpacity(0.2),
            const Color(0xFF39FF14).withOpacity(0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00BFFF).withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: Lottie.asset(
          _currentAnimationPath ?? widget.animationPath,
          controller: _controller,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            if (widget.isAnimating) {
              _controller.repeat();
            }
          },
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to pulse animation on error
            return Lottie.asset(
              'assets/lottie/fallback_pulse.json',
              fit: BoxFit.cover,
            );
          },
        ),
      ),
    );
  }
}
