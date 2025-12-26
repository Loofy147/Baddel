// lib/ui/screens/search/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baddel/core/models/item_model.dart';
import 'package:baddel/core/models/search_options.dart';
import 'package:baddel/ui/widgets/common/skeleton_loader.dart';
import 'package:geolocator/geolocator.dart';
import 'package:baddel/core/providers.dart';

// ============================================================================
// PROVIDERS
// ============================================================================

final searchQueryProvider = StateProvider<String>((ref) => '');
final selectedCategoryProvider = StateProvider<String?>((ref) => null);
final priceRangeProvider = StateProvider<RangeValues>((ref) => const RangeValues(0, 100000));
final sortByProvider = StateProvider<SortOption>((ref) => SortOption.newest);
final acceptsSwapsOnlyProvider = StateProvider<bool>((ref) => false);
final maxDistanceProvider = StateProvider<double>((ref) => 50); // km

final forceRefreshProvider = StateProvider.autoDispose<bool>((ref) => false);

final filteredItemsProvider =
    FutureProvider.autoDispose.family<List<Item>, Position?>((ref, userLocation) async {
  final supabaseService = ref.watch(supabaseServiceProvider);
  final forceRefresh = ref.watch(forceRefreshProvider);
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final priceRange = ref.watch(priceRangeProvider);
  final sortBy = ref.watch(sortByProvider);
  final swapsOnly = ref.watch(acceptsSwapsOnlyProvider);
  final maxDistance = ref.watch(maxDistanceProvider);

  return await supabaseService.searchItems(
    query: query,
    category: category,
    minPrice: priceRange.start,
    maxPrice: priceRange.end,
    swapsOnly: swapsOnly,
    lat: userLocation?.latitude,
    lng: userLocation?.longitude,
    maxDistance: maxDistance,
    sortBy: sortBy,
    forceRefresh: forceRefresh,
  );
});

// ============================================================================
// MAIN SEARCH SCREEN
// ============================================================================

class EnhancedSearchScreen extends ConsumerStatefulWidget {
  final Position? userLocation;

  const EnhancedSearchScreen({super.key, this.userLocation});

  @override
  ConsumerState<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends ConsumerState<EnhancedSearchScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _showFilters = false;

  final List<String> _categories = [
    'Electronics',
    'Vehicles',
    'Furniture',
    'Clothing',
    'Home & Garden',
    'Collectibles',
    'Sports',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredItemsProvider(widget.userLocation));
    _hasActiveFilters();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            if (_showFilters) _buildFilterPanel(),
            _buildActiveFiltersChips(),
            Expanded(
              child: filteredItems.when(
                loading: () => _buildLoadingState(),
                error: (err, stack) => _buildErrorState(err),
                data: (items) => items.isEmpty
                    ? _buildEmptyState()
                    : _buildResultsList(items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // SEARCH BAR
  // ============================================================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          bottom: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey[800]!),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(searchQueryProvider.notifier).state = '';
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  ref.read(searchQueryProvider.notifier).state = value;
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final hasFilters = _hasActiveFilters();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: hasFilters ? const Color(0xFF2962FF) : Colors.grey[850],
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.tune,
              color: hasFilters ? Colors.white : Colors.grey[400],
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
        ),
        if (hasFilters)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  bool _hasActiveFilters() {
    final category = ref.read(selectedCategoryProvider);
    final priceRange = ref.read(priceRangeProvider);
    final swapsOnly = ref.read(acceptsSwapsOnlyProvider);

    return category != null ||
           priceRange.start > 0 ||
           priceRange.end < 100000 ||
           swapsOnly;
  }

  // ============================================================================
  // FILTER PANEL
  // ============================================================================

  Widget _buildFilterPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 400,
      color: Colors.grey[900],
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildCategoryFilter(),
            const SizedBox(height: 24),
            _buildPriceRangeFilter(),
            const SizedBox(height: 24),
            _buildDistanceFilter(),
            const SizedBox(height: 24),
            _buildSwapToggle(),
            const SizedBox(height: 24),
            _buildSortOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.map((category) {
            final isSelected = selectedCategory == category;
            return FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                ref.read(selectedCategoryProvider.notifier).state =
                    selected ? category : null;
              },
              selectedColor: const Color(0xFF2962FF),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
              ),
              backgroundColor: Colors.grey[850],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPriceRangeFilter() {
    final priceRange = ref.watch(priceRangeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Price Range (DZD)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${priceRange.start.toInt()} - ${priceRange.end.toInt()}',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: priceRange,
          min: 0,
          max: 100000,
          divisions: 100,
          activeColor: const Color(0xFF00E676),
          inactiveColor: Colors.grey[800],
          onChanged: (values) {
            ref.read(priceRangeProvider.notifier).state = values;
          },
        ),
      ],
    );
  }

