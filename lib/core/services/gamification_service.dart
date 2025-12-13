// lib/core/services/gamification_service.dart
import 'package:baddel/core/models/achievement_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GamificationService {
  final _client = Supabase.instance.client;

  Future<List<Achievement>> getAchievements() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final data = await _client
        .from('user_achievements')
        .select('*, achievement:achievements(*)')
        .eq('user_id', user.id);

    return (data as List)
        .map((json) => Achievement.fromJson(json))
        .toList();
  }

  Future<void> checkAchievements() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final unlocked = await _client.rpc(
      'check_and_unlock_achievements',
      params: {'p_user_id': user.id}
    );

    // Show notifications for newly unlocked
    for (final achievement in unlocked) {
      _showAchievementNotification(achievement);
    }
  }

  void _showAchievementNotification(Map<String, dynamic> achievement) {
    // In a real app, you would use a package like flutter_local_notifications
    // to show a proper in-app or system notification.
    print('🏆 Achievement Unlocked: ${achievement['achievement_name']} (+${achievement['points_earned']} points)');
  }
}
