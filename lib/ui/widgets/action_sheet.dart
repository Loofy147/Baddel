import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:baddel/core/models/item_model.dart';

class ActionSheet extends StatefulWidget {
  final Item item;
  const ActionSheet({super.key, required this.item});

  @override
  State<ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<ActionSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _cashController = TextEditingController();
  String? _selectedSwapItemId;
  double _hybridCashAmount = 0; // The extra cash added
  bool _isSubmitting = false;

  final SupabaseService _service = SupabaseService();
  late Future<List<Item>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.item.acceptsSwaps ? 2 : 1, vsync: this);
    if (widget.item.acceptsSwaps) {
      _inventoryFuture = _service.getMyInventory();
      _inventoryFuture.then((inventory) {
        if (inventory.isNotEmpty && mounted) {
          setState(() {
            _selectedSwapItemId = inventory.first.id;
          });
        }
      });
    }
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
          // 1. DRAG HANDLE
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),

          // 2. HEADER
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0),
            padding: const EdgeInsets.all(12.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[900]!, Colors.grey[850]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15.0),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(widget.item.imageUrl, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Make an Offer for", style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(
                        widget.item.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text("${widget.item.price} DZD", style: const TextStyle(color: Color(0xFF00E676), fontSize: 14, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. TABS
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

          // 4. TAB VIEWS
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- CASH TAB ---
                _buildCashTab(),

                // --- SWAP TAB ---
                if (widget.item.acceptsSwaps) _buildSwapTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCashTab() {
    final service = SupabaseService();
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
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _cashController,
            builder: (context, value, child) {
              final isValid = (int.tryParse(value.text) ?? 0) > 0;
              return ElevatedButton(
                onPressed: (isValid && !_isSubmitting) ? () async {
                  setState(() => _isSubmitting = true);
                  final success = await service.createOffer(
                    targetItemId: widget.item.id,
                    sellerId: widget.item.ownerId,
                    cashAmount: int.tryParse(_cashController.text) ?? 0,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "💸 Cash Offer Sent!" : "❌ Failed to send offer")));
                  }
                  // No need to reset _isSubmitting as the sheet is dismissed.
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E676),
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text("SEND CASH OFFER", style: TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSwapTab() {
    // Assuming 50,000 DA is max top-up for UI niceness
    final double maxTopUp = widget.item.price * 1.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SELECT ITEM
          const Text("1. Select item from your Garage:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          Expanded(
            flex: 2,
            child: FutureBuilder<List<Item>>(
              future: _inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _emptyGarageWidget();
                }

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
                            border: Border.all(color: isSelected ? const Color(0xFFBB86FC) : Colors.transparent, width: 2),
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(image: NetworkImage(item.imageUrl), fit: BoxFit.cover, colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.5), BlendMode.darken))),
                        child: Center(child: Text(item.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const Divider(color: Colors.grey),

          // 2. THE HYBRID SLIDER (Advanced Feature)
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
            max: 50000, // Hardcoded max for demo, logically should be dynamic
            activeColor: const Color(0xFF00E676),
            inactiveColor: Colors.grey[800],
            divisions: 50, // Steps of 1000 DA
            label: "+ ${_hybridCashAmount.toInt()} DA",
            onChanged: (val) => setState(() => _hybridCashAmount = val),
          ),

          const Spacer(),

          // 3. SUBMIT
          ElevatedButton(
            onPressed: (_selectedSwapItemId != null && !_isSubmitting) ? () async {
              setState(() => _isSubmitting = true);
              await service.createOffer(
                targetItemId: widget.item.id,
                sellerId: widget.item.ownerId,
                cashAmount: _hybridCashAmount.toInt(),
                offeredItemId: _selectedSwapItemId,
              );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Hybrid Offer Sent!")));
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text("SEND PROPOSAL", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _emptyGarageWidget() {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close the sheet first
        Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen()));
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[800]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.grey, size: 30),
              SizedBox(height: 8),
              Text("Empty Garage\nTap to upload an item", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}
