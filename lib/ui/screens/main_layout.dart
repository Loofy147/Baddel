import 'package:flutter/material.dart';
import 'package:baddel/ui/screens/deck/home_deck_screen.dart';
import 'package:baddel/ui/screens/chat/offers_screen.dart';
import 'package:baddel/ui/screens/profile/profile_screen.dart';
import 'package:baddel/features/notifications/notifications_system.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baddel/ui/theme.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDeckScreen(), // 0
    const OffersScreen(),   // 1
    const ProfileScreen(),  // 2
  ];

  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    ref.listen(notificationsProvider, (previous, next) {
      next.when(
        data: (notifications) {
          final unread = notifications.where((n) => !n.isRead).toList();
          if (unread.isNotEmpty) {
            _showInAppNotification(unread.first);
          }
        },
        loading: () {},
        error: (_, __) {},
      );
    });
  }

  void _showInAppNotification(AppNotification notification) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: InAppNotificationBanner(notification: notification),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      // Floating Action Button (The Upload Button)
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.neonGreen,
        tooltip: 'Upload Item',
        child: const Icon(Icons.add, color: AppTheme.deepObsidian),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppTheme.deepObsidian,
        selectedItemColor: AppTheme.neonGreen,
        unselectedItemColor: AppTheme.secondaryText,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: const Icon(Icons.style), label: "Deck"),
          BottomNavigationBarItem(
              icon: const Icon(Icons.chat_bubble), label: "Deals"),
          BottomNavigationBarItem(
              icon: const Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
