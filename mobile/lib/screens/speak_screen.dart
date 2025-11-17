import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/theme.dart';
import '../utils/animation_utils.dart';

/// Standalone speak screen for practicing conversation with AI tutor
/// This is different from the lesson-based speak screen
class SpeakScreen extends ConsumerWidget {
  const SpeakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Speaking'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // AI Tutor animation
              AnimationUtils.buildAnimation(
                path: AnimationUtils.aiTutorTalking,
                width: 200,
                height: 200,
              ),
              const SizedBox(height: 32),
              Text(
                'Free Conversation Practice',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(
                  'Practice speaking English with your AI tutor. Start a conversation on any topic!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Start conversation button
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to video call screen with free conversation
                    Navigator.pushNamed(
                      context,
                      '/video-call',
                      arguments: {
                        'lessonId': 0, // 0 indicates free conversation mode
                        'topic': 'Free Conversation',
                      },
                    );
                  },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Start Video Call'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Info cards
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildInfoCard(
                      context,
                      Icons.chat_bubble_outline,
                      'Natural Conversations',
                      'Talk about any topic you like',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      Icons.feedback_outlined,
                      'Instant Feedback',
                      'Get real-time pronunciation tips',
                    ),
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      context,
                      Icons.emoji_events_outlined,
                      'Earn XP',
                      'Practice daily to boost your streak',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80), // Extra space for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
