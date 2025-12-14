// lib/ui/screens/onboarding/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  late AnimationController _buttonController;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: Icons.swipe,
      title: 'Swipe Smart',
      description: 'Discover items around you with a simple swipe. Like dating, but for shopping.',
      color: Color(0xFF2962FF),
      gradient: [Color(0xFF2962FF), Color(0xFF1976D2)],
    ),
    OnboardingPage(
      icon: Icons.swap_horiz,
      title: 'Swap or Buy',
      description: 'Trade your items or add cash. The most flexible marketplace in Algeria.',
      color: Color(0xFFBB86FC),
      gradient: [Color(0xFFBB86FC), Color(0xFF9C27B0)],
    ),
    OnboardingPage(
      icon: Icons.chat_bubble,
      title: 'Deal Safe',
      description: 'Chat, negotiate, and meet. Built-in trust system protects both sides.',
      color: Color(0xFF00E676),
      gradient: [Color(0xFF00E676), Color(0xFF00C853)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _animationController.reset();
    _animationController.forward();

    if (page == _pages.length - 1) {
      _buttonController.forward();
    } else {
      _buttonController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated Background
          _buildAnimatedBackground(),

          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index);
            },
          ),

          // Page Indicators
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: _buildPageIndicators(),
          ),

          // Action Button
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: _buildActionButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: BackgroundPainter(
            animation: _animationController,
            color: _pages[_currentPage].color,
          ),
          child: Container(),
        );
      },
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    final offset = (_currentPage - index).clamp(-1.0, 1.0);

    return FadeTransition(
      opacity: _animationController,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0.3, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100),

              // Animated Icon
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 600),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Transform.rotate(
                      angle: (1 - value) * math.pi * 2,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: page.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: page.color.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          page.icon,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 60),

              // Title
              Text(
                page.title,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // Description
              Text(
                page.description,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 30 : 10,
          height: 10,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? _pages[_currentPage].color
                : Colors.grey[800],
            borderRadius: BorderRadius.circular(5),
          ),
        );
      }),
    );
  }

  Widget _buildActionButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: () {
              if (_currentPage == _pages.length - 1) {
                // Navigate to login
                Navigator.pushReplacementNamed(context, '/login');
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _pages[_currentPage].color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 8,
              shadowColor: _pages[_currentPage].color.withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentPage == _pages.length - 1 ? "LET'S START" : "NEXT",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  _currentPage == _pages.length - 1
                      ? Icons.rocket_launch
                      : Icons.arrow_forward,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Data Model
class OnboardingPage {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final List<Color> gradient;

  OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.gradient,
  });
}

// Custom Background Painter
class BackgroundPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;

  BackgroundPainter({required this.animation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    // Draw animated circles
    for (int i = 0; i < 3; i++) {
      final radius = size.width * (0.3 + i * 0.2) * animation.value;
      final offset = Offset(
        size.width * (0.3 + i * 0.15),
        size.height * (0.2 + i * 0.2),
      );
      canvas.drawCircle(offset, radius, paint);
    }

    // Draw animated waves
    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width / 2;

    path.moveTo(0, size.height * 0.7);

    for (double i = 0; i < size.width; i++) {
      path.lineTo(
        i,
        size.height * 0.7 +
          math.sin((i / waveLength + animation.value * 2) * math.pi * 2) * waveHeight,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}
