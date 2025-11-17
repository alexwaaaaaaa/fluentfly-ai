class FeedbackResponse {
  final int fluency;
  final int pronunciation;
  final int grammar;
  final List<String> tips;
  final DetailedAnalysis? detailedAnalysis;

  FeedbackResponse({
    required this.fluency,
    required this.pronunciation,
    required this.grammar,
    required this.tips,
    this.detailedAnalysis,
  });

  factory FeedbackResponse.fromJson(Map<String, dynamic> json) {
    return FeedbackResponse(
      fluency: json['fluency'] as int,
      pronunciation: json['pronunciation'] as int,
      grammar: json['grammar'] as int,
      tips: (json['tips'] as List<dynamic>).map((e) => e as String).toList(),
      detailedAnalysis: json['detailedAnalysis'] != null
          ? DetailedAnalysis.fromJson(
              json['detailedAnalysis'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DetailedAnalysis {
  final double wordsPerMinute;
  final int pauseCount;
  final List<String> lowConfidenceWords;
  final List<GrammarError> grammarErrors;

  DetailedAnalysis({
    required this.wordsPerMinute,
    required this.pauseCount,
    required this.lowConfidenceWords,
    required this.grammarErrors,
  });

  factory DetailedAnalysis.fromJson(Map<String, dynamic> json) {
    return DetailedAnalysis(
      wordsPerMinute: (json['wordsPerMinute'] as num).toDouble(),
      pauseCount: json['pauseCount'] as int,
      lowConfidenceWords: (json['lowConfidenceWords'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      grammarErrors: (json['grammarErrors'] as List<dynamic>)
          .map((e) => GrammarError.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GrammarError {
  final String text;
  final String correction;
  final String explanation;

  GrammarError({
    required this.text,
    required this.correction,
    required this.explanation,
  });

  factory GrammarError.fromJson(Map<String, dynamic> json) {
    return GrammarError(
      text: json['text'] as String,
      correction: json['correction'] as String,
      explanation: json['explanation'] as String,
    );
  }
}
