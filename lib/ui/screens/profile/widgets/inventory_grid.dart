import 'package:baddel/core/models/item_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme.dart';
import 'inventory_card.dart';

class InventoryGrid extends ConsumerWidget {
  final List<Item> items;

  const InventoryGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("MY ACTIVE GARAGE", style: AppTheme.textTheme.headlineMedium),
              Text("${items.length} Items", style: AppTheme.textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: AppTheme.spacingMedium,
            mainAxisSpacing: AppTheme.spacingMedium,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => InventoryCard(item: items[index]),
        ),
      ],
    );
  }
}
