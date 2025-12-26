import 'package:baddel/core/services/error_handler.dart';
import 'package:baddel/ui/screens/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baddel/core/providers.dart';

class OffersScreen extends ConsumerWidget {
  const OffersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(supabaseServiceProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text("My Deals"), backgroundColor: Colors.black),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: service.getOffersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No Active Deals", style: TextStyle(color: Colors.grey)));
          }

          final offers = snapshot.data!;

          return ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isCash = offer['type'] == 'cash_only';

              return GestureDetector(
                onTap: () async {
                  if (offer['status'] == 'pending') {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Accept Deal?"),
                        content: const Text("Once accepted, you can chat with the other party."),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                          TextButton(
                            onPressed: () async {
                              try {
                                Navigator.pop(ctx);
                                await service.acceptOffer(offer['id']);
                              } on AppException catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("❌ ${e.message}")),
                                );
                              }
                            },
                            child: const Text("ACCEPT", style: TextStyle(color: Colors.green))
                          )
                        ],
                      )
                    );
                  } else if (offer['status'] == 'accepted') {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => ChatScreen(offerId: offer['id'], otherUserName: "Trader")
                    ));
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCash ? const Color(0xFF00E676).withOpacity(0.2) : const Color(0xFFBB86FC).withOpacity(0.2),
                        ),
                        child: Icon(
                          isCash ? Icons.attach_money : Icons.swap_horiz,
                          color: isCash ? const Color(0xFF00E676) : const Color(0xFFBB86FC),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isCash ? "Cash Offer Received" : "Swap Proposal",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              isCash ? "${offer['cash_amount']} DZD" : "Item Swap Requested",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(5)
                        ),
                        child: Text(
                          (offer['status'] as String).toUpperCase(),
                          style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
