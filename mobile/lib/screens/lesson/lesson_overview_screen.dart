import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/lesson_provider.dart';
import 'lesson_flow_screen.dart';

class LessonOverviewScreen extends ConsumerWidget {
  final int lessonId;

  const LessonOverviewScreen({Key? key, required this.lessonId})
    : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lessonAsync = ref.watch(lessonProvider(lessonId));

    return Scaffold(
      body: lessonAsync.when(
        data: (lesson) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(lesson.title),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level and skill
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getLevelColor(lesson.level),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            lesson.level,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          lesson.skill,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Description
                    if (lesson.description != null) ...[
                      Text(
                        lesson.description!,
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Lesson info
                    if (lesson.meta != null) ...[
                      _buildInfoRow(
                        context,
                        Icons.access_time,
                        'Duration',
                        '${lesson.meta!['duration'] ?? 'N/A'} minutes',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        context,
                        Icons.stars,
                        'XP Reward',
                        '${lesson.meta!['xp'] ?? 'N/A'} XP',
                      ),
                      const SizedBox(height: 12),
                      if (lesson.meta!['vocabulary'] != null) ...[
                        _buildInfoRow(
                          context,
                          Icons.book,
                          'Vocabulary',
                          '${(lesson.meta!['vocabulary'] as List).length} words',
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                    // Lesson stages
                    Text(
                      'Lesson Stages',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStageCard(
                      context,
                      Icons.menu_book,
                      'Vocabulary',
                      'Learn new words and phrases',
                      0,
                    ),
                    const SizedBox(height: 12),
                    _buildStageCard(
                      context,
                      Icons.headphones,
                      'Listening',
                      'Practice listening comprehension',
                      1,
                    ),
                    const SizedBox(height: 12),
                    _buildStageCard(
                      context,
                      Icons.mic,
                      'Speaking',
                      'Practice pronunciation with AI',
                      2,
                    ),
                    const SizedBox(height: 12),
                    _buildStageCard(
                      context,
                      Icons.quiz,
                      'Quiz',
                      'Test your knowledge',
                      3,
                    ),
                    const SizedBox(height: 12),
                    _buildStageCard(
                      context,
                      Icons.assessment,
                      'Feedback',
                      'Review your performance',
                      4,
                    ),
                    const SizedBox(height: 32),
                    // Start button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LessonFlowScreen(lessonId: lessonId),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Start Lesson',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Failed to load lesson', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(lessonProvider(lessonId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(value, style: theme.textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildStageCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    int index,
  ) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: Text(
          '${index + 1}',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'A1':
        return Colors.green;
      case 'A2':
        return Colors.lightGreen;
      case 'B1':
        return Colors.blue;
      case 'B2':
        return Colors.indigo;
      case 'C1':
        return Colors.purple;
      case 'C2':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}
