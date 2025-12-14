// lib/core/services/recommendation_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/services/logger.dart';
import 'dart:async';

class RecommendationService {
  final _client = Supabase.instance.client;

  // Cache for performance
  final Map<String, List<Item>> _cache = {};
  Timer? _cacheInvalidationTimer;

  // Track interactions for learning
  final List<UserInteraction> _pendingInteractions = [];
  Timer? _batchSyncTimer;

  RecommendationService() {
    _initializeBatchSync();
  }

  void _initializeBatchSync() {
    // Sync interactions every 30 seconds
    _batchSyncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _syncPendingInteractions(),
    );

    // Invalidate cache every 5 minutes
    _cacheInvalidationTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cache.clear(),
    );
  }

  /// Get personalized recommendations for the user
  Future<List<Item>> getPersonalizedFeed({
    required double lat,
    required double lng,
    int limit = 50,
    int offset = 0,
    bool forceRefresh = false,
  }) async {
    try {
      // Check cache first
      final cacheKey = 'feed_${lat}_${lng}_${limit}_$offset';
      if (!forceRefresh && _cache.containsKey(cacheKey)) {
        Logger.info('Returning cached recommendations');
        return _cache[cacheKey]!;
      }

      final user = _client.auth.currentUser;
      if (user == null) {
        return _getFallbackRecommendations(lat, lng, limit, offset);
      }

      Logger.info('Fetching personalized recommendations');

      final response = await _client.rpc(
        'get_personalized_recommendations',
        params: {
          'p_user_id': user.id,
          'p_user_lat': lat,
          'p_user_lng': lng,
          'p_limit': limit,
          'p_offset': offset,
        },
      ).timeout(const Duration(seconds: 10));

      final items = (response as List)
          .map((json) => Item.fromJson(json))
          .toList();

      // Cache the results
      _cache[cacheKey] = items;

      // Track that user viewed these items
      for (final item in items.take(10)) {
        recordInteraction(
          item.id,
          InteractionType.view,
          metadata: {'screen': 'home_deck'},
        );
      }

      Logger.info('Got ${items.length} personalized items');
      return items;

    } catch (e, stackTrace) {
      Logger.error('Failed to get recommendations', e, stackTrace);
      return _getFallbackRecommendations(lat, lng, limit, offset);
    }
  }

  /// Fallback to simple nearby items if personalization fails
  Future<List<Item>> _getFallbackRecommendations(
    double lat,
    double lng,
    int limit,
    int offset,
  ) async {
    try {
      final response = await _client.rpc(
        'get_items_nearby',
        params: {
          'lat': lat,
          'lng': lng,
          'radius_meters': 50000,
        },
      );

      return (response as List)
          .map((json) => Item.fromJson(json))
          .toList();
    } catch (e) {
      Logger.error('Fallback recommendations failed', e);
      return [];
    }
  }

  /// Record a user interaction (swipe, view, etc.)
  void recordInteraction(
    String itemId,
    InteractionType type, {
    int? durationSeconds,
    Map<String, dynamic>? metadata,
  }) {
    final interaction = UserInteraction(
      itemId: itemId,
      action: type.value,
      sessionId: _getSessionId(),
      durationSeconds: durationSeconds,
      metadata: metadata,
    );

    _pendingInteractions.add(interaction);

    // If we have 10+ pending, sync immediately
    if (_pendingInteractions.length >= 10) {
      _syncPendingInteractions();
    }
  }

  /// Batch sync interactions to database
  Future<void> _syncPendingInteractions() async {
    if (_pendingInteractions.isEmpty) return;

    final batch = List<UserInteraction>.from(_pendingInteractions);
    _pendingInteractions.clear();

    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      await _client.from('user_interactions').insert(
        batch.map((i) => {
          'user_id': user.id,
          'item_id': i.itemId,
          'action': i.action,
          'session_id': i.sessionId,
          'duration_seconds': i.durationSeconds,
          'metadata': i.metadata,
        }).toList(),
      );

      Logger.info('Synced ${batch.length} interactions');

      // Update user preferences if we've had 10+ interactions
      await _updateUserPreferencesIfNeeded();

    } catch (e) {
      Logger.error('Failed to sync interactions', e);
      // Put them back in the queue
      _pendingInteractions.addAll(batch);
    }
  }

  /// Update user preferences based on recent behavior
  Future<void> _updateUserPreferencesIfNeeded() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Check if we should update preferences
      final prefs = await _client
          .from('user_preferences')
          .select('updated_at')
          .eq('user_id', user.id)
          .maybeSingle();

      if (prefs == null) {
        // First time, create preferences
        await _client.rpc('update_user_preferences', params: {
          'p_user_id': user.id,
        });
        Logger.info('Created initial user preferences');
      } else {
        // Update if last update was > 1 hour ago
        final lastUpdate = DateTime.parse(prefs['updated_at']);
        if (DateTime.now().difference(lastUpdate).inHours >= 1) {
          await _client.rpc('update_user_preferences', params: {
            'p_user_id': user.id,
          });
          Logger.info('Updated user preferences');
        }
      }
    } catch (e) {
      Logger.error('Failed to update user preferences', e);
    }
  }

  /// Get explanation for why an item was recommended
  Future<RecommendationExplanation?> explainRecommendation(
    String itemId,
  ) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      // Get the score breakdown from recent recommendations
      final recent = await _client
          .from('user_interactions')
          .select('metadata')
          .eq('user_id', user.id)
          .eq('item_id', itemId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (recent != null && recent['metadata'] != null) {
        final breakdown = recent['metadata']['score_breakdown'];
        return RecommendationExplanation.fromJson(breakdown);
      }

      return null;
    } catch (e) {
      Logger.error('Failed to explain recommendation', e);
      return null;
    }
  }

  /// Get similar items to a given item
  Future<List<Item>> getSimilarItems({
    required String itemId,
    required double lat,
    required double lng,
    int limit = 20,
  }) async {
    try {
      // Get the item details
      final item = await _client
          .from('items')
          .select()
          .eq('id', itemId)
          .single();

      // Find similar items (same category, similar price)
      final response = await _client.rpc('get_items_nearby', params: {
        'lat': lat,
        'lng': lng,
        'radius_meters': 50000,
      });

      final allItems = (response as List)
          .map((json) => Item.fromJson(json))
          .toList();

      // Filter and sort by similarity
      final similar = allItems
          .where((i) =>
            i.id != itemId &&
            i.category == item['category'] &&
            (i.price - item['price']).abs() < item['price'] * 0.5
          )
          .take(limit)
          .toList();

      return similar;
    } catch (e) {
      Logger.error('Failed to get similar items', e);
      return [];
    }
  }

  /// Prefetch next batch of recommendations for smooth scrolling
  Future<void> prefetchNextBatch({
    required double lat,
    required double lng,
    required int currentOffset,
  }) async {
    try {
      // Prefetch in background
      getPersonalizedFeed(
        lat: lat,
        lng: lng,
        limit: 50,
        offset: currentOffset + 50,
      );
    } catch (e) {
      // Silent fail for prefetch
      Logger.warning('Prefetch failed: $e');
    }
  }

  /// Get trending items in user's area
  Future<List<Item>> getTrendingItems({
    required double lat,
    required double lng,
    int limit = 20,
  }) async {
    try {
      final response = await _client.rpc('get_items_nearby', params: {
        'lat': lat,
        'lng': lng,
        'radius_meters': 50000,
      });

      final items = (response as List)
          .map((json) => Item.fromJson(json))
          .toList();

      // Sort by popularity (would need popularity_score from item_scores table)
      items.sort((a, b) {
        // For now, sort by recent + distance
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      });

      return items.take(limit).toList();
    } catch (e) {
      Logger.error('Failed to get trending items', e);
      return [];
    }
  }

  String _getSessionId() {
    // Simple session ID (would be better to persist across app launches)
    return '${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _batchSyncTimer?.cancel();
    _cacheInvalidationTimer?.cancel();
    _syncPendingInteractions(); // Sync any remaining
  }
}

