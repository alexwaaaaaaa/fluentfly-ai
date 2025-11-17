class User {
  final int id;
  final String? email;
  final String? phone;
  final String name;
  final int xp;
  final int streak;
  final String level;
  final String? profileImageUrl;

  User({
    required this.id,
    this.email,
    this.phone,
    required this.name,
    required this.xp,
    required this.streak,
    required this.level,
    this.profileImageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      name: json['name'] as String,
      xp: json['xp'] as int,
      streak: json['streak'] as int,
      level: json['level'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'xp': xp,
      'streak': streak,
      'level': level,
      'profileImageUrl': profileImageUrl,
    };
  }
}
