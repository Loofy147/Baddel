import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/providers.dart';
import 'package:baddel/core/services/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';

class InventoryCard extends ConsumerWidget {
  final Item item;

  const InventoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDeleteConfirmation(context, item, ref),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: AppTheme.borderRadius,
            child: Image.network(item.imageUrl, fit: BoxFit.cover),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: AppTheme.borderRadius,
              gradient: LinearGradient(
                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                begin: Alignment.bottomCenter,
                end: Alignment.center,
              ),
            ),
          ),
          Positioned(
            top: AppTheme.spacingSmall,
            right: AppTheme.spacingSmall,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
              child: const Icon(Icons.delete, size: 16, color: Colors.white),
            ),
          ),
          Positioned(
            bottom: AppTheme.spacingSmall,
            left: AppTheme.spacingSmall,
            right: AppTheme.spacingSmall,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: AppTheme.textTheme.titleLarge),
                    Text("${item.price} DA", style: AppTheme.textTheme.bodyLarge?.copyWith(color: AppTheme.neonGreen)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.bolt, color: Colors.amber),
                  onPressed: () => _showBoostDialog(context),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showBoostDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkSurface,
        title: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.amber),
            const SizedBox(width: 10),
            Text('Boost Listing', style: AppTheme.textTheme.headlineMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get your item seen by more people!', style: AppTheme.textTheme.bodyMedium),
            const SizedBox(height: 20),
            Text('Choose a boost duration:', style: AppTheme.textTheme.bodyLarge),
            const SizedBox(height: 10),
            const ListTile(
              leading: Icon(Icons.local_fire_department, color: Colors.amber),
              title: Text('24 Hours'),
              subtitle: Text('100 DZD'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const Tooltip(
            message: 'Coming Soon: Payment integration is under development',
            child: ElevatedButton(
              onPressed: null,
              child: Text('Proceed to Payment'),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Item item, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.darkSurface,
          title: Text('Delete Item?', style: AppTheme.textTheme.headlineMedium),
          content: Text('Are you sure you want to delete "${item.title}"? This cannot be undone.', style: AppTheme.textTheme.bodyMedium),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('DELETE', style: TextStyle(color: AppTheme.errorColor)),
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                try {
                  await ref.read(supabaseServiceProvider).deleteItem(item.id);
                  final _ = ref.refresh(myInventoryProvider);
                } on AppException catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("❌ ${e.message}")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
