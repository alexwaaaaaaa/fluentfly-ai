class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? audioUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.audioUrl,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      audioUrl: json['audioUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'audioUrl': audioUrl,
    };
  }
}

class ChatResponse {
  final String reply;
  final String emotion;
  final String? hint;
  final String ttsUrl;

  ChatResponse({
    required this.reply,
    required this.emotion,
    this.hint,
    required this.ttsUrl,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    return ChatResponse(
      reply: json['reply'] as String,
      emotion: json['emotion'] as String,
      hint: json['hint'] as String?,
      ttsUrl: json['ttsUrl'] as String,
    );
  }
}
