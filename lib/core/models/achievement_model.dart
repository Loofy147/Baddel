// lib/core/models/achievement_model.dart

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int points;
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.points,
    required this.isUnlocked,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final achievementData = json['achievement'] as Map<String, dynamic>;
    return Achievement(
      id: achievementData['id'] as String,
      name: achievementData['name'] as String,
      description: achievementData['description'] as String,
      icon: achievementData['icon'] as String,
      points: achievementData['points'] as int,
      isUnlocked: json['unlocked_at'] != null,
    );
  }
}
