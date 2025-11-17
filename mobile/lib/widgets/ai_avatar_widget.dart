import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../config/theme.dart';

/// Animated AI avatar widget for video calls
class AIAvatarWidget extends StatefulWidget {
  final bool isSpeaking;
  final double size;

  const AIAvatarWidget({super.key, required this.isSpeaking, this.size = 120});

  @override
  State<AIAvatarWidget> createState() => _AIAvatarWidgetState();
}

class _AIAvatarWidgetState extends State<AIAvatarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.accentColor.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: widget.isSpeaking
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing ring when speaking
          if (widget.isSpeaking)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.accentColor.withValues(alpha: 0.6),
                        width: 3,
                      ),
                    ),
                  ),
                );
              },
            ),

          // Avatar content
          ClipOval(
            child: Container(
              width: widget.size - 16,
              height: widget.size - 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                    AppTheme.accentColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: widget.isSpeaking
                  ? _buildSpeakingAnimation()
                  : _buildIdleAvatar(),
            ),
          ),

          // Sound wave indicator when speaking
          if (widget.isSpeaking) _buildSoundWaveIndicator(),
        ],
      ),
    );
  }

  Widget _buildSpeakingAnimation() {
    return Lottie.asset(
      'assets/lottie/ai_tutor_talking.json',
      fit: BoxFit.cover,
      repeat: true,
    );
  }

  Widget _buildIdleAvatar() {
    return const Icon(Icons.smart_toy, size: 48, color: Colors.white);
  }

  Widget _buildSoundWaveIndicator() {
    return Positioned(
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildWaveBar(0.3),
            const SizedBox(width: 2),
            _buildWaveBar(0.6),
            const SizedBox(width: 2),
            _buildWaveBar(0.9),
            const SizedBox(width: 2),
            _buildWaveBar(0.6),
            const SizedBox(width: 2),
            _buildWaveBar(0.3),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(double heightFactor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final animatedHeight = 12 * heightFactor * _pulseAnimation.value;
        return Container(
          width: 3,
          height: animatedHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