  Widget _buildDistanceFilter() {
    final maxDistance = ref.watch(maxDistanceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Maximum Distance',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${maxDistance.toInt()} km',
              style: const TextStyle(
                color: Color(0xFF00E676),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: maxDistance,
          min: 1,
          max: 100,
          divisions: 99,
          activeColor: const Color(0xFF00E676),
          inactiveColor: Colors.grey[800],
          onChanged: (value) {
            ref.read(maxDistanceProvider.notifier).state = value;
          },
        ),
      ],
    );
  }

  Widget _buildSwapToggle() {
    final swapsOnly = ref.watch(acceptsSwapsOnlyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Items that accept swaps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Only show items open to trades',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Switch(
            value: swapsOnly,
            activeColor: const Color(0xFFBB86FC),
            onChanged: (value) {
              ref.read(acceptsSwapsOnlyProvider.notifier).state = value;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSortOptions() {
    final sortBy = ref.watch(sortByProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sort By',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...SortOption.values.map((option) {
          return RadioListTile<SortOption>(
            title: Text(
              option.label,
              style: const TextStyle(color: Colors.white),
            ),
            value: option,
            groupValue: sortBy,
            activeColor: const Color(0xFF2962FF),
            onChanged: (value) {
              if (value != null) {
                ref.read(sortByProvider.notifier).state = value;
              }
            },
          );
        }),
      ],
    );
  }

  // ============================================================================
  // ACTIVE FILTERS CHIPS
  // ============================================================================

  Widget _buildActiveFiltersChips() {
    if (!_hasActiveFilters()) return const SizedBox.shrink();

    final category = ref.watch(selectedCategoryProvider);
    final swapsOnly = ref.watch(acceptsSwapsOnlyProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (category != null)
            _buildChip(
              label: category,
              onDelete: () {
                ref.read(selectedCategoryProvider.notifier).state = null;
              },
            ),
          if (swapsOnly)
            _buildChip(
              label: 'Accepts Swaps',
              onDelete: () {
                ref.read(acceptsSwapsOnlyProvider.notifier).state = false;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required VoidCallback onDelete}) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: const Color(0xFF2962FF).withOpacity(0.2),
      deleteIconColor: const Color(0xFF2962FF),
      labelStyle: const TextStyle(
        color: Color(0xFF2962FF),
        fontSize: 12,
      ),
    );
  }

  void _clearAllFilters() {
    ref.read(selectedCategoryProvider.notifier).state = null;
    ref.read(priceRangeProvider.notifier).state = const RangeValues(0, 100000);
    ref.read(acceptsSwapsOnlyProvider.notifier).state = false;
    ref.read(maxDistanceProvider.notifier).state = 50;
    ref.read(sortByProvider.notifier).state = SortOption.newest;
  }

  // ============================================================================
  // STATES
  // ============================================================================

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => const SkeletonListItem(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey[800]),
          const SizedBox(height: 16),
          const Text(
            'No items found',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(List<Item> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildItemCard(items[index]);
      },
    );
  }

  Widget _buildItemCard(Item item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
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
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        item.distanceDisplay,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
