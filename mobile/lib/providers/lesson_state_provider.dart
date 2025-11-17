import 'package:flutter_riverpod/flutter_riverpod.dart';

enum LessonStage { vocabulary, listening, speaking, quiz, feedback }

class LessonState {
  final int lessonId;
  final LessonStage currentStage;
  final Map<LessonStage, int> scores;
  final int currentExerciseIndex;
  final bool isCompleted;

  LessonState({
    required this.lessonId,
    required this.currentStage,
    required this.scores,
    this.currentExerciseIndex = 0,
    this.isCompleted = false,
  });

  LessonState copyWith({
    int? lessonId,
    LessonStage? currentStage,
    Map<LessonStage, int>? scores,
    int? currentExerciseIndex,
    bool? isCompleted,
  }) {
    return LessonState(
      lessonId: lessonId ?? this.lessonId,
      currentStage: currentStage ?? this.currentStage,
      scores: scores ?? this.scores,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  factory LessonState.initial(int lessonId) {
    return LessonState(
      lessonId: lessonId,
      currentStage: LessonStage.vocabulary,
      scores: {},
    );
  }

  int get totalScore {
    return scores.values.fold(0, (sum, score) => sum + score);
  }

  double get progress {
    final stageIndex = LessonStage.values.indexOf(currentStage);
    return (stageIndex + 1) / LessonStage.values.length;
  }
}

class LessonStateNotifier extends StateNotifier<LessonState> {
  LessonStateNotifier(int lessonId) : super(LessonState.initial(lessonId));

  void nextStage() {
    final currentIndex = LessonStage.values.indexOf(state.currentStage);
    if (currentIndex < LessonStage.values.length - 1) {
      state = state.copyWith(
        currentStage: LessonStage.values[currentIndex + 1],
        currentExerciseIndex: 0,
      );
    } else {
      state = state.copyWith(isCompleted: true);
    }
  }

  void previousStage() {
    final currentIndex = LessonStage.values.indexOf(state.currentStage);
    if (currentIndex > 0) {
      state = state.copyWith(
        currentStage: LessonStage.values[currentIndex - 1],
        currentExerciseIndex: 0,
      );
    }
  }

  void setStage(LessonStage stage) {
    state = state.copyWith(currentStage: stage, currentExerciseIndex: 0);
  }

  void completeStage(int score) {
    final newScores = Map<LessonStage, int>.from(state.scores);
    newScores[state.currentStage] = score;

    state = state.copyWith(scores: newScores);
    nextStage();
  }

  void nextExercise() {
    state = state.copyWith(
      currentExerciseIndex: state.currentExerciseIndex + 1,
    );
  }

  void reset() {
    state = LessonState.initial(state.lessonId);
  }
}

// Provider for lesson state
final lessonStateProvider =
    StateNotifierProvider.family<LessonStateNotifier, LessonState, int>(
      (ref, lessonId) => LessonStateNotifier(lessonId),
    );
