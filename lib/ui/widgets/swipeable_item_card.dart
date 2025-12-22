import 'package:flutter/material.dart';
import 'package:baddel/ui/theme.dart';
import 'dart:ui' as ui;

/// A premium, swipeable card widget that displays marketplace items with glassmorphism effects.
class SwipeableItemCard extends StatefulWidget {
  final String itemId;
  final String imageUrl;
  final String title;
  final String price;
  final String distance;
  final bool acceptsSwaps;

  const SwipeableItemCard({
    Key? key,
    required this.itemId,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.distance,
    required this.acceptsSwaps,
  }) : super(key: key);

  @override
  State<SwipeableItemCard> createState() => _SwipeableItemCardState();
}

class _SwipeableItemCardState extends State<SwipeableItemCard> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppTheme.borderRadius,
            boxShadow: [
              // Neon glow effect
              BoxShadow(
                color: AppTheme.neonGreen.withOpacity(0.3 * _glowController.value),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppTheme.borderRadius,
            child: Stack(
              children: [
                // Background image with gradient overlay
                Image.network(
                  widget.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.darkSurface,
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: AppTheme.secondaryText),
                      ),
                    );
                  },
                ),
                // Gradient overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Glassmorphism frosted glass effect at the bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: AppTheme.glassSurface,
                          border: Border(
                            top: BorderSide(
                              color: AppTheme.neonGreen.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Title
                            Text(
                              widget.title,
                              style: AppTheme.textTheme.titleLarge,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Price and Distance Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Price with neon accent
                                Row(
                                  children: [
                                    Text(
                                      widget.price,
                                      style: AppTheme.textTheme.headlineMedium?.copyWith(
                                        color: AppTheme.neonGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'DZD',
                                      style: AppTheme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                // Distance badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neonPurple.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: AppTheme.neonPurple.withOpacity(0.6),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    widget.distance,
                                    style: AppTheme.textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.neonPurple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Swap capability badge
                            if (widget.acceptsSwaps)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppTheme.neonGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_horiz, size: 14, color: AppTheme.neonGreen),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Accepts Swaps',
                                      style: AppTheme.textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.neonGreen,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
