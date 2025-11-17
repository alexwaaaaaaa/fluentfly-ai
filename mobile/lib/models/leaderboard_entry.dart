class LeaderboardEntry {
  final int rank;
  final int userId;
  final String name;
  final int xp;
  final String level;
  final int streak;
  final String? profileImageUrl;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.level,
    required this.streak,
    this.profileImageUrl,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'],
      userId: json['userId'],
      name: json['name'],
      xp: json['xp'],
      level: json['level'],
      streak: json['streak'],
      profileImageUrl: json['profileImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'userId': userId,
      'name': name,
      'xp': xp,
      'level': level,
      'streak': streak,
      'profileImageUrl': profileImageUrl,
    };
  }
}
