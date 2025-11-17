import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../models/feedback.dart';
import '../../widgets/feedback_card.dart';

class FeedbackScreen extends StatefulWidget {
  final FeedbackResponse feedback;
  final int xpAwarded;
  final VoidCallback onContinue;

  const FeedbackScreen({
    super.key,
    required this.feedback,
    required this.xpAwarded,
    required this.onContinue,
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>
    with TickerProviderStateMixin {
  late AnimationController _confettiController;
  late AnimationController _xpController;
  bool _showXpAnimation = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(vsync: this);
    _xpController = AnimationController(vsync: this);

    // Show confetti animation on load
    _confettiController.forward();

    // Show XP animation after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showXpAnimation = true);
        _xpController.forward();
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _xpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E12),
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti animation overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Lottie.asset(
                  'assets/lottie/success_confetti.json',
                  controller: _confettiController,
                  onLoaded: (composition) {
                    _confettiController.duration = composition.duration;
                  },
                  repeat: false,
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildScoreCards(),
                  const SizedBox(height: 32),
                  _buildTipsSection(),
                  const SizedBox(height: 32),
                  _buildXpSection(),
                  const SizedBox(height: 32),
                  _buildContinueButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // XP coins animation
            if (_showXpAnimation)
              Positioned.fill(
                child: IgnorePointer(
                  child: Lottie.asset(
                    'assets/lottie/flying_xp_coins.json',
                    controller: _xpController,
                    onLoaded: (composition) {
                      _xpController.duration = composition.duration;
                    },
                    repeat: false,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final averageScore =
        (widget.feedback.fluency +
            widget.feedback.pronunciation +
            widget.feedback.grammar) ~/
        3;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00BFFF).withOpacity(0.3),
                const Color(0xFF39FF14).withOpacity(0.3),
              ],
            ),
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: Color(0xFF39FF14),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Lesson Complete!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Overall Score: $averageScore/100',
          style: TextStyle(fontSize: 18, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildScoreCards() {
    return Row(
      children: [
        Expanded(
          child: FeedbackCard(
            title: 'Fluency',
            score: widget.feedback.fluency,
            color: const Color(0xFF00BFFF),
            icon: Icons.speed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FeedbackCard(
            title: 'Pronunciation',
            score: widget.feedback.pronunciation,
            color: const Color(0xFF39FF14),
            icon: Icons.record_voice_over,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FeedbackCard(
            title: 'Grammar',
            score: widget.feedback.grammar,
            color: const Color(0xFFFF6B6B),
            icon: Icons.spellcheck,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection() {
    if (widget.feedback.tips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00BFFF).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFF39FF14), size: 24),
              const SizedBox(width: 8),
              const Text(
                'Tips for Improvement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.feedback.tips.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00BFFF),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[300],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildXpSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00BFFF).withOpacity(0.2),
            const Color(0xFF39FF14).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF39FF14).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: Color(0xFF39FF14), size: 32),
          const SizedBox(width: 12),
          Text(
            '+${widget.xpAwarded} XP',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF39FF14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      onPressed: widget.onContinue,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00BFFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: const Text(
        'Continue',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
