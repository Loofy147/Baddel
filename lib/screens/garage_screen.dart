import 'package:baddel/models/item_model.dart';
import 'package:baddel/screens/upload_item_screen.dart';
import 'package:baddel/services/supabase_service.dart';
import 'package:baddel/widgets/garage_item_card.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GarageScreen extends StatefulWidget {
  const GarageScreen({Key? key}) : super(key: key);

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  late Future<List<Item>> _itemsFuture;
  final SupabaseClient _client = locator<SupabaseService>().client;

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

  void _refreshItems() {
    setState(() {
      _itemsFuture = _fetchItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Garage'),
      ),
      body: FutureBuilder<List<Item>>(
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
            return const Center(child: Text('You have no items in your garage yet.'));
          }
          return GridView.builder(
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UploadItemScreen()),
          );
          _refreshItems();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
