import 'package:baddel/core/providers.dart';
import 'package:baddel/ui/screens/seller_dashboard/ab_testing_screen.dart';
import 'package:baddel/ui/screens/seller_dashboard/geographic_heatmap_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SellerPerformanceDashboardScreen extends ConsumerWidget {
  const SellerPerformanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsyncValue = ref.watch(sellerMetricsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: metricsAsyncValue.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (metrics) => ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            MetricCard(
              title: 'Impression Rate',
              value: metrics['impressionRate']['value'],
              description: metrics['impressionRate']['description'],
              icon: Icons.visibility,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            MetricCard(
              title: 'Swipe-Right Rate',
              value: metrics['swipeRightRate']['value'],
              description: metrics['swipeRightRate']['description'],
              icon: Icons.thumb_up_alt,
              color: Colors.green,
            ),
            const SizedBox(height: 16),
            MetricCard(
              title: 'Offer-to-Acceptance Ratio',
              value: metrics['offerToAcceptanceRatio']['value'],
              description: metrics['offerToAcceptanceRatio']['description'],
              icon: Icons.swap_horiz,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            MetricCard(
              title: 'Geographic Heatmap',
              value: metrics['geographicHeatmap']['value'],
              description: metrics['geographicHeatmap']['description'],
              icon: Icons.map,
              color: Colors.purple,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GeographicHeatmapScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            MetricCard(
              title: 'A/B Testing',
              value: metrics['abTesting']['value'],
              description: metrics['abTesting']['description'],
              icon: Icons.science,
              color: Colors.teal,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ABTestingScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
