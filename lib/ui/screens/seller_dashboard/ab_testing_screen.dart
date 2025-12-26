import 'package:baddel/core/providers.dart';
import 'package:baddel/ui/screens/seller_dashboard/create_ab_test_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ABTestingScreen extends ConsumerWidget {
  const ABTestingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsyncValue = ref.watch(myInventoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('A/B Testing - Select an Item'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: inventoryAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Text('You have no items in your garage to A/B test.'),
            );
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // Using a custom widget for better UI, if available, otherwise ListTile is fine.
              // For now, ListTile is sufficient.
              return ListTile(
                leading: item.imageUrls.isNotEmpty
                    ? Image.network(item.imageUrls.first, width: 56, height: 56, fit: BoxFit.cover)
                    : Container(width: 56, height: 56, color: Colors.grey[800]),
                title: Text(item.title),
                subtitle: const Text('Tap to set up an A/B test'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateABTestScreen(item: item),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
