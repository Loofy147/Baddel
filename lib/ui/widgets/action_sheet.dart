import 'package.baddel/core/providers.dart';
import 'package:baddel/core/services/auth_service.dart';
import 'package:baddel/core/services/error_handler.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActionSheet extends ConsumerStatefulWidget {
  final Item item;
  const ActionSheet({super.key, required this.item});

  @override
  ConsumerState<ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends ConsumerState<ActionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashController = TextEditingController();
  String? _selectedSwapItemId;
  double _hybridCashAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.item.acceptsSwaps ? 2 : 1, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(widget.item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Make an Offer for", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(widget.item.title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("${widget.item.price} DZD", style: const TextStyle(color: Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.flag, color: Colors.grey),
                  onPressed: () => _showReportDialog(context),
                  tooltip: 'Report Item',
                  icon: const Icon(Icons.flag, color: Colors.red),
                  onPressed: () => _showReportDialog(),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            indicatorColor: const Color(0xFF2962FF),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
            tabs: [
              const Tab(text: "💸 OFFER CASH"),
              if (widget.item.acceptsSwaps) const Tab(text: "🔄 SWAP ITEM"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCashTab(),
                if (widget.item.acceptsSwaps) _buildSwapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashTab() {
    final service = ref.read(supabaseServiceProvider);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text("Enter your price (DZD)", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: "${widget.item.price}",
              hintStyle: TextStyle(color: Colors.grey.withOpacity(0.3)),
              border: InputBorder.none,
              prefixText: "DA  ",
              prefixStyle: const TextStyle(color: Color(0xFF00E676), fontSize: 30),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💸 Sending Cash Offer...")));

                await service.createOffer(
                  targetItemId: widget.item.id,
                  sellerId: widget.item.ownerId,
                  cashAmount: int.tryParse(_cashController.text) ?? 0,
                );

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💸 Cash Offer Sent!")));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send offer: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("SEND CASH OFFER", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildSwapTab() {
    final service = ref.read(supabaseServiceProvider);
    final myInventoryAsyncValue = ref.watch(myInventoryProvider);
    // Assuming 50,000 DA is max top-up for UI niceness
    final service = SupabaseService();
    final double maxTopUp = widget.item.price * 1.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("1. Select item from your Garage:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: myInventoryAsyncValue.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (myItems) {
                if (myItems.isEmpty) return _emptyGarageWidget();
            child: FutureBuilder<List<Item>>(
              future: service.getMyInventory(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) return _emptyGarageWidget();

                final myItems = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: myItems.length,
                  itemBuilder: (ctx, index) {
                    final item = myItems[index];
                    final isSelected = _selectedSwapItemId == item.id;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSwapItemId = item.id),
                      child: Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFBB86FC).withOpacity(0.2) : Colors.grey[900],
                          border: Border.all(
                            color: isSelected ? const Color(0xFFBB86FC) : Colors.transparent,
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(10),
                          image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken))
                        ),
                        child: Center(child: Text(item.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("2. Add Cash Top-up?", style: TextStyle(color: Colors.grey)),
              Text("+ ${_hybridCashAmount.toInt()} DZD", style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          Slider(
            value: _hybridCashAmount,
            min: 0,
            max: 50000,
            activeColor: const Color(0xFF00E676),
            inactiveColor: Colors.grey[800],
            divisions: 50,
            label: "+ ${_hybridCashAmount.toInt()} DA",
            onChanged: (val) => setState(() => _hybridCashAmount = val),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () async {
              if (_selectedSwapItemId == null) return; // Validation

              await ref.read(supabaseServiceProvider).createOffer(
                targetItemId: widget.item.id,
                sellerId: widget.item.ownerId,
                cashAmount: _hybridCashAmount.toInt(), // Pass the hybrid cash
                offeredItemId: _selectedSwapItemId
              );
              if(mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Hybrid Offer Sent!")));
              try {
                await service.createOffer(
                  targetItemId: widget.item.id,
                  sellerId: widget.item.ownerId,
                  cashAmount: _hybridCashAmount.toInt(), // Pass the hybrid cash
                  offeredItemId: _selectedSwapItemId,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Hybrid Offer Sent!")));
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to send offer: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("SEND PROPOSAL", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _emptyGarageWidget() {
    return Container(
       width: double.infinity,
       decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(10)),
       child: const Center(child: Text("Empty Garage. Upload items first!", style: TextStyle(color: Colors.grey)))
    );
  }

  void _showReportDialog(BuildContext context) {
    String? selectedReason;
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2C),
          title: const Text('Report Item', style: TextStyle(color: Colors.white)),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    const Text('Why are you reporting this item?', style: TextStyle(color: Colors.grey)),
                    ...['spam', 'inappropriate', 'fraud', 'other'].map((String reason) {
                      return RadioListTile<String>(
                        title: Text(reason, style: const TextStyle(color: Colors.white)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (String? value) {
                          setState(() {
                            selectedReason = value;
                          });
                        },
                        activeColor: const Color(0xFFBB86FC),
                      );
                    }),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Optional notes...',
                        hintStyle: TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (selectedReason != null) {
                  try {
                    await ref.read(supabaseServiceProvider).reportItem(
                      itemId: widget.item.id,
                      reason: selectedReason!,
                      notes: notesController.text.isNotEmpty ? notesController.text : null,
                    );
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ Report submitted. Thank you!')),
                    );
                  } catch (e) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ Error: ${e.toString()}')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
  void _showReportDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Report Item', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter reason for reporting',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) return;
              final service = SupabaseService();
              try {
                await service.reportItem(widget.item.id, reasonController.text.trim());
                if (mounted) {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close action sheet
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Report submitted. Thank you for your feedback.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit report: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }
}
