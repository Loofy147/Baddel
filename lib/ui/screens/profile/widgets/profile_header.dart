import 'package:flutter/material.dart';
import '../../../theme.dart';

class ProfileHeader extends StatelessWidget {
  final int score;
  final String phone;
  final Map<String, dynamic> profileData;

  const ProfileHeader({
    super.key,
    required this.score,
    required this.phone,
    required this.profileData,
  });

  @override
  Widget build(BuildContext context) {
    String level = "Novice";
    Color color = AppTheme.secondaryText;
    if (score > 60) {
      level = "Merchant";
      color = AppTheme.neonPurple;
    }
    if (score > 80) {
      level = "Boss";
      color = AppTheme.electricBlue;
    }

    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: AppTheme.borderRadius,
        border: AppTheme.border,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(Icons.person, size: 30, color: color),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phone, style: AppTheme.textTheme.titleLarge),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    child: Text(level.toUpperCase(), style: AppTheme.textTheme.labelLarge?.copyWith(color: Colors.black)),
                  )
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Text("$score", style: AppTheme.textTheme.displayLarge?.copyWith(color: color)),
                  Text("REP SCORE", style: AppTheme.textTheme.bodyMedium?.copyWith(color: AppTheme.secondaryText)),
                ],
              )
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(context, "Active", "${profileData['active_items'] ?? 0}"),
              _statItem(context, "Sold", "${profileData['sold_items'] ?? 0}"),
              _statItem(context, "Deals", "0"),
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(value, style: AppTheme.textTheme.headlineMedium),
        Text(label, style: AppTheme.textTheme.bodyMedium),
      ],
    );
  }
}
