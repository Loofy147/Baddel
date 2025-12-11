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

  // 3. POST ITEM (Create Listing) with GEOLOCATION
  Future<bool> postItem({
    required String title,
    required int price,
    required String imageUrl,
    required bool acceptsSwaps,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        print('🔴 User not logged in. Cannot post.');
        return false;
      }

      // Default to Algiers (Monument des Martyrs) if GPS failed or permission denied
      // WKT Format: POINT(LONGITUDE LATITUDE) - Space separated
      final lat = latitude ?? 36.7525;
      final lng = longitude ?? 3.0588;
      final locationString = 'POINT($lng $lat)';

      await _client.from('items').insert({
        'owner_id': userId,
        'title': title,
        'price': price,
        'image_url': imageUrl,
        'accepts_swaps': acceptsSwaps,
        'is_cash_only': !acceptsSwaps,
        'location': locationString, // <--- Sent as WKT String, PostGIS parses this automatically
        'status': 'active',
      });
      return true;
    } catch (e) {
      print('🔴 Error posting item: $e');
      return false;
    }
  }

  // 4. GET MY GARAGE (Items owned by current user)
  Future<List<Item>> getMyInventory() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('items')
          .select()
          .eq('owner_id', userId) // ONLY MY ITEMS
          .eq('status', 'active');

      return (response as List).map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      print('🔴 Error fetching inventory: $e');
      return [];
    }
  }

  // 5. SEND AN OFFER (The "Deal" logic)
  Future<bool> createOffer({
    required String targetItemId,
    required String sellerId,
    required int cashAmount,
    String? offeredItemId, // Nullable (if Cash Only)
  }) async {
    try {
      final myId = _client.auth.currentUser?.id;
      if (myId == null) return false;

      // Determine the Offer Type
      String type = 'cash_only';
      if (offeredItemId != null && cashAmount > 0) type = 'hybrid';
      if (offeredItemId != null && cashAmount == 0) type = 'swap_pure';

      await _client.from('offers').insert({
        'buyer_id': myId,
        'seller_id': sellerId,
        'target_item_id': targetItemId,
        'offered_item_id': offeredItemId,
        'cash_amount': cashAmount,
        'type': type,
        'status': 'pending',
      });

      return true;
    } catch (e) {
      print('🔴 Error creating offer: $e');
      return false;
    }
  }

  // 6. GET MY OFFERS (Simple Version)
  Stream<List<Map<String, dynamic>>> getOffersStream() {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return const Stream.empty();

    // Fetch offers where I am the Buyer OR the Seller
    return _client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('seller_id', myId) // Currently just showing Incoming Offers
        .order('created_at');
  }

  // 8. SEND MESSAGE
  Future<void> sendMessage(String offerId, String content) async {
    final myId = _client.auth.currentUser?.id;
    if (myId == null) return;

    await _client.from('messages').insert({
      'offer_id': offerId,
      'sender_id': myId,
      'content': content,
    });
  }

  // 9. LISTEN TO CHAT (Stream)
  Stream<List<Map<String, dynamic>>> getChatStream(String offerId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('offer_id', offerId)
        .order('created_at', ascending: true); // Oldest first
  }

  // 10. ACCEPT DEAL (Change status to allow chatting)
  Future<void> acceptOffer(String offerId) async {
    await _client.from('offers').update({'status': 'accepted'}).eq('id', offerId);
  }

  // 11. GET USER PROFILE (Stats & Badges)
  Future<Map<String, dynamic>?> getUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Fetch User Row
      final user = await _client.from('users').select().eq('id', userId).single();

      // Fetch Item Counts (Active vs Sold)
      final items = await _client.from('items').select('status').eq('owner_id', userId);
      final activeCount = items.where((i) => i['status'] == 'active').length;
      final soldCount = items.where((i) => i['status'] == 'sold').length;

      return {
        ...user,
        'active_items': activeCount,
        'sold_items': soldCount,
      };
    } catch (e) {
      print('🔴 Error fetching profile: $e');
      return null;
    }
  }

  // 12. DELETE ITEM (or Mark Sold)
  Future<void> deleteItem(String itemId) async {
    // We don't actually delete; we mark as 'deleted' to keep data
    await _client.from('items').update({'status': 'deleted'}).eq('id', itemId);
  }
}
