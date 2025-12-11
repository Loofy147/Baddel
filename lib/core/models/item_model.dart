class Item {
  final String id;
  final String ownerId; // <-- NEW
  final String title;
  final int price;
  final String imageUrl;
  final bool acceptsSwaps;
  final String locationName;

  Item({
    required this.id,
    required this.ownerId, // <-- NEW
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.acceptsSwaps,
    required this.locationName,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'],
      ownerId: json['owner_id'] ?? '', // <-- MAP IT
      title: json['title'],
      price: json['price'] ?? 0,
      imageUrl: json['image_url'] ?? 'https://via.placeholder.com/400',
      acceptsSwaps: json['accepts_swaps'] ?? false,
      locationName: 'Alger Centre',
    );
  }
}
