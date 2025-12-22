import 'package:baddel/core/services/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baddel/features/favorites/favorites_system.dart';
import 'package:baddel/features/notifications/notifications_system.dart';
import 'package:baddel/ui/screens/admin/analytics_dashboard.dart';
import 'package:baddel/ui/screens/seller_dashboard/seller_performance_dashboard_screen.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'widgets/profile_header.dart';
import 'widgets/inventory_grid.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) {
    ref.read(authServiceProvider).signOut();
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsyncValue = ref.watch(userProfileStreamProvider);
    final privateDataAsyncValue = ref.watch(userPrivateDataProvider);
    final inventoryAsyncValue = ref.watch(myInventoryProvider);
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (isAdmin == true)
            IconButton(
              icon: const Icon(Icons.analytics, color: Colors.amber),
              tooltip: 'View Analytics',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AnalyticsDashboard())),
            ),
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.blue),
            tooltip: 'Seller Dashboard',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SellerPerformanceDashboardScreen())),
          ),
          NotificationBadge(
            child: IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white),
              tooltip: 'Notifications',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsScreen())),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.red),
            tooltip: 'My Favorites',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoritesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Logout',
            onPressed: () => _logout(context, ref),
          )
        ],
      ),
      body: profileAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (profileData) => privateDataAsyncValue.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
          data: (privateData) => SingleChildScrollView(
            child: Column(
              children: [
                ProfileHeader(
                  score: profileData?['reputation_score'] ?? 50,
                  phone: privateData?['phone'] ?? "No Phone",
                  profileData: profileData ?? {},
                ),
                inventoryAsyncValue.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (myItems) => myItems.isEmpty ? _buildEmptyGarage(context) : InventoryGrid(items: myItems),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyGarage(BuildContext context) {
    return Container(
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadScreen())),
            child: const Text('Add Your First Item'),
          ),
        ],
      ),
    );
  }
}
