class Item {
  final String id;
  final String ownerId;
  final String title;
  final int price;
  final String imageUrl;
  final bool acceptsSwaps;
  final String? category; // NEW: For recommendations
  final double? distanceMeters; // NEW: Actual distance
  final String distanceDisplay; // NEW: Formatted distance "5.2 km"

  Item({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.acceptsSwaps,
    this.category,
    this.distanceMeters,
    this.distanceDisplay = 'Unknown',
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String? ?? '',
      title: json['title'] as String,
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] as String? ?? 'https://via.placeholder.com/400',
      acceptsSwaps: json['accepts_swaps'] as bool? ?? false,
      category: json['category'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      distanceDisplay: json['distance_display'] as String? ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'price': price,
      'image_url': imageUrl,
      'accepts_swaps': acceptsSwaps,
      'category': category,
      'distance_meters': distanceMeters,
      'distance_display': distanceDisplay,
    };
  }

  // Helper to check if item is nearby (< 5km)
  bool get isNearby => (distanceMeters ?? double.infinity) < 5000;

  // Helper to get price in Algerian Dinar format
  String get formattedPrice => '$price DZD';

  // Copy with method for immutability
  Item copyWith({
    String? id,
    String? ownerId,
    String? title,
    int? price,
    String? imageUrl,
    bool? acceptsSwaps,
    String? category,
    double? distanceMeters,
    String? distanceDisplay,
  }) {
    return Item(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      acceptsSwaps: acceptsSwaps ?? this.acceptsSwaps,
      category: category ?? this.category,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      distanceDisplay: distanceDisplay ?? this.distanceDisplay,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, title: $title, price: $price, distance: $distanceDisplay)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}