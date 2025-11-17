import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../models/progress.dart';
import '../models/lesson.dart';
import '../services/progress_service.dart';
import '../services/lesson_service.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

final reviewItemsProvider = FutureProvider<List<ReviewItem>>((ref) async {
  final apiService = ApiService();
  final cacheService = CacheService();
  final connectivityService = ConnectivityService();
  final progressService = ProgressService(apiService);
  final lessonService = LessonService(
    apiService,
    cacheService,
    connectivityService,
  );
  final logger = Logger();

  try {
    // Get all user progress
    final progressList = await progressService.getProgress();

    // Filter for completed lessons with scores < 80%
    final needsReview = progressList
        .where((p) => p.completed && p.percentage < 80)
        .toList();

    // Get lessons for review items
    final reviewItems = <ReviewItem>[];

    for (final progress in needsReview) {
      try {
        final lesson = await lessonService.getLesson(progress.lessonId);

        // Add vocabulary items from lesson
        if (lesson.meta != null && lesson.meta!['vocabulary'] != null) {
          final vocabulary = lesson.meta!['vocabulary'] as List;
          for (final word in vocabulary) {
            reviewItems.add(
              ReviewItem(
                lessonId: lesson.id,
                lessonTitle: lesson.title,
                exerciseType: 'vocabulary',
                question: word.toString(),
                correctAnswer: word.toString(),
                audioUrl: lesson.audioUrl,
                isVocabulary: true,
              ),
            );
          }
        }

        // Add incorrectly answered exercises
        if (lesson.exercises != null) {
          for (final exercise in lesson.exercises!) {
            // Simulate incorrect answers (in real app, track actual user answers)
            if (progress.percentage < 80) {
              reviewItems.add(
                ReviewItem(
                  lessonId: lesson.id,
                  lessonTitle: lesson.title,
                  exerciseType: exercise.type,
                  question: exercise.question,
                  correctAnswer: _getCorrectAnswer(exercise),
                  audioUrl: exercise.audioUrl,
                  isVocabulary: false,
                ),
              );
            }
          }
        }
      } catch (e) {
        logger.e('Failed to load lesson ${progress.lessonId}', error: e);
      }
    }

    // Apply spaced repetition sorting (most recent mistakes first)
    reviewItems.sort((a, b) => b.lessonId.compareTo(a.lessonId));

    return reviewItems;
  } catch (e) {
    logger.e('Failed to load review items', error: e);
    return [];
  }
});

String _getCorrectAnswer(Exercise exercise) {
  if (exercise.answer != null) {
    if (exercise.answer!['correct'] != null) {
      final correctIndex = exercise.answer!['correct'] as int;
      if (exercise.options != null && correctIndex < exercise.options!.length) {
        return exercise.options![correctIndex] as String;
      }
    }
    if (exercise.answer!['text'] != null) {
      return exercise.answer!['text'] as String;
    }
  }
  return 'N/A';
}

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewItemsAsync = ref.watch(reviewItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        backgroundColor: const Color(0xFF0A0E12),
      ),
      backgroundColor: const Color(0xFF0A0E12),
      body: reviewItemsAsync.when(
        data: (items) =>
            items.isEmpty ? _buildEmptyState() : _buildReviewList(items, ref),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF00BFFF)),
        ),
        error: (error, stack) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Colors.green.shade400,
          ),
          const SizedBox(height: 24),
          const Text(
            'Great job!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No items to review right now.',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete more lessons to add items here.',
            style: TextStyle(fontSize: 14, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 24),
          const Text(
            'Failed to load review items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            error,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<ReviewItem> items, WidgetRef ref) {
    // Group items by lesson
    final groupedItems = <int, List<ReviewItem>>{};
    for (final item in items) {
      groupedItems.putIfAbsent(item.lessonId, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildHeader(items.length),
        const SizedBox(height: 24),
        ...groupedItems.entries.map((entry) {
          final lessonItems = entry.value;
          final lessonTitle = lessonItems.first.lessonTitle;

          return _buildLessonSection(lessonTitle, lessonItems, ref);
        }),
      ],
    );
  }

  Widget _buildHeader(int itemCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00BFFF), Color(0xFF39FF14)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Practice',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$itemCount items to review',
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonSection(
    String lessonTitle,
    List<ReviewItem> items,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            lessonTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00BFFF),
            ),
          ),
        ),
        ...items.map((item) => _buildReviewCard(item, ref)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviewCard(ReviewItem item, WidgetRef ref) {
    return Card(
      color: const Color(0xFF1A1F2E),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildTypeChip(item.exerciseType),
                const Spacer(),
                if (item.audioUrl != null || item.isVocabulary)
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: Color(0xFF00BFFF)),
                    onPressed: () => _playAudio(item, ref),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (item.userAnswer != null) ...[
              Text(
                'Your answer: ${item.userAnswer}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.redAccent,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(height: 4),
            ],
            Text(
              'Correct: ${item.correctAnswer}',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF39FF14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final color = _getTypeColor(type);
    final label = _getTypeLabel(type);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'vocabulary':
        return const Color(0xFF39FF14);
      case 'mcq':
        return const Color(0xFF00BFFF);
      case 'speaking':
        return Colors.orange;
      case 'listening':
        return Colors.purple;
      case 'fill_blank':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'vocabulary':
        return 'Vocabulary';
      case 'mcq':
        return 'Multiple Choice';
      case 'speaking':
        return 'Speaking';
      case 'listening':
        return 'Listening';
      case 'fill_blank':
        return 'Fill in the Blank';
      default:
        return type;
    }
  }

  Future<void> _playAudio(ReviewItem item, WidgetRef ref) async {
    final audioService = AudioService();
    final apiService = ApiService();
    final logger = Logger();

    try {
      String audioUrl;

      if (item.isVocabulary) {
        // Generate TTS for vocabulary word
        audioUrl = await apiService.getTextToSpeech(item.question);
      } else if (item.audioUrl != null) {
        audioUrl = item.audioUrl!;
      } else {
        return;
      }

      await audioService.playAudio(audioUrl);
    } catch (e) {
      logger.e('Failed to play audio', error: e);
    }
  }
}
