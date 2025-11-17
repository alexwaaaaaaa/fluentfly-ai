import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lesson.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final Lesson lesson;
  final VoidCallback onComplete;

  const QuizScreen({Key? key, required this.lesson, required this.onComplete})
    : super(key: key);

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  int _currentQuestionIndex = 0;
  List<Exercise> _quizExercises = [];
  dynamic _userAnswer;
  int _correctAnswers = 0;
  bool _showFeedback = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  void _loadExercises() {
    if (widget.lesson.exercises != null) {
      _quizExercises = widget.lesson.exercises!
          .where((e) => e.type == 'mcq' || e.type == 'fill_blank')
          .toList();
    }
  }

  void _selectAnswer(dynamic answer) {
    if (!_showFeedback) {
      setState(() {
        _userAnswer = answer;
      });
    }
  }

  void _checkAnswer() {
    if (_userAnswer == null) return;

    final exercise = _quizExercises[_currentQuestionIndex];
    bool isCorrect = false;

    if (exercise.type == 'mcq') {
      final correctIndex = exercise.answer?['correct'] as int?;
      isCorrect = _userAnswer == correctIndex;
    } else if (exercise.type == 'fill_blank') {
      final correctAnswer = exercise.answer?['text'] as String?;
      isCorrect =
          _userAnswer.toString().toLowerCase() == correctAnswer?.toLowerCase();
    }

    setState(() {
      _showFeedback = true;
      if (isCorrect) {
        _correctAnswers++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _quizExercises.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _userAnswer = null;
        _showFeedback = false;
      });
    } else {
      // Complete quiz stage
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_quizExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No quiz questions available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: widget.onComplete,
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }

    final exercise = _quizExercises[_currentQuestionIndex];

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
                    'Quiz',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_currentQuestionIndex + 1}/${_quizExercises.length}',
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
                  value: (_currentQuestionIndex + 1) / _quizExercises.length,
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
        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Question
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      exercise.question,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Answer options
                if (exercise.type == 'mcq')
                  _buildMCQOptions(exercise, theme)
                else if (exercise.type == 'fill_blank')
                  _buildFillBlankInput(exercise, theme),
                // Feedback
                if (_showFeedback) ...[
                  const SizedBox(height: 24),
                  _buildFeedback(exercise),
                ],
              ],
            ),
          ),
        ),
        // Action buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: _showFeedback
              ? ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _currentQuestionIndex < _quizExercises.length - 1
                        ? 'Next Question'
                        : 'Complete Quiz',
                  ),
                )
              : ElevatedButton(
                  onPressed: _userAnswer != null ? _checkAnswer : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Check Answer'),
                ),
        ),
      ],
    );
  }

  Widget _buildMCQOptions(Exercise exercise, ThemeData theme) {
    final correctIndex = exercise.answer?['correct'] as int?;

    return Column(
      children: List.generate(exercise.options?.length ?? 0, (index) {
        final isSelected = _userAnswer == index;
        final isCorrect = index == correctIndex;
        final showCorrect = _showFeedback && isCorrect;
        final showIncorrect = _showFeedback && isSelected && !isCorrect;

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
                    const Icon(Icons.check_circle, color: Colors.green)
                  else if (showIncorrect)
                    const Icon(Icons.cancel, color: Colors.red),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFillBlankInput(Exercise exercise, ThemeData theme) {
    final controller = TextEditingController(
      text: _userAnswer?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      enabled: !_showFeedback,
      decoration: InputDecoration(
        hintText: 'Type your answer here',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      style: theme.textTheme.bodyLarge,
      onChanged: (value) {
        _userAnswer = value;
      },
    );
  }

  Widget _buildFeedback(Exercise exercise) {
    bool isCorrect = false;

    if (exercise.type == 'mcq') {
      final correctIndex = exercise.answer?['correct'] as int?;
      isCorrect = _userAnswer == correctIndex;
    } else if (exercise.type == 'fill_blank') {
      final correctAnswer = exercise.answer?['text'] as String?;
      isCorrect =
          _userAnswer.toString().toLowerCase() == correctAnswer?.toLowerCase();
    }

    return Card(
      color: isCorrect
          ? Colors.green.withOpacity(0.1)
          : Colors.red.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isCorrect ? Icons.check_circle : Icons.cancel,
              color: isCorrect ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCorrect ? 'Correct!' : 'Incorrect',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isCorrect ? Colors.green : Colors.red,
                    ),
                  ),
                  if (!isCorrect && exercise.type == 'fill_blank') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Correct answer: ${exercise.answer?['text']}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
