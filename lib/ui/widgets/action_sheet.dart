import 'package:baddel/core/services/supabase_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Two Modes: Cash (0) and Swap (1)
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
          // 1. DRAG HANDLE
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2)),
          ),

          // 2. HEADER
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
                )
              ],
            ),
          ),

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
          ElevatedButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("💸 Sending Cash Offer...")));

              final success = await service.createOffer(
                targetItemId: widget.item.id,
                sellerId: widget.item.ownerId,
                cashAmount: int.tryParse(_cashController.text) ?? 0,
              );

              if(mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "💸 Cash Offer Sent!" : "❌ Failed to send offer")));
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
    final service = SupabaseService();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Select from your Garage:", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),

          // REAL INVENTORY FETCH
          Expanded( // Changed from SizedBox to Expanded to take available space
            child: FutureBuilder<List<Item>>(
              future: service.getMyInventory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final myItems = snapshot.data!;
                if (myItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.garage, color: Colors.grey, size: 40),
                        const Text("Your Garage is Empty", style: TextStyle(color: Colors.grey)),
                        TextButton(
                          // In a real app, verify navigation stack
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Go Upload First")
                        )
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: myItems.length,
                  itemBuilder: (ctx, index) {
                    final item = myItems[index];
                    final isSelected = _selectedSwapItemId == item.id;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedSwapItemId = item.id),
                      child: Container(
                        width: 140,
                        margin: const EdgeInsets.only(right: 15, bottom: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFBB86FC).withOpacity(0.2) : Colors.grey[900],
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFBB86FC) : Colors.transparent,
                            width: 2
                          ),
                          image: DecorationImage(
                             image: NetworkImage(item.imageUrl),
                             fit: BoxFit.cover,
                             colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.4), BlendMode.darken)
                          )
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          item.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // SEND BUTTON (WIRED TO SUPABASE)
          ElevatedButton(
            onPressed: () async {
              if (_selectedSwapItemId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("⚠️ Select an item to swap")));
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🔄 Sending Proposal...")));

              final success = await service.createOffer(
                targetItemId: widget.item.id,
                sellerId: widget.item.ownerId,
                cashAmount: 0,
                offeredItemId: _selectedSwapItemId
              );

              if(mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success ? "🔄 Swap Proposal Sent!" : "❌ Failed to send offer")));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
            ),
            child: const Text("PROPOSE SWAP", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
