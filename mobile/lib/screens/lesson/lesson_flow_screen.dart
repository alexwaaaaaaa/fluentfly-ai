import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lesson.dart';
import '../../models/feedback.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/lesson_state_provider.dart';
import 'vocabulary_screen.dart';
import 'listening_screen.dart';
import 'speak_screen.dart';
import 'quiz_screen.dart';
import 'feedback_screen.dart';

class LessonFlowScreen extends ConsumerWidget {
  final int lessonId;

  const LessonFlowScreen({super.key, required this.lessonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonProvider(lessonId));
    final lessonState = ref.watch(lessonStateProvider(lessonId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_getStageName(lessonState.currentStage)),
        actions: [
          // Progress indicator
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${(lessonState.progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
      body: lessonAsync.when(
        data: (lesson) {
          if (lessonState.isCompleted) {
            return _buildCompletionScreen(context, ref, lesson, lessonState);
          }

          return _buildStageScreen(context, ref, lesson, lessonState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageScreen(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    LessonState state,
  ) {
    switch (state.currentStage) {
      case LessonStage.vocabulary:
        return VocabularyScreen(
          lesson: lesson,
          onComplete: () {
            ref.read(lessonStateProvider(lessonId).notifier).completeStage(100);
          },
        );
      case LessonStage.listening:
        return ListeningScreen(
          lesson: lesson,
          onComplete: () {
            ref.read(lessonStateProvider(lessonId).notifier).completeStage(100);
          },
        );
      case LessonStage.speaking:
        return SpeakScreen(
          lessonId: lessonId,
          topic: lesson.title,
          onComplete: () {
            ref.read(lessonStateProvider(lessonId).notifier).completeStage(100);
          },
        );
      case LessonStage.quiz:
        return QuizScreen(
          lesson: lesson,
          onComplete: () {
            ref.read(lessonStateProvider(lessonId).notifier).completeStage(100);
          },
        );
      case LessonStage.feedback:
        return _buildFeedbackScreen(context, ref, lesson, state);
    }
  }

  Widget _buildFeedbackScreen(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    LessonState state,
  ) {
    // Generate feedback based on lesson performance
    final feedback = FeedbackResponse(
      fluency: _calculateFluencyScore(state),
      pronunciation: _calculatePronunciationScore(state),
      grammar: _calculateGrammarScore(state),
      tips: _generateTips(state),
    );

    final xpAwarded = lesson.meta?['xp'] as int? ?? 25;

    return FeedbackScreen(
      feedback: feedback,
      xpAwarded: xpAwarded,
      onContinue: () {
        ref.read(lessonStateProvider(lessonId).notifier).completeStage(100);
      },
    );
  }

  int _calculateFluencyScore(LessonState state) {
    // Calculate based on stage scores
    final scores = state.scores.values.toList();
    if (scores.isEmpty) return 75;
    return (scores.reduce((a, b) => a + b) / scores.length).round();
  }

  int _calculatePronunciationScore(LessonState state) {
    // For now, return a score based on overall performance
    return _calculateFluencyScore(state) + 5;
  }

  int _calculateGrammarScore(LessonState state) {
    // For now, return a score based on overall performance
    return _calculateFluencyScore(state) - 5;
  }

  List<String> _generateTips(LessonState state) {
    final tips = <String>[];
    final avgScore = _calculateFluencyScore(state);

    if (avgScore < 70) {
      tips.add('Practice speaking more slowly to improve clarity');
      tips.add('Review the vocabulary words before speaking exercises');
    } else if (avgScore < 85) {
      tips.add('Great progress! Try to speak with more confidence');
      tips.add('Focus on pronunciation of difficult words');
    } else {
      tips.add('Excellent work! Keep practicing to maintain your skills');
      tips.add('Try more advanced lessons to challenge yourself');
    }

    return tips;
  }

  Widget _buildCompletionScreen(
    BuildContext context,
    WidgetRef ref,
    Lesson lesson,
    LessonState state,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.celebration, size: 100, color: Colors.amber),
            const SizedBox(height: 24),
            const Text(
              'Congratulations!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'You completed "${lesson.title}"',
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildStatRow('Total Score', '${state.totalScore}'),
                    const Divider(height: 24),
                    _buildStatRow('XP Earned', '${lesson.meta?['xp'] ?? 0}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Continue', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _getStageName(LessonStage stage) {
    switch (stage) {
      case LessonStage.vocabulary:
        return 'Vocabulary';
      case LessonStage.listening:
        return 'Listening';
      case LessonStage.speaking:
        return 'Speaking';
      case LessonStage.quiz:
        return 'Quiz';
      case LessonStage.feedback:
        return 'Feedback';
    }
  }
}
