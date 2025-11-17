class Badge {
  final int id;
  final String name;
  final String? description;
  final String? iconUrl;
  final Map<String, dynamic>? criteria;
  final DateTime? earnedAt;

  Badge({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.criteria,
    this.earnedAt,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['iconUrl'],
      criteria: json['criteria'],
      earnedAt: json['earnedAt'] != null
          ? DateTime.parse(json['earnedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'criteria': criteria,
      'earnedAt': earnedAt?.toIso8601String(),
    };
  }
}
