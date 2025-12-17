// lib/features/favorites/favorites_system.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:baddel/core/models/item_model.dart';

// ============================================================================
// FAVORITES SERVICE
// ============================================================================

class FavoritesService {
  final _supabase = Supabase.instance.client;

  // Add item to favorites
  Future<void> addFavorite(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase.from('favorites').insert({
      'user_id': userId,
      'item_id': itemId,
    });

    // Increment favorite count on item
    await _supabase.rpc('increment_favorite_count', params: {'item_id': itemId});
  }

  // Remove item from favorites
  Future<void> removeFavorite(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    await _supabase
        .from('favorites')
        .delete()
        .eq('user_id': userId)
        .eq('item_id': itemId);

    // Decrement favorite count on item
    await _supabase.rpc('decrement_favorite_count', params: {'item_id': itemId});
  }

  // Check if item is favorited
  Future<bool> isFavorited(String itemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    final result = await _supabase
        .from('favorites')
        .select('id')
        .eq('user_id': userId)
        .eq('item_id': itemId)
        .maybeSingle();

    return result != null;
  }

  // Get all favorited items
  Future<List<Item>> getFavorites() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _supabase
        .from('favorites')
        .select('*, items(*)')
        .eq('user_id': userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((fav) => Item.fromJson(fav['items']))
        .toList();
  }

  // Stream of favorites (real-time updates)
  Stream<List<Item>> getFavoritesStream() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id': userId)
        .order('created_at', ascending: false)
        .asyncMap((data) async {
          final List<Item> items = [];
          for (var fav in data) {
            try {
              final itemData = await _supabase
                  .from('items')
                  .select()
                  .eq('id', fav['item_id'])
                  .single();
              items.add(Item.fromJson(itemData));
            } catch (e) {
              // Item might be deleted, skip it
              continue;
            }
          }
          return items;
        });
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  return FavoritesService();
});

final favoritesProvider = StreamProvider.autoDispose<List<Item>>((ref) {
  return ref.watch(favoritesServiceProvider).getFavoritesStream();
});

final isFavoritedProvider = FutureProvider.family<bool, String>((ref, itemId) async {
  return await ref.watch(favoritesServiceProvider).isFavorited(itemId);
});

// ============================================================================
// FAVORITE BUTTON WIDGET
// ============================================================================

class FavoriteButton extends ConsumerStatefulWidget {
  final String itemId;
  final double size;
  final Color? activeColor;
  final Color? inactiveColor;

  const FavoriteButton({
    super.key,
    required this.itemId,
    this.size = 24,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  ConsumerState<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends ConsumerState<FavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isFavorited = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _checkIfFavorited();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkIfFavorited() async {
    final isFavorited = await ref
        .read(favoritesServiceProvider)
        .isFavorited(widget.itemId);
    if (mounted) {
      setState(() => _isFavorited = isFavorited);
    }
  }

  Future<void> _toggleFavorite() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_isFavorited) {
        await ref.read(favoritesServiceProvider).removeFavorite(widget.itemId);
      } else {
        await ref.read(favoritesServiceProvider).addFavorite(widget.itemId);
        _controller.forward().then((_) => _controller.reverse());
      }

      setState(() => _isFavorited = !_isFavorited);

      // Refresh the favorites list
      ref.invalidate(favoritesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: IconButton(
        icon: Icon(
          _isFavorited ? Icons.favorite : Icons.favorite_border,
          color: _isFavorited
              ? (widget.activeColor ?? Colors.red)
              : (widget.inactiveColor ?? Colors.white),
          size: widget.size,
        ),
        onPressed: _isLoading ? null : _toggleFavorite,
      ),
    );
  }
}

// ============================================================================
// FAVORITES SCREEN
// ============================================================================

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Saved Items'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showFavoritesInfo(context),
          ),
        ],
      ),
      body: favoritesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2962FF)),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading favorites',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        data: (favorites) {
          if (favorites.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteCard(context, ref, favorites[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text(
            'No saved items yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Items you save will appear here',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2962FF),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Browse Items'),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteCard(BuildContext context, WidgetRef ref, Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to item details
        },
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Image.network(
                item.imageUrl,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${item.price} DZD',
                      style: const TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          item.distanceDisplay,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: FavoriteButton(itemId: item.id),
            ),
          ],
        ),
      ),
    );
  }

  void _showFavoritesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'About Saved Items',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Save items you\'re interested in to come back to them later. '
          'You\'ll be notified if the price changes or the item gets new offers.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
