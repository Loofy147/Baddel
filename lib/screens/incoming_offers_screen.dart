import 'package:baddel/models/item_model.dart';
import 'package:baddel/services/supabase_service.dart';
import 'package:baddel/widgets/item_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class IncomingOffersScreen extends StatefulWidget {
  const IncomingOffersScreen({Key? key}) : super(key: key);

  @override
  State<IncomingOffersScreen> createState() => _IncomingOffersScreenState();
}

class _IncomingOffersScreenState extends State<IncomingOffersScreen> {
  final CardSwiperController controller = CardSwiperController();
  final SupabaseClient _client = locator<SupabaseService>().client;
  late Future<List<Map<String, dynamic>>> _offersFuture;

  @override
  void initState() {
    super.initState();
    _offersFuture = _fetchIncomingOffers();
  }

  Future<List<Map<String, dynamic>>> _fetchIncomingOffers() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('actions')
        .select('id, offered_item_id, items!inner(*)')
        .eq('items.user_id', userId)
        .eq('type', 'Right_Swap')
        .eq('status', 'Pending');

    return (response as List).map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incoming Swap Offers'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _offersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final offers = snapshot.data!;
            if (offers.isEmpty) {
              return const Center(child: Text('You have no incoming swap offers.'));
            }
            return CardSwiper(
              controller: controller,
              cardsCount: offers.length,
              onSwipe: (previousIndex, currentIndex, direction) =>
                  _onSwipe(previousIndex, currentIndex, direction, offers),
              numberOfCardsDisplayed: 1,
              padding: const EdgeInsets.all(24.0),
              cardBuilder: (
                context,
                index,
                horizontalThresholdPercentage,
                verticalThresholdPercentage,
              ) {
                final itemData = offers[index]['items'];
                final item = Item(
                  id: itemData['id'],
                  title: itemData['title'],
                  price: itemData['price'].toString(),
                  location: 'Oran', // Placeholder
                  imageUrl: itemData['image_url'],
                );
                return ItemCard(item: item);
              },
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
    List<Map<String, dynamic>> offers,
  ) {
    final action = offers[previousIndex];
    if (direction == CardSwiperDirection.right) {
      _acceptOffer(action['id'], action['actor_id'], _client.auth.currentUser!.id);
    } else {
      _rejectOffer(action['id']);
    }
    return true;
  }

  Future<void> _acceptOffer(int actionId, String actorId, String itemOwnerId) async {
    try {
      await _client
          .from('actions')
          .update({'status': 'Accepted'})
          .eq('id', actionId);

      final chatResponse = await _client.from('chats').insert({}).select('id').single();
      final chatId = chatResponse['id'];

      await _client.from('chat_participants').insert([
        {'chat_id': chatId, 'user_id': actorId},
        {'chat_id': chatId, 'user_id': itemOwnerId},
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('It\'s a match! A new chat has been created.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting offer: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectOffer(int actionId) async {
    try {
      await _client
          .from('actions')
          .update({'status': 'Rejected'})
          .eq('id', actionId);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting offer: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
