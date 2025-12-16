import 'package:baddel/core/services/recommendation_service.dart';
import 'package:baddel/ui/screens/chat/offers_screen.dart';
import 'package:baddel/ui/widgets/action_sheet.dart';
import 'package:baddel/ui/widgets/advanced_card_swiper.dart';
import 'package:baddel/ui/widgets/advanced_card_swiper_controller.dart';
import 'package:baddel/ui/screens/garage/upload_screen.dart';
import 'package:baddel/ui/screens/search/search_screen.dart';
import 'package:baddel/ui/widgets/social_sharing_gallery.dart';
import 'package:flutter/material.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/services/logger.dart';
import 'package:geolocator/geolocator.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // Uncomment when DB has data

enum BaddelSwipeDirection { left, right }

class HomeDeckScreen extends StatefulWidget {
  const HomeDeckScreen({super.key});

  @override
  State<HomeDeckScreen> createState() => _HomeDeckScreenState();
}

class _HomeDeckScreenState extends State<HomeDeckScreen> {
  final _recommendationService = RecommendationService();
  final _swiperController = AdvancedCardSwiperController();
  List<Item> _items = [];

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
          });
        }
      }
    } catch (e) {
      Logger.error("GPS Error", e);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
        _loadRecommendations();
      }
    }
  }

  Future<void> _loadRecommendations() async {
    final items = await _recommendationService.getPersonalizedFeed(
      lat: _userLat,
      lng: _userLng,
      limit: 50,
    );
    if (mounted) {
      setState(() => _items = items);
    }
  }

  @override
  void dispose() {
    _recommendationService.dispose();
    super.dispose();
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
                  : _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.layers_clear, size: 60, color: Colors.grey),
                              const SizedBox(height: 10),
                              const Text("No items yet.\nBe the first to upload!",
                                  textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadScreen())),
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                                child: const Text("Be the First to Upload!", style: TextStyle(color: Colors.white)),
                              ),
                              TextButton(
                                onPressed: _loadRecommendations, // Refresh
                                child: const Text("Refresh Deck"),
                              ),
                            ],
                          ),
                        )
                      : AdvancedCardSwiper(
                          controller: _swiperController,
                          cards: _items.map((item) => _buildCard(item)).toList(),
                          onSwipe: (index, direction) {
                            _onSwipe(index,
                                direction == SwipeDirection.right ? BaddelSwipeDirection.right : BaddelSwipeDirection.left);
                          },
                        ),
            ),

            _buildBottomControls(), // Keep bottom controls
          ],
        ),
      ),
    );
  }

  void _onSwipe(int previousIndex, BaddelSwipeDirection direction) {
    final item = _items[previousIndex];

    _recommendationService.recordInteraction(
      item.id,
      direction == BaddelSwipeDirection.right ? InteractionType.swipeRight : InteractionType.swipeLeft,
    );

    if (direction == BaddelSwipeDirection.right) {
      Future.delayed(const Duration(milliseconds: 300), () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => ActionSheet(item: item),
        );
      });
    }
  }

  // --- WIDGETS ---
  Widget _buildCard(Item item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SocialSharingGallery(
              imageUrls: item.imageUrls,
              title: item.title,
              description: 'Price: ${item.price} DZD\nDistance: ${item.distanceDisplay}',
            ),
          ),
        );
      },
      child: SwipeableItemCard(
        imageUrl: item.imageUrl,
        title: item.title,
        price: item.price,
        distance: item.distanceDisplay,
        acceptsSwaps: item.acceptsSwaps,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 48), // Spacer
          Image.network("https://img.icons8.com/color/48/shop.png", height: 30), // LOGO PLACEHOLDER
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EnhancedSearchScreen(
                    userLocation: Position(
                      latitude: _userLat,
                      longitude: _userLng,
                      timestamp: DateTime.now(),
                      accuracy: 0.0,
                      altitude: 0.0,
                      altitudeAccuracy: 0.0,
                      heading: 0.0,
                      headingAccuracy: 0.0,
                      speed: 0.0,
                      speedAccuracy: 0.0,
                    ),
                  ),
                ),
              );
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
          _actionBtn(Icons.close, Colors.red, "Pass", () => _swiperController.swipeLeft()),
          _actionBtn(Icons.bolt, Colors.amber, "Super Like (Coming Soon)", null), // Super Like / Fire Sale
          _actionBtn(Icons.favorite, Colors.green, "Make a Deal", () => _swiperController.swipeRight()),
        ],
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, String tooltip, VoidCallback? onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: onTap != null ? Colors.grey[900] : Colors.grey[900]!.withOpacity(0.5),
              border: Border.all(color: onTap != null ? color : Colors.grey, width: 2),
            ),
            child: Icon(icon, color: onTap != null ? color : Colors.grey, size: 30),
          ),
        ),
      ),
    );
  }
}
