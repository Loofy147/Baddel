import 'package:flutter/material.dart';
import 'package:baddel/ui/screens/deck/home_deck_screen.dart';
import 'package:baddel/ui/screens/chat/offers_screen.dart';
import 'package:baddel/ui/screens/profile/profile_screen.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    final myId = Supabase.instance.client.auth.currentUser?.id;
    if (myId == null) return;

    // LISTEN FOR NEW OFFERS
    Supabase.instance.client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('seller_id', myId)
        .listen((List<Map<String, dynamic>> data) {
           // Basic logic: if a new item appears in the stream that wasn't there before
           // For simplicity in Beta, we just check the latest one timestamp
           // (This is a simplified example. In prod, use Postgres Changes)
           if (data.isNotEmpty) {
             final lastOffer = data.last;
             // Check if it's "New" (created within last 10 seconds)
             final createdAt = DateTime.parse(lastOffer['created_at']);
             if (DateTime.now().difference(createdAt).inSeconds < 10) {
               _showNotification("🔔 New Offer received!");
             }
           }
        });

    // LISTEN FOR NEW MESSAGES
    // (Similar logic for 'messages' table where receiver_id = myId)
    // You'd need to add 'receiver_id' to messages table to query efficiently,
    // or join tables. For now, skipping to keep simple.
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00E676), // Neon Green
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),

      // Floating Action Button (The Upload Button)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2962FF),
        tooltip: 'Upload Item',
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
