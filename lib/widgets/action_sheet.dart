import 'package:baddel/models/item_model.dart';
import 'package:flutter/material.dart';

class ActionSheet extends StatefulWidget {
  final Item item;
  const ActionSheet({Key? key, required this.item}) : super(key: key);

  @override
  State<ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<ActionSheet> {
  String _offerAmount = '';
  Item? _selectedSwapItem;

  // Placeholder for user's items in their "Garage"
  final List<Item> _userItems = [
    Item(id: 'g1', title: 'Old Gaming Mouse', price: '3000', location: 'Oran', imageUrl: 'https://i.ibb.co/683gR2Q/ps5.webp'),
    Item(id: 'g2', title: 'Used Headphones', price: '5000', location: 'Oran', imageUrl: 'https://i.ibb.co/FbfV5r3/iphone13.webp'),
    Item(id: 'g3', title: 'Classic Watch', price: '12000', location: 'Oran', imageUrl: 'https://i.ibb.co/k2GzT2d/gamingpc.webp'),
  ];

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
        ElevatedButton(
          onPressed: () {
            // TODO: Logic to send cash offer
            print('Cash offer sent: $_offerAmount DA');
            closeSheet(); // Close the numeric pad sheet
            Navigator.pop(context); // Close the main action sheet
          },
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
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _userItems.length,
                itemBuilder: (context, index) {
                  final item = _userItems[index];
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
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectedSwapItem == null ? null : () {
                // TODO: Logic to send swap offer
                print('Swap offer sent with: ${_selectedSwapItem!.title}');
                closeSheet(); // Close the swap sheet
                Navigator.pop(context); // Close the main action sheet
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('Send Swap Offer'),
            ),
          ],
        );
      }
    );
  }
}
