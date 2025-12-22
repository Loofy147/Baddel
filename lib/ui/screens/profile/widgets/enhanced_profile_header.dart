import 'package:flutter/material.dart';
import 'package:baddel/ui/theme.dart';
import 'dart:ui' as ui;

/// An enhanced profile header with animated reputation ring and glassmorphism design.
class EnhancedProfileHeader extends StatefulWidget {
  final int score;
  final String phone;
  final Map<String, dynamic> profileData;

  const EnhancedProfileHeader({
    Key? key,
    required this.score,
    required this.phone,
    required this.profileData,
  }) : super(key: key);

  @override
  State<EnhancedProfileHeader> createState() => _EnhancedProfileHeaderState();
}

class _EnhancedProfileHeaderState extends State<EnhancedProfileHeader> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getLevelName() {
    if (widget.score > 80) return 'BOSS';
    if (widget.score > 60) return 'MERCHANT';
    return 'NOVICE';
  }

  Color _getLevelColor() {
    if (widget.score > 80) return AppTheme.neonGreen;
    if (widget.score > 60) return AppTheme.neonPurple;
    return AppTheme.secondaryText;
  }

  @override
  Widget build(BuildContext context) {
    final levelColor = _getLevelColor();
    final levelName = _getLevelName();

    return ClipRRect(
      borderRadius: AppTheme.borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.all(AppTheme.spacingMedium),
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            borderRadius: AppTheme.borderRadius,
            border: Border.all(
              color: levelColor.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              // Header row with avatar and level badge
              Row(
                children: [
                  // Avatar with glow effect
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: levelColor.withOpacity(0.5 * _animationController.value),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: levelColor.withOpacity(0.2),
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color: levelColor,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: AppTheme.spacingMedium),
                  // User info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          phone,
                          style: AppTheme.textTheme.titleLarge,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Level badge with neon effect
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: levelColor.withOpacity(0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: levelColor.withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Text(
                            levelName,
                            style: AppTheme.textTheme.labelLarge?.copyWith(
                              color: levelColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reputation score circle
                  _buildReputationRing(levelColor),
                ],
              ),
              const SizedBox(height: AppTheme.spacingLarge),
              // Stats row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                    'Active',
                    '${widget.profileData['active_items'] ?? 0}',
                    AppTheme.neonGreen,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.borderColor,
                  ),
                  _buildStatItem(
                    'Sold',
                    '${widget.profileData['sold_items'] ?? 0}',
                    AppTheme.neonPurple,
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.borderColor,
                  ),
                  _buildStatItem(
                    'Deals',
                    '${widget.profileData['completed_deals'] ?? 0}',
                    AppTheme.vividRed,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReputationRing(Color color) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          // Animated progress ring
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(80, 80),
                painter: ReputationRingPainter(
                  progress: (widget.score / 100).clamp(0, 1),
                  color: color,
                  glowIntensity: _animationController.value,
                ),
              );
            },
          ),
          // Center text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${widget.score}',
                style: AppTheme.textTheme.headlineMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'REP',
                style: AppTheme.textTheme.bodyMedium?.copyWith(
                  color: color.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: AppTheme.textTheme.headlineMedium?.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTheme.textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// Custom painter for the animated reputation ring.
class ReputationRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double glowIntensity;

  ReputationRingPainter({
    required this.progress,
    required this.color,
    required this.glowIntensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Draw glow effect
    final glowPaint = Paint()
      ..color = color.withOpacity(0.2 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, glowPaint);

    // Draw progress arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -3.14159 / 2, // Start from top
      (3.14159 * 2) * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(ReputationRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.glowIntensity != glowIntensity;
  }
}
