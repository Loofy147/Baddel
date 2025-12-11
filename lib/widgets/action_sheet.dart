import 'package:baddel/models/item_model.dart';
import 'package:baddel/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActionSheet extends StatefulWidget {
  final Item item;
  const ActionSheet({Key? key, required this.item}) : super(key: key);

  @override
  State<ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<ActionSheet> {
  String _offerAmount = '';
  Item? _selectedSwapItem;
  bool _isLoading = false;
  late Future<List<Item>> _userItemsFuture;
  final SupabaseClient _client = locator<SupabaseService>().client;

  @override
  void initState() {
    super.initState();
    _userItemsFuture = _fetchUserItems();
  }

  Future<List<Item>> _fetchUserItems() async {
    final userId = _client.auth.currentUser!.id;
    final response = await _client
        .from('items')
        .select()
        .eq('user_id', userId)
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

  void _showCashOffer() {
    setState(() {
      _offerAmount = '';
    });
    _showOfferContent((closeSheet) => _buildCashOfferContent(closeSheet));
  }

  void _showSwapOffer() {
    setState(() {
      _selectedSwapItem = null;
    });
    _showOfferContent((closeSheet) => _buildSwapOfferContent(closeSheet));
  }

  void _showOfferContent(Widget Function(VoidCallback) contentBuilder) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: contentBuilder(() => Navigator.pop(context)),
          ),
        );
      },
    );
  }

  Future<void> _sendCashOffer(VoidCallback closeSheet) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final actorId = locator<SupabaseService>().client.auth.currentUser!.id;
      await locator<SupabaseService>().client.from('actions').insert({
        'actor_id': actorId,
        'item_id': widget.item.id,
        'type': 'Right_Cash',
        'offer_value': int.parse(_offerAmount),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash offer sent successfully!')),
        );
        closeSheet(); // Close the numeric pad sheet
        Navigator.pop(context); // Close the main action sheet
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending offer: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendSwapOffer(VoidCallback closeSheet) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final actorId = locator<SupabaseService>().client.auth.currentUser!.id;
      await locator<SupabaseService>().client.from('actions').insert({
        'actor_id': actorId,
        'item_id': widget.item.id,
        'type': 'Right_Swap',
        'offered_item_id': _selectedSwapItem!.id,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Swap offer sent successfully!')),
        );
        closeSheet(); // Close the swap sheet
        Navigator.pop(context); // Close the main action sheet
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending offer: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Text(
            'Make an Offer',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Text('💸', style: TextStyle(fontSize: 24)),
            label: const Text('OFFER CASH (Chri)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              minimumSize: const Size(double.infinity, 50),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: _showCashOffer,
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Text('🔄', style: TextStyle(fontSize: 24)),
            label: const Text('OFFER SWAP (Baddel)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFBB86FC),
              minimumSize: const Size(double.infinity, 50),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: _showSwapOffer,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildCashOfferContent(VoidCallback closeSheet) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Offer for ${widget.item.title}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Text(
          '${_offerAmount.isEmpty ? '0' : _offerAmount} DA',
          style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
        ),
        const SizedBox(height: 16),
        // Simple numeric pad
        ...[
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['', '0', '<']
        ].map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) return const SizedBox(width: 64);
              return TextButton(
                onPressed: () {
                  setState(() {
                    if (key == '<') {
                      if (_offerAmount.isNotEmpty) {
                        _offerAmount = _offerAmount.substring(0, _offerAmount.length - 1);
                      }
                    } else {
                      _offerAmount += key;
                    }
                  });
                },
                child: Text(key, style: const TextStyle(fontSize: 24)),
              );
            }).toList(),
          );
        }).toList(),
        const SizedBox(height: 20),
        _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: () => _sendCashOffer(closeSheet),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text('Send Offer'),
              ),
      ],
    );
  }

  Widget _buildSwapOfferContent(VoidCallback closeSheet) {
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select an item to swap',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 150,
              child: FutureBuilder<List<Item>>(
                future: _userItemsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final userItems = snapshot.data!;
                  if (userItems.isEmpty) {
                    return const Center(child: Text('You have no items to swap.'));
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: userItems.length,
                    itemBuilder: (context, index) {
                      final item = userItems[index];
                      final isSelected = _selectedSwapItem?.id == item.id;
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            _selectedSwapItem = item;
                          });
                        },
                        child: Card(
                          color: isSelected ? Colors.blue.withOpacity(0.5) : null,
                          child: Container(
                            width: 120,
                            child: Column(
                              children: [
                                Expanded(child: Image.network(item.imageUrl, fit: BoxFit.cover)),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(item.title, overflow: TextOverflow.ellipsis),
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _selectedSwapItem == null ? null : () => _sendSwapOffer(closeSheet),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Send Swap Offer'),
                  ),
          ],
        );
      },
    );
  }
}
