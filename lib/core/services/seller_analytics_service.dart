class SellerAnalyticsService {
  Future<Map<String, dynamic>> getSellerMetrics() async {
    // Simulate a network delay of 1 second
    await Future.delayed(const Duration(seconds: 1));

    // In a real application, this would fetch data from a backend.
    // For now, we return mock data.
    return {
      'impressionRate': {
        'value': '1,573 views',
        'description': 'How often your item appears in user Decks.',
      },
      'swipeRightRate': {
        'value': '82%',
        'description': 'Percentage of users who showed interest.',
      },
      'offerToAcceptanceRatio': {
        'value': '37%',
        'description': 'Efficiency of converting interest into a final deal.',
      },
      'geographicHeatmap': {
        'value': 'View Heatmap',
        'description': 'Where your item is getting the most views.',
      },
    };
  }
}
