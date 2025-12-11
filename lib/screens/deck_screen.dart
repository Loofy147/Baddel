import 'package:baddel/models/item_model.dart';
import 'package:baddel/widgets/action_sheet.dart';
import 'package:baddel/widgets/item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';

class DeckScreen extends StatefulWidget {
  const DeckScreen({Key? key}) : super(key: key);

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final CardSwiperController controller = CardSwiperController();

  final List<Item> items = [
    Item(
      id: '1',
      title: 'PlayStation 5',
      price: '85,000',
      location: 'Oran',
      imageUrl: 'https://i.ibb.co/683gR2Q/ps5.webp',
    ),
    Item(
      id: '2',
      title: 'iPhone 13 Pro',
      price: '150,000',
      location: 'Algiers',
      imageUrl: 'https://i.ibb.co/FbfV5r3/iphone13.webp',
    ),
    Item(
      id: '3',
      title: 'Gaming PC',
      price: '250,000',
      location: 'Constantine',
      imageUrl: 'https://i.ibb.co/k2GzT2d/gamingpc.webp',
    ),
  ];

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
        child: Column(
          children: [
            Expanded(
              child: CardSwiper(
                controller: controller,
                cardsCount: items.length,
                onSwipe: _onSwipe,
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
        ),
      ),
    );
  }

  bool _onSwipe(
    int previousIndex,
    int? currentIndex,
    CardSwiperDirection direction,
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
