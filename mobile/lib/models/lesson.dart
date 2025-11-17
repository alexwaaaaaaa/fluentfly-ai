class Lesson {
  final int id;
  final String skill;
  final String title;
  final String level;
  final String? audioUrl;
  final String? description;
  final Map<String, dynamic>? meta;
  final int? orderIndex;
  final List<Exercise>? exercises;

  Lesson({
    required this.id,
    required this.skill,
    required this.title,
    required this.level,
    this.audioUrl,
    this.description,
    this.meta,
    this.orderIndex,
    this.exercises,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as int,
      skill: json['skill'] as String,
      title: json['title'] as String,
      level: json['level'] as String,
      audioUrl: json['audioUrl'] as String?,
      description: json['description'] as String?,
      meta: json['meta'] as Map<String, dynamic>?,
      orderIndex: json['orderIndex'] as int?,
      exercises: json['exercises'] != null
          ? (json['exercises'] as List)
                .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'skill': skill,
      'title': title,
      'level': level,
      'audioUrl': audioUrl,
      'description': description,
      'meta': meta,
      'orderIndex': orderIndex,
      'exercises': exercises?.map((e) => e.toJson()).toList(),
    };
  }
}

class Exercise {
  final int id;
  final int lessonId;
  final String type;
  final String question;
  final List<dynamic>? options;
  final Map<String, dynamic>? answer;
  final String? audioUrl;
  final int? orderIndex;

  Exercise({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.question,
    this.options,
    this.answer,
    this.audioUrl,
    this.orderIndex,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as int,
      lessonId: json['lessonId'] as int,
      type: json['type'] as String,
      question: json['question'] as String,
      options: json['options'] as List<dynamic>?,
      answer: json['answer'] as Map<String, dynamic>?,
      audioUrl: json['audioUrl'] as String?,
      orderIndex: json['orderIndex'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lessonId': lessonId,
      'type': type,
      'question': question,
      'options': options,
      'answer': answer,
      'audioUrl': audioUrl,
      'orderIndex': orderIndex,
    };
  }
}
