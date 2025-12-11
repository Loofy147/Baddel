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

  // 🧪 MOCK DATA (Until you have real data in Supabase)
  List<Item> items = [
    Item(id: '1', title: 'PlayStation 5', price: 65000, imageUrl: 'https://images.unsplash.com/photo-1606144042614-b2417e99c4e3', acceptsSwaps: true, locationName: 'El Biar'),
    Item(id: '2', title: 'Clio 4 GT Line', price: 2800000, imageUrl: 'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2', acceptsSwaps: false, locationName: 'Oran'),
    Item(id: '3', title: 'iPhone 13 Pro', price: 95000, imageUrl: 'https://images.unsplash.com/photo-1632661674596-df8be070a5c5', acceptsSwaps: true, locationName: 'Setif'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP BAR
            _buildTopBar(),

            // 2. THE DECK
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: items.length,
                onSwipe: _onSwipe,
                cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                  return _buildCard(items[index]);
                },
              ),
            ),

            // 3. ACTION BUTTONS
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // --- LOGIC ---
  bool _onSwipe(int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    if (direction == CardSwiperDirection.right) {
      // 1. Show Visual Feedback
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Opening Negotiation..."),
        duration: Duration(milliseconds: 500)
      ));

      // 2. Open the Cockpit
      Future.delayed(const Duration(milliseconds: 300), () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true, // Allows full height
          backgroundColor: Colors.transparent,
          builder: (context) => ActionSheet(item: items[previousIndex]),
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
          const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 30),
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
