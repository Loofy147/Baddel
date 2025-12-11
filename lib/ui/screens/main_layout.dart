import 'package:flutter/material.dart';
import 'package:baddel/ui/screens/deck/home_deck_screen.dart';
import 'package:baddel/ui/screens/chat/offers_screen.dart';
import 'package:baddel/ui/screens/profile/profile_screen.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeDeckScreen(), // 0
    const OffersScreen(),   // 1
    const ProfileScreen(),  // 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      // Floating Action Button (The Upload Button)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2962FF),
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFF2962FF),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style), label: "Deck"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: "Deals"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
