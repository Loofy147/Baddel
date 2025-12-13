// lib/ui/screens/profile/achievements_screen.dart
import 'package:baddel/core/models/achievement_model.dart';
import 'package:baddel/core/services/gamification_service.dart';
import 'package:flutter/material.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final _gamificationService = GamificationService();
  late Future<List<Achievement>> _achievementsFuture;

  @override
  void initState() {
    super.initState();
    _achievementsFuture = _gamificationService.getAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: FutureBuilder<List<Achievement>>(
        future: _achievementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No achievements yet.'));
          }

          final achievements = snapshot.data!;
          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return ListTile(
                leading: Text(achievement.icon, style: const TextStyle(fontSize: 24)),
                title: Text(achievement.name),
                subtitle: Text(achievement.description),
                trailing: achievement.isUnlocked
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.lock, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }
}
