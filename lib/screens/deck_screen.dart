import 'package:baddel/models/item_model.dart';
import 'package:baddel/services/supabase_service.dart';
import 'package:baddel/widgets/action_sheet.dart';
import 'package:baddel/widgets/item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({Key? key}) : super(key: key);

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final CardSwiperController controller = CardSwiperController();
  final SupabaseClient _client = locator<SupabaseService>().client;
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _fetchItems();
  }

  Future<List<Item>> _fetchItems() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('items')
        .select()
        .not('user_id', 'eq', userId)
        .order('created_at', ascending: false);

    final List<Item> items = (response as List).map((data) {
      return Item(
        id: data['id'],
        title: data['title'],
        price: data['price'].toString(),
        location: 'Oran', // Placeholder
        imageUrl: data['image_url'],
      );
    }).toList();

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baddel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Item>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final items = snapshot.data!;
            if (items.isEmpty) {
              return const Center(child: Text('No items available in the deck.'));
            }
            return Column(
              children: [
                Expanded(
                  child: CardSwiper(
                    controller: controller,
                    cardsCount: items.length,
                    onSwipe: (previousIndex, currentIndex, direction) =>
                        _onSwipe(previousIndex, currentIndex, direction, items),
                    onUndo: _onUndo,
                    allowedSwipeDirection: const AllowedSwipeDirection.only(left: true),
                    numberOfCardsDisplayed: 3,
                    backCardOffset: const Offset(40, 40),
                    padding: const EdgeInsets.all(24.0),
                    cardBuilder: (
                      context,
                      index,
                      horizontalThresholdPercentage,
                      verticalThresholdPercentage,
                    ) =>
                        ItemCard(item: items[index]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
    List<Item> items,
  ) {
    if (direction == CardSwiperDirection.right) {
      _showActionSheet(items[previousIndex]);
      return false; // Prevent the card from being dismissed
    }
    debugPrint(
      'The card $previousIndex was swiped to the ${direction.name}. Now the card $currentIndex is on top',
    );
    return true;
  }

  void _showActionSheet(Item item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ActionSheet(item: item);
      },
    );
  }

  bool _onUndo(
    int? previousIndex,
    int currentIndex,
    CardSwiperDirection direction,
  ) {
    debugPrint(
      'The card $currentIndex was undod from the ${direction.name}',
    );
    return true;
  }
}
