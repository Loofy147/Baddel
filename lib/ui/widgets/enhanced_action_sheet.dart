import 'package:flutter/material.dart';
import 'package:baddel/ui/theme.dart';
import 'package:baddel/core/models/item_model.dart';
import 'dart:ui' as ui;

/// An enhanced action sheet for making trade and cash offers with a premium glassmorphism design.
class EnhancedActionSheet extends StatefulWidget {
  final Item item;
  final Function(double cashAmount) onCashOfferSubmit;
  final Function(Item swapItem, double? cashTopUp) onHybridOfferSubmit;
  final List<Item> userInventory;

  const EnhancedActionSheet({
    Key? key,
    required this.item,
    required this.onCashOfferSubmit,
    required this.onHybridOfferSubmit,
    required this.userInventory,
  }) : super(key: key);

  @override
  State<EnhancedActionSheet> createState() => _EnhancedActionSheetState();
}

class _EnhancedActionSheetState extends State<EnhancedActionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  double _cashAmount = 0;
  Item? _selectedSwapItem;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.glassSurface,
            border: Border(
              top: BorderSide(
                color: AppTheme.neonGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryText.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Make an Offer',
                        style: AppTheme.textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'for ${widget.item.title}',
                        style: AppTheme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                // Tab bar
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: AppTheme.borderColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: AppTheme.neonGreen,
                    indicatorWeight: 3,
                    labelColor: AppTheme.neonGreen,
                    unselectedLabelColor: AppTheme.secondaryText,
                    tabs: const [
                      Tab(text: 'Cash'),
                      Tab(text: 'Swap'),
                      Tab(text: 'Hybrid'),
                    ],
                  ),
                ),
                // Tab content
                SizedBox(
                  height: 300,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCashOfferTab(),
                      _buildSwapOfferTab(),
                      _buildHybridOfferTab(),
                    ],
                  ),
                ),
                // Submit button
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOffer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonGreen,
                      foregroundColor: AppTheme.deepObsidian,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.borderRadius,
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.deepObsidian),
                            ),
                          )
                        : Text(
                            'SEND OFFER',
                            style: AppTheme.textTheme.labelLarge,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCashOfferTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Offer Amount',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '${_cashAmount.toStringAsFixed(0)} DZD',
            style: AppTheme.textTheme.displayLarge?.copyWith(
              color: AppTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 24),
          Slider(
            value: _cashAmount,
            min: 0,
            max: 500000,
            divisions: 100,
            activeColor: AppTheme.neonGreen,
            inactiveColor: AppTheme.borderColor,
            onChanged: (value) {
              setState(() => _cashAmount = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwapOfferTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: widget.userInventory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.secondaryText),
                  const SizedBox(height: 12),
                  Text(
                    'Your garage is empty',
                    style: AppTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: widget.userInventory.length,
              itemBuilder: (context, index) {
                final item = widget.userInventory[index];
                final isSelected = _selectedSwapItem?.id == item.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSwapItem = item);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppTheme.neonGreen : AppTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: AppTheme.borderRadius,
                      color: isSelected
                          ? AppTheme.neonGreen.withOpacity(0.1)
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.darkSurface,
                          ),
                          child: const Icon(Icons.image, color: AppTheme.secondaryText),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: AppTheme.textTheme.bodyLarge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.price} DZD',
                                style: AppTheme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.neonGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppTheme.neonGreen),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHybridOfferTab() {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        children: [
          Text(
            'Select an item + add cash',
            style: AppTheme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSwapOfferTab(),
          ),
          const SizedBox(height: 16),
          Text(
            'Additional Cash: ${_cashAmount.toStringAsFixed(0)} DZD',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.neonPurple,
            ),
          ),
          const SizedBox(height: 12),
          Slider(
            value: _cashAmount,
            min: 0,
            max: 100000,
            divisions: 50,
            activeColor: AppTheme.neonPurple,
            inactiveColor: AppTheme.borderColor,
            onChanged: (value) {
              setState(() => _cashAmount = value);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _submitOffer() async {
    setState(() => _isSubmitting = true);
    try {
      final tabIndex = _tabController.index;
      if (tabIndex == 0) {
        // Cash offer
        await widget.onCashOfferSubmit(_cashAmount);
      } else if (tabIndex == 1) {
        // Swap offer
        if (_selectedSwapItem != null) {
          await widget.onHybridOfferSubmit(_selectedSwapItem!, null);
        }
      } else {
        // Hybrid offer
        if (_selectedSwapItem != null) {
          await widget.onHybridOfferSubmit(_selectedSwapItem!, _cashAmount);
        }
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Offer sent successfully!'),
            backgroundColor: AppTheme.neonGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.vividRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