// ========================================
// Data Models
// ========================================

class UserInteraction {
  final String itemId;
  final String action;
  final String sessionId;
  final int? durationSeconds;
  final Map<String, dynamic>? metadata;

  UserInteraction({
    required this.itemId,
    required this.action,
    required this.sessionId,
    this.durationSeconds,
    this.metadata,
  });
}

enum InteractionType {
  view('view'),
  swipeRight('swipe_right'),
  swipeLeft('swipe_left'),
  offerSent('offer_sent'),
  chatOpened('chat_opened'),
  purchased('purchased');

  final String value;
  const InteractionType(this.value);
}

class RecommendationExplanation {
  final double proximityScore;
  final double categoryScore;
  final double priceScore;
  final double qualityScore;
  final double freshnessScore;
  final double swapMatchScore;
  final double reputationScore;
  final double popularityScore;
  final double boostedScore;

  RecommendationExplanation({
    required this.proximityScore,
    required this.categoryScore,
    required this.priceScore,
    required this.qualityScore,
    required this.freshnessScore,
    required this.swapMatchScore,
    required this.reputationScore,
    required this.popularityScore,
    required this.boostedScore,
  });

  factory RecommendationExplanation.fromJson(Map<String, dynamic> json) {
    return RecommendationExplanation(
      proximityScore: (json['proximity'] ?? 0).toDouble(),
      categoryScore: (json['category'] ?? 0).toDouble(),
      priceScore: (json['price'] ?? 0).toDouble(),
      qualityScore: (json['quality'] ?? 0).toDouble(),
      freshnessScore: (json['freshness'] ?? 0).toDouble(),
      swapMatchScore: (json['swap_match'] ?? 0).toDouble(),
      reputationScore: (json['reputation'] ?? 0).toDouble(),
      popularityScore: (json['popularity'] ?? 0).toDouble(),
      boostedScore: (json['boosted'] ?? 0).toDouble(),
    );
  }

  String getTopReason() {
    final scores = {
      'Perfect location': proximityScore,
      'Matches your interests': categoryScore,
      'In your price range': priceScore,
      'High quality item': qualityScore,
      'Brand new listing': freshnessScore,
      'Swap-friendly': swapMatchScore,
      'Trusted seller': reputationScore,
      'Trending item': popularityScore,
      'Featured': boostedScore,
    };

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  List<String> getTopReasons({int count = 3}) {
    final scores = {
      'Perfect location': proximityScore,
      'Matches your interests': categoryScore,
      'In your price range': priceScore,
      'High quality': qualityScore,
      'Brand new': freshnessScore,
      'Swap-friendly': swapMatchScore,
      'Trusted seller': reputationScore,
      'Trending': popularityScore,
      'Featured': boostedScore,
    };

    final sorted = scores.entries
        .where((e) => e.value > 10) // Only significant reasons
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((e) => e.key).toList();
  }
}
