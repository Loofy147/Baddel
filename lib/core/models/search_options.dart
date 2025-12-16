enum SortOption {
  newest('Newest First'),
  oldest('Oldest First'),
  priceLowToHigh('Price: Low to High'),
  priceHighToLow('Price: High to Low'),
  nearest('Nearest First');

  final String label;
  const SortOption(this.label);
}
