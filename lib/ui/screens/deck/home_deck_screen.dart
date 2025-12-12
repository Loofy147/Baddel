import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/ui/screens/chat/offers_screen.dart';
import 'package:baddel/ui/widgets/action_sheet.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Uncomment when DB has data

class HomeDeckScreen extends StatefulWidget {
  const HomeDeckScreen({super.key});

  @override
  State<HomeDeckScreen> createState() => _HomeDeckScreenState();
}

class _HomeDeckScreenState extends State<HomeDeckScreen> {
  final CardSwiperController controller = CardSwiperController();
  final _supabaseService = SupabaseService();

  // Default Algiers location
  double _userLat = 36.7525;
  double _userLng = 3.0588;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      // Basic permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() {
            _userLat = position.latitude;
            _userLng = position.longitude;
            _isLoadingLocation = false;
          });
        }
      } else {
         setState(() => _isLoadingLocation = false); // Use default Algiers
      }
    } catch (e) {
      print("GPS Error: $e");
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(), // Keep your top bar

            // THE REAL DECK FETCHED FROM DB
            Expanded(
              child: _isLoadingLocation
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Item>>(
                    // CALL THE NEW RPC FUNCTION HERE
                    future: _supabaseService.getNearbyItems(lat: _userLat, lng: _userLng, radiusInMeters: 50000),
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
                              const Text("No items yet.\nBe the first to upload!", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
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
        boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
      ),
      alignment: Alignment.bottomLeft,
      child: Container(
        decoration: const BoxDecoration(
          gradient: const LinearGradient(colors: const [Colors.black, Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
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
                Text(
                   " ${item.distanceDisplay} away", // Displays "5.2 km away"
                   style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)
                ),
                if (item.acceptsSwaps) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFBB86FC), borderRadius: BorderRadius.circular(10)),
                    child: const Text("🔄 SWAP OK", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network("https://img.icons8.com/color/48/shop.png", height: 30), // LOGO PLACEHOLDER
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
