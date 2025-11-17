import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lesson.dart';

class ListeningScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final VoidCallback onComplete;

  const ListeningScreen({
    Key? key,
    required this.lesson,
    required this.onComplete,
  }) : super(key: key);

  @override
  ConsumerState<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends ConsumerState<ListeningScreen> {
  int _currentExerciseIndex = 0;
  List<Exercise> _listeningExercises = [];
  int? _selectedAnswer;
  int _correctAnswers = 0;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    if (widget.lesson.exercises != null) {
      _listeningExercises = widget.lesson.exercises!
          .where((e) => e.type == 'listening' || e.type == 'mcq')
          .toList();
    }
  }

  void _playAudio() {
    // TODO: Implement audio playback
    final exercise = _listeningExercises[_currentExerciseIndex];
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing audio: ${exercise.audioUrl ?? "No audio"}'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _selectAnswer(int index) {
    if (!_showFeedback) {
      setState(() {
        _selectedAnswer = index;
      });
    }
  }

  void _checkAnswer() {
    if (_selectedAnswer == null) return;

    final exercise = _listeningExercises[_currentExerciseIndex];
    final correctIndex = exercise.answer?['correct'] as int?;

    setState(() {
      _showFeedback = true;
      if (_selectedAnswer == correctIndex) {
        _correctAnswers++;
      }
    });
  }

  void _nextExercise() {
    if (_currentExerciseIndex < _listeningExercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _selectedAnswer = null;
        _showFeedback = false;
      });
    } else {
      // Complete listening stage
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_listeningExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No listening exercises available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onComplete,
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }

    final exercise = _listeningExercises[_currentExerciseIndex];
    final correctIndex = exercise.answer?['correct'] as int?;

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Listening Practice',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentExerciseIndex + 1}/${_listeningExercises.length}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      (_currentExerciseIndex + 1) / _listeningExercises.length,
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Exercise content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Audio player
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.headphones,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _playAudio,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play Audio'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Question
                Text(
                  exercise.question,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                // Options
                if (exercise.options != null)
                  ...List.generate(exercise.options!.length, (index) {
                    final isSelected = _selectedAnswer == index;
                    final isCorrect = index == correctIndex;
                    final showCorrect = _showFeedback && isCorrect;
                    final showIncorrect =
                        _showFeedback && isSelected && !isCorrect;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _selectAnswer(index),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: showCorrect
                                ? Colors.green.withOpacity(0.2)
                                : showIncorrect
                                ? Colors.red.withOpacity(0.2)
                                : isSelected
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : Colors.grey[100],
                            border: Border.all(
                              color: showCorrect
                                  ? Colors.green
                                  : showIncorrect
                                  ? Colors.red
                                  : isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.grey[300]!,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  exercise.options![index].toString(),
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                              if (showCorrect)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              else if (showIncorrect)
                                const Icon(Icons.cancel, color: Colors.red),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: _showFeedback
              ? ElevatedButton(
                  onPressed: _nextExercise,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentExerciseIndex < _listeningExercises.length - 1
                        ? 'Next Exercise'
                        : 'Complete',
                  ),
                )
              : ElevatedButton(
                  onPressed: _selectedAnswer != null ? _checkAnswer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Check Answer'),
                ),
        ),
      ],
    );
  }
}
