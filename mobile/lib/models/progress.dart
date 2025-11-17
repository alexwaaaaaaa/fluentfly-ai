class Progress {
  final int id;
  final int userId;
  final int lessonId;
  final Map<String, dynamic> score;
  final bool completed;
  final int? timeSpent;
  final DateTime? completedAt;
  final DateTime createdAt;

  Progress({
    required this.id,
    required this.userId,
    required this.lessonId,
    required this.score,
    required this.completed,
    this.timeSpent,
    this.completedAt,
    required this.createdAt,
  });

  factory Progress.fromJson(Map<String, dynamic> json) {
    return Progress(
      id: json['id'] as int,
      userId: json['userId'] as int,
      lessonId: json['lessonId'] as int,
      score: json['score'] as Map<String, dynamic>,
      completed: json['completed'] as bool,
      timeSpent: json['timeSpent'] as int?,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'lessonId': lessonId,
      'score': score,
      'completed': completed,
      'timeSpent': timeSpent,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  int get percentage => score['percentage'] as int? ?? 0;
  int get correct => score['correct'] as int? ?? 0;
  int get total => score['total'] as int? ?? 0;
}

class ProgressStats {
  final int totalLessonsCompleted;
  final int totalTimeSpent;
  final double averageScore;
  final int lessonsInProgress;
  final int totalXpEarned;
  final List<Progress> recentProgress;

  ProgressStats({
    required this.totalLessonsCompleted,
    required this.totalTimeSpent,
    required this.averageScore,
    required this.lessonsInProgress,
    required this.totalXpEarned,
    required this.recentProgress,
  });

  factory ProgressStats.fromJson(Map<String, dynamic> json) {
    return ProgressStats(
      totalLessonsCompleted: json['totalLessonsCompleted'] as int,
      totalTimeSpent: json['totalTimeSpent'] as int,
      averageScore: (json['averageScore'] as num).toDouble(),
      lessonsInProgress: json['lessonsInProgress'] as int,
      totalXpEarned: json['totalXpEarned'] as int,
      recentProgress: (json['recentProgress'] as List)
          .map((e) => Progress.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ReviewItem {
  final int lessonId;
  final String lessonTitle;
  final String exerciseType;
  final String question;
  final String? userAnswer;
  final String correctAnswer;
  final String? audioUrl;
  final bool isVocabulary;

  ReviewItem({
    required this.lessonId,
    required this.lessonTitle,
    required this.exerciseType,
    required this.question,
    this.userAnswer,
    required this.correctAnswer,
    this.audioUrl,
    this.isVocabulary = false,
  });
}
