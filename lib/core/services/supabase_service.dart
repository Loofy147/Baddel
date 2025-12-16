import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baddel/core/models/item_model.dart';
import 'auth_service.dart';
import 'error_handler.dart';
import 'logger.dart';

class SupabaseService {
  final SupabaseClient _client;
  final AuthService _authService;

  SupabaseService(this._client, this._authService);

  Future<String> _getCurrentUserId() async {
    final user = await _authService.currentUser;
    if (user == null) {
      throw AppException('User not authenticated. Please log in.', code: 'AUTH_REQUIRED');
    }
    return user.id;
  }

  // 1. GET THE FEED (Fetch Items)
  Future<List<Item>> getFeedItems() async {
    try {
      final response = await _client
          .from('items')
          .select()
          .order('created_at', ascending: false);

      final data = response as List<dynamic>;
      return data.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  Future<List<Item>> getNearbyItems({required double lat, required double lng, required int radiusInMeters}) async {
    try {
      final response = await _client.rpc('get_items_nearby', params: {
        'lat': lat,
        'lng': lng,
        'radius_meters': radiusInMeters,
      });
      final data = response as List<dynamic>;
      return data.map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  // 2. UPLOAD IMAGE (To Storage Bucket)
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      await _client.storage
          .from('baddel_images')
          .upload(path, imageFile);

      final publicUrl = _client.storage
          .from('baddel_images')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  // 3. POST ITEM (Create Listing) with GEOLOCATION
  Future<void> postItem({
    required String title,
    required int price,
    required List<String> imageUrls,
    required bool acceptsSwaps,
    String? category,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final userId = await _getCurrentUserId();
      final lat = latitude != null ? (latitude * 1000).round() / 1000 : 36.7525;
      final lng = longitude != null ? (longitude * 1000).round() / 1000 : 3.0588;
      final locationString = 'POINT($lng $lat)';

      await _client.from('items').insert({
        'owner_id': userId,
        'title': title,
        'price': price,
        'image_urls': imageUrls,
        'image_url': imageUrls.first,
        'accepts_swaps': acceptsSwaps,
        'is_cash_only': !acceptsSwaps,
        'location': locationString,
        'status': 'active',
        'category': category,
      });
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  // 4. GET MY GARAGE (Items owned by current user)
  Future<List<Item>> getMyInventory() async {
    try {
      final userId = await _getCurrentUserId();
      final response = await _client
          .from('items')
          .select()
          .eq('owner_id', userId)
          .eq('status', 'active');

      return (response as List).map((json) => Item.fromJson(json)).toList();
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  // 5. SEND AN OFFER (The "Deal" logic)
  Future<void> createOffer({
    required String targetItemId,
    required String sellerId,
    required int cashAmount,
    String? offeredItemId,
  }) async {
    try {
      final myId = await _getCurrentUserId();
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
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  // 6. GET MY OFFERS (Simple Version)
  Stream<List<Map<String, dynamic>>> getOffersStream() async* {
    final myId = await _getCurrentUserId();
    // Fetch offers where I am the Seller
    yield* _client
        .from('offers')
        .stream(primaryKey: ['id'])
        .eq('seller_id', myId)
        .order('created_at');
  }

  // 8. SEND MESSAGE
  Future<void> sendMessage(String offerId, String content) async {
    final myId = await _getCurrentUserId();

    // Authorization check
    final offer = await _client.from('offers').select('buyer_id, seller_id').eq('id', offerId).single();
    if (offer['buyer_id'] != myId && offer['seller_id'] != myId) {
      throw AppException('You are not a part of this deal.', code: 'UNAUTHORIZED');
    }

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
        .order('created_at', ascending: true);
  }

  // 10. ACCEPT DEAL (Change status to allow chatting)
  Future<void> acceptOffer(String offerId) async {
    final userId = await _getCurrentUserId();
    final offer = await _client.from('offers').select('seller_id').eq('id', offerId).single();
    if (offer['seller_id'] != userId) {
      throw AppException('Unauthorized to accept this offer', code: 'UNAUTHORIZED');
    }

    await _client.from('offers').update({'status': 'accepted'}).eq('id', offerId);
  }

  // 11. GET USER PROFILE (Stats & Badges)
  Future<Map<String, dynamic>> getUserProfile() async {
    final userId = await _getCurrentUserId();
    try {
      final userProfile = await _client.from('users').select().eq('id', userId).single();
      final items = await _client.from('items').select('status').eq('owner_id', userId);
      final activeCount = items.where((i) => i['status'] == 'active').length;
      final soldCount = items.where((i) => i['status'] == 'sold').length;

      return {
        ...userProfile,
        'active_items': activeCount,
        'sold_items': soldCount,
      };
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  Stream<Map<String, dynamic>?> getUserProfileStream() async* {
    final userId = await _getCurrentUserId();
    yield* _client
        .from('users')
        .stream(primaryKey: ['id']).eq('id', userId)
        .map((event) => event.isNotEmpty ? event.first : null);
  }

  Future<Map<String, dynamic>> getUserPrivateData() async {
    final userId = await _getCurrentUserId();
    try {
      final data = await _client.from('user_private_data').select().eq('id', userId).single();
      return data;
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }

  // 12. DELETE ITEM (or Mark Sold)
  Future<void> deleteItem(String itemId) async {
    final userId = await _getCurrentUserId();
    final result = await _client
      .from('items')
      .update({'status': 'deleted'})
      .eq('id', itemId)
      .eq('owner_id', userId)
      .select();

    if (result.isEmpty) {
      throw AppException('Unauthorized or item not found', code: 'UNAUTHORIZED');
    }
  }

  // 13. REPORT ITEM
  Future<void> reportItem({required String itemId, required String reason, String? notes}) async {
    final userId = await _getCurrentUserId();
    try {
      await _client.from('reports').insert({
        'reporter_id': userId,
        'reported_item_id': itemId,
        'reason': reason,
        'notes': notes,
      });
    } catch (e) {
      throw AppException.fromSupabaseError(e);
    }
  }
}
