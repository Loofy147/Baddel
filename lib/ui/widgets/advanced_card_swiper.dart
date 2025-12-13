// lib/ui/widgets/advanced_card_swiper.dart
import 'package:baddel/ui/widgets/advanced_card_swiper_controller.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AdvancedCardSwiper extends StatefulWidget {
  final List<Widget> cards;
  final AdvancedCardSwiperController? controller;
  final Function(int index, SwipeDirection direction)? onSwipe;
  final Function(int index)? onCardTap;
  final Duration animationDuration;
  final double maxAngle;
  final double threshold;

  const AdvancedCardSwiper({
    super.key,
    required this.cards,
    this.controller,
    this.onSwipe,
    this.onCardTap,
    this.animationDuration = const Duration(milliseconds: 400),
    this.maxAngle = 20,
    this.threshold = 100,
  });

  @override
  State<AdvancedCardSwiper> createState() => _AdvancedCardSwiperState();
}

class _AdvancedCardSwiperState extends State<AdvancedCardSwiper>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  Offset _dragOffset = Offset.zero;
  bool _isDragging = false;
  late AnimationController _swipeAnimationController;
  late Animation<Offset> _swipeAnimation;
  SwipeDirection? _swipeDirection;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(() {
      if (widget.controller?.swipingDirection == SwipingDirection.left) {
        _animateSwipe(SwipeDirection.left);
      } else if (widget.controller?.swipingDirection == SwipingDirection.right) {
        _animateSwipe(SwipeDirection.right);
      }
    });

    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _swipeAnimationController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    setState(() => _isDragging = true);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() => _isDragging = false);

    final velocity = details.velocity.pixelsPerSecond;
    final screenWidth = MediaQuery.of(context).size.width;

    // Determine swipe direction
    if (_dragOffset.dx.abs() > widget.threshold || velocity.dx.abs() > 1000) {
      if (_dragOffset.dx > 0 || velocity.dx > 0) {
        _animateSwipe(SwipeDirection.right);
      } else {
        _animateSwipe(SwipeDirection.left);
      }
    } else {
      // Snap back
      _resetPosition();
    }
  }

  void _animateSwipe(SwipeDirection direction) {
    _swipeDirection = direction;
    final screenWidth = MediaQuery.of(context).size.width;
    final endOffset = direction == SwipeDirection.right
        ? Offset(screenWidth * 1.5, _dragOffset.dy)
        : Offset(-screenWidth * 1.5, _dragOffset.dy);

    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: endOffset,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.easeOut,
    ));

    _swipeAnimationController.forward().then((_) {
      widget.onSwipe?.call(_currentIndex, direction);
      setState(() {
        _currentIndex++;
        _dragOffset = Offset.zero;
        _swipeAnimationController.reset();
      });
    });
  }

  void _resetPosition() {
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _swipeAnimationController,
      curve: Curves.elasticOut,
    ));

    _swipeAnimationController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _swipeAnimationController.reset();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background cards (for depth effect)
        if (_currentIndex + 2 < widget.cards.length)
          _buildBackgroundCard(2),
        if (_currentIndex + 1 < widget.cards.length)
          _buildBackgroundCard(1),

        // Main card
        if (_currentIndex < widget.cards.length)
          _buildMainCard(),

        // Swipe indicators
        if (_isDragging) _buildSwipeIndicators(),
      ],
    );
  }

  Widget _buildMainCard() {
    final offset = _isDragging ? _dragOffset : _swipeAnimation.value;
    final angle = _calculateRotation(offset.dx);
    final opacity = _calculateOpacity(offset.dx);

    return AnimatedBuilder(
      animation: _swipeAnimationController,
      builder: (context, child) {
        return Transform.translate(
          offset: offset,
          child: Transform.rotate(
            angle: angle,
            child: GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onTap: () => widget.onCardTap?.call(_currentIndex),
              child: Opacity(
                opacity: opacity,
                child: _buildCardWithShadow(widget.cards[_currentIndex]),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackgroundCard(int depth) {
    final scale = 1.0 - (depth * 0.05);
    final yOffset = depth * 10.0;

    return Transform.scale(
      scale: scale,
      child: Transform.translate(
        offset: Offset(0, yOffset),
        child: Opacity(
          opacity: 0.5 - (depth * 0.1),
          child: IgnorePointer(
            child: widget.cards[_currentIndex + depth],
          ),
        ),
      ),
    );
  }

  Widget _buildCardWithShadow(Widget card) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 30,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: card,
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (_dragOffset.dx / screenWidth).clamp(-1.0, 1.0);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            // Left indicator (Pass)
            if (progress < 0)
              Positioned(
                top: 100,
                right: 50,
                child: _buildIndicator(
                  icon: Icons.close,
                  color: Colors.red,
                  opacity: progress.abs(),
                  rotation: -math.pi / 6,
                ),
              ),

            // Right indicator (Like)
            if (progress > 0)
              Positioned(
                top: 100,
                left: 50,
                child: _buildIndicator(
                  icon: Icons.favorite,
                  color: Colors.green,
                  opacity: progress,
                  rotation: math.pi / 6,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator({
    required IconData icon,
    required Color color,
    required double opacity,
    required double rotation,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 4),
          borderRadius: BorderRadius.circular(15),
          color: color.withOpacity(0.2),
        ),
        child: Icon(
          icon,
          color: color,
          size: 60,
        ),
      ),
    );
  }

  double _calculateRotation(double dragX) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rotation = (dragX / screenWidth) * widget.maxAngle;
    return rotation * (math.pi / 180);
  }

  double _calculateOpacity(double dragX) {
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = (dragX.abs() / screenWidth).clamp(0.0, 1.0);
    return 1.0 - (progress * 0.3);
  }
}

enum SwipeDirection { left, right }

// Example usage with beautiful card design
class SwipeableItemCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final int price;
  final String distance;
  final bool acceptsSwaps;

  const SwipeableItemCard({
    super.key,
    required this.imageUrl,
    required this.title,
    required this.price,
    required this.distance,
    this.acceptsSwaps = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),

          // Content
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Price
                  Text(
                    '$price DZD',
                    style: const TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[400],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      if (acceptsSwaps) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBB86FC),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'SWAP OK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: 'bold',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Quick actions (top right)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
