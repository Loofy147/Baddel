import 'package:flutter/material.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _supabaseService = SupabaseService();

  Map<String, dynamic>? _profileData;
  List<Item> _myItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await _supabaseService.getUserProfile();
    final items = await _supabaseService.getMyInventory();

    if (mounted) {
      setState(() {
        _profileData = profile;
        _myItems = items;
        _isLoading = false;
      });
    }
  }

  void _logout() {
    _authService.signOut();
    // In main.dart, Auth state change will handle navigation,
    // but to be safe we push replacement to login:
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final score = _profileData?['reputation_score'] ?? 50;
    final phone = _profileData?['phone'] ?? "No Phone";

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.red), onPressed: _logout)
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. THE HERO CARD (Gamification)
            _buildHeroStats(score, phone),

            const SizedBox(height: 20),

            // 2. MY GARAGE HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("MY ACTIVE GARAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("${_myItems.length} Items", style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. INVENTORY GRID
            _myItems.isEmpty
              ? const Padding(padding: EdgeInsets.all(50), child: Text("Garage Empty", style: TextStyle(color: Colors.grey)))
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(15),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _myItems.length,
                  itemBuilder: (context, index) => _buildManageCard(_myItems[index]),
                ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeroStats(int score, String phone) {
    // Calculate Level based on Score
    String level = "Novice";
    Color color = Colors.grey;
    if (score > 60) { level = "Merchant"; color = Colors.blue; }
    if (score > 80) { level = "Boss"; color = const Color(0xFF00E676); }

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.grey[900]!, Colors.black], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[800]!),
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
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(phone, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                    child: Text(level.toUpperCase(), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const Spacer(),
              Column(
                children: [
                  Text("$score", style: TextStyle(color: color, fontSize: 30, fontWeight: FontWeight.bold)),
                  const Text("REP SCORE", style: TextStyle(color: Colors.grey, fontSize: 10)),
                ],
              )
            ],
          ),
          const SizedBox(height: 20),
          // STATS ROW
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Active", "${_profileData?['active_items'] ?? 0}"),
              _statItem("Sold", "${_profileData?['sold_items'] ?? 0}"),
              _statItem("Deals", "0"), // Placeholder for future deals count
            ],
          )
        ],
      ),
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildManageCard(Item item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(item.imageUrl, fit: BoxFit.cover),
        ),
        // Overlay
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
          ),
        ),
        // Delete Button
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: () async {
              await _supabaseService.deleteItem(item.id);
              _loadData(); // Refresh UI
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.delete, size: 16, color: Colors.white),
            ),
          ),
        ),
        // Text
        Positioned(
          bottom: 10, left: 10,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text("${item.price} DA", style: const TextStyle(color: Color(0xFF00E676), fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}
