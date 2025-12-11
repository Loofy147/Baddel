import 'package:baddel/models/item_model.dart';
import 'package:baddel/screens/upload_item_screen.dart';
import 'package:baddel/widgets/garage_item_card.dart';
import 'package:flutter/material.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
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
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
          childAspectRatio: 0.8,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return GarageItemCard(item: items[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadItemScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
