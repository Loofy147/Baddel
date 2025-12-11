import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baddel/core/models/item_model.dart';

class SupabaseService {
  final _client = Supabase.instance.client;

  // 1. GET THE FEED (Fetch Items)
  Future<List<Item>> getFeedItems() async {
    try {
      final response = await _client
          .from('items')
          .select()
          .order('created_at', ascending: false); // Newest first

      final data = response as List<dynamic>;
      return data.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      print('🔴 Error fetching feed: $e');
      return [];
    }
  }

  // 2. UPLOAD IMAGE (To Storage Bucket)
  Future<String?> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      await _client.storage
          .from('baddel_images')
          .upload(path, imageFile);

      // Get the Public URL
      final publicUrl = _client.storage
          .from('baddel_images')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      print('🔴 Error uploading image: $e');
      return null;
    }
  }

  // 3. POST ITEM (Create Listing)
  Future<bool> postItem({
    required String title,
    required int price,
    required String imageUrl,
    required bool acceptsSwaps,
  }) async {
    try {
      // NOTE: In a real app, 'owner_id' comes from Auth.
      // For now, we use the current user if logged in, or a random UUID if not.
      // Ideally, ensure you sign in anonymously at least in main.dart
      final userId = _client.auth.currentUser?.id;

      if (userId == null) {
         print('🔴 User not logged in. Cannot post.');
         return false;
      }

      await _client.from('items').insert({
        'owner_id': userId,
        'title': title,
        'price': price,
        'image_url': imageUrl,
        'accepts_swaps': acceptsSwaps,
        'is_cash_only': !acceptsSwaps,
        // We use a dummy location point for now to satisfy the DB constraint
        // ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
        'location': 'POINT(3.0588 36.7525)', // Alger Centre coordinates
        'status': 'active',
      });
      return true;
    } catch (e) {
      print('🔴 Error posting item: $e');
      return false;
    }
  }
}
