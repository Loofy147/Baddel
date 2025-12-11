class Item {
  final String id;
  final String title;
  final int price;
  final String imageUrl;
  final bool acceptsSwaps;
  final String locationName;

  Item({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.acceptsSwaps,
    required this.locationName,
  });

  // Factory to create Item from Supabase JSON
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      title: json['title'],
      price: json['price'] ?? 0,
      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/400', // Fallback
      acceptsSwaps: json['accepts_swaps'] ?? false,
      locationName: 'Alger Centre', // Placeholder for now, later we use GeoHash
    );
  }
}
