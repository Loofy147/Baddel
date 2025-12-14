import 'package:baddel/core/services/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baddel/ui/screens/admin/analytics_dashboard.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authServiceProvider).signOut();
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _supabaseService = SupabaseService();

  Map<String, dynamic>? _profileData;
  List<Item> _myItems = [];
  bool _isLoading = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final profile = await _supabaseService.getUserProfile();
      final items = await _supabaseService.getMyInventory();
      final isAdmin = await _supabaseService.isAdmin();

      if (mounted) {
        setState(() {
          _profileData = profile;
          _myItems = items;
          _isAdmin = isAdmin;
        });
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${e.message}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _logout() {
    _authService.signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(userProfileProvider);
    final inventoryAsyncValue = ref.watch(myInventoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
          )
        ],
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profileData) {
          final score = profileData?['reputation_score'] ?? 50;
          final phone = profileData?['phone'] ?? "No Phone";

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeroStats(score, phone, profileData),
                const SizedBox(height: 20),
                inventoryAsyncValue.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (myItems) => Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("MY ACTIVE GARAGE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            Text("${myItems.length} Items", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      myItems.isEmpty
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
                              itemCount: myItems.length,
                              itemBuilder: (context, index) => _buildManageCard(myItems[index], ref),
                            ),
                    ],
          if (_isAdmin)
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.amber),
              tooltip: 'View Analytics',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalyticsDashboard()),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroStats(score, phone),
            const SizedBox(height: 20),
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
            _myItems.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(vertical: 50),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.car_repair_outlined, color: Colors.grey, size: 60),
                      const SizedBox(height: 10),
                      const Text("Your garage is empty.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2962FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const UploadScreen()),
                          );
                        },
                        child: const Text('Add Your First Item'),
                      ),
                    ],
                  ),
                )
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
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeroStats(int score, String phone, Map<String, dynamic>? profileData) {
    // Calculate Level based on Score
  Widget _buildHeroStats(int score, String phone) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("Active", "${profileData?['active_items'] ?? 0}"),
              _statItem("Sold", "${profileData?['sold_items'] ?? 0}"),
              _statItem("Deals", "0"), // Placeholder for future deals count
              _statItem("Active", "${_profileData?['active_items'] ?? 0}"),
              _statItem("Sold", "${_profileData?['sold_items'] ?? 0}"),
              _statItem("Deals", "0"),
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

  Widget _buildManageCard(Item item, WidgetRef ref) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(item.imageUrl, fit: BoxFit.cover),
        ),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            gradient: const LinearGradient(colors: [Colors.black87, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.center),
          ),
        ),
        Positioned(
          top: 5, right: 5,
          child: GestureDetector(
            onTap: () => _showDeleteConfirmation(item),
            onTap: () async {
              await ref.read(supabaseServiceProvider).deleteItem(item.id);
              ref.refresh(myInventoryProvider);
              try {
                await _supabaseService.deleteItem(item.id);
                _loadData();
              } on AppException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ ${e.message}")),
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.delete, size: 16, color: Colors.white),
            ),
          ),
        ),
        Positioned(
          bottom: 10, left: 10, right: 10,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("${item.price} DA", style: const TextStyle(color: Color(0xFF00E676), fontSize: 12)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.bolt, color: Colors.amber),
                onPressed: () => _showBoostDialog(item),
              ),
            ],
          ),
        )
      ],
    );
  }

  void _showDeleteConfirmation(Item item) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Delete Item?', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete "${item.title}"? This cannot be undone.', style: const TextStyle(color: Colors.grey)),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
              onPressed: () => Navigator.of(dialogContext).pop(), // Close the dialog
            ),
            TextButton(
              child: const Text('DELETE', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog

                // --- OPTIMISTIC UI UPDATE ---
                final itemIndex = _myItems.indexWhere((i) => i.id == item.id);
                if (itemIndex == -1) return; // Should not happen

                setState(() {
                  _myItems.removeAt(itemIndex);
                });

                // Background deletion and error handling
                _supabaseService.deleteItem(item.id).then((success) {
                  if (!success && mounted) {
                    // IF DELETION FAILS, RE-INSERT ITEM AND SHOW ERROR
                    setState(() {
                      _myItems.insert(itemIndex, item);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Error deleting "${item.title}". Please try again.'),
                      ),
                    );
                  }
                });
              },
            ),
          ],
        );
      },
  void _showBoostDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber),
            const SizedBox(width: 10),
            const Text('Boost Listing', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get your item seen by more people!', style: TextStyle(color: Colors.grey[400])),
            const SizedBox(height: 20),
            const Text('Choose a boost duration:', style: TextStyle(color: Colors.white)),
            const SizedBox(height: 10),
            // Placeholder options
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.amber),
              title: const Text('24 Hours', style: TextStyle(color: Colors.white)),
              subtitle: Text('100 DZD', style: TextStyle(color: Colors.grey[400])),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.amber),
              title: const Text('3 Days', style: TextStyle(color: Colors.white)),
              subtitle: Text('250 DZD', style: TextStyle(color: Colors.grey[400])),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department, color: Colors.amber),
              title: const Text('7 Days', style: TextStyle(color: Colors.white)),
              subtitle: Text('500 DZD', style: TextStyle(color: Colors.grey[400])),
              onTap: () {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          Tooltip(
            message: 'Coming Soon: Payment integration is under development',
            child: ElevatedButton(
              onPressed: null, // Disabled
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
              child: const Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }
}
