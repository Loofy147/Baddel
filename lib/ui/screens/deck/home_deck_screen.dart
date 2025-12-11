import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/ui/screens/chat/offers_screen.dart';
import 'package:baddel/ui/widgets/action_sheet.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:baddel/core/models/item_model.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Uncomment when DB has data

class HomeDeckScreen extends StatefulWidget {
  const HomeDeckScreen({super.key});

  @override
  State<HomeDeckScreen> createState() => _HomeDeckScreenState();
}

class _HomeDeckScreenState extends State<HomeDeckScreen> {
  final CardSwiperController controller = CardSwiperController();
  final _supabaseService = SupabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(), // Keep your top bar

            // THE REAL DECK FETCHED FROM DB
            Expanded(
              child: FutureBuilder<List<Item>>(
                future: _supabaseService.getFeedItems(),
                builder: (context, snapshot) {
                  // 1. LOADING STATE
                  if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)));
                  }

                  // 2. ERROR OR EMPTY
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.layers_clear, size: 60, color: Colors.grey),
                          const SizedBox(height: 10),
                          const Text("No items yet.\nBe the first to upload!", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 20),
                          ElevatedButton(
                             onPressed: () => setState(() {}), // Refresh
                             child: const Text("Refresh Deck")
                          )
                        ],
                      ),
                    );
                  }

                  // 3. REAL DATA
                  final realItems = snapshot.data!;
                  return CardSwiper(
                    controller: controller,
                    cardsCount: realItems.length,
                    onSwipe: (prev, curr, dir) => _onSwipe(prev, curr, dir, realItems), // Note: we pass list here
                    cardBuilder: (context, index, x, y) {
                      return _buildCard(realItems[index]);
                    },
                  );
                },
              ),
            ),

            _buildBottomControls(), // Keep bottom controls
          ],
        ),
      ),
    );
  }

  // NOTE: Update _onSwipe signature to accept the List<Item> so it knows which item was swiped
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction, List<Item> realItems) {
     if (direction == CardSwiperDirection.right) {
        // ... use realItems[previousIndex] instead of global items variable ...
        Future.delayed(const Duration(milliseconds: 300), () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => ActionSheet(item: realItems[previousIndex]),
            );
        });
     }
     return true;
  }

  // --- WIDGETS ---
  Widget _buildCard(Item item) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(item.imageUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
      ),
      alignment: Alignment.bottomLeft,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Colors.black, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text("${item.price} DZD", style: const TextStyle(color: Color(0xFF00E676), fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.grey, size: 16),
                Text(" ${item.locationName}", style: const TextStyle(color: Colors.grey)),
                if (item.acceptsSwaps) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFBB86FC), borderRadius: BorderRadius.circular(10)),
                    child: const Text("🔄 SWAP OK", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  )
                ]
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.add_box, color: Colors.white, size: 30),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (context) => const UploadScreen()));
            },
          ),
          Image.network("https://img.icons8.com/color/48/shop.png", height: 30), // LOGO PLACEHOLDER
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 30),
            onPressed: () {
               // Navigate to Offers
               Navigator.push(context, MaterialPageRoute(builder: (context) => const OffersScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionBtn(Icons.close, Colors.red, () => controller.swipe(CardSwiperDirection.left)),
          _actionBtn(Icons.bolt, Colors.amber, () {}), // Super Like / Fire Sale
          _actionBtn(Icons.favorite, Colors.green, () => controller.swipe(CardSwiperDirection.right)),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60, height: 60,
        decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey[900], border: Border.all(color: color, width: 2)),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}
