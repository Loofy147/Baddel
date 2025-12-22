import 'package:flutter/material.dart';

class SellerPerformanceDashboardScreen extends StatelessWidget {
  const SellerPerformanceDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          MetricCard(
            title: 'Impression Rate',
            value: '1,234 views',
            description: 'How often your item appears in user Decks.',
            icon: Icons.visibility,
            color: Colors.blue,
          ),
          SizedBox(height: 16),
          MetricCard(
            title: 'Swipe-Right Rate',
            value: '78%',
            description: 'Percentage of users who showed interest.',
            icon: Icons.thumb_up_alt,
            color: Colors.green,
          ),
          SizedBox(height: 16),
          MetricCard(
            title: 'Offer-to-Acceptance Ratio',
            value: '42%',
            description: 'Efficiency of converting interest into a final deal.',
            icon: Icons.swap_horiz,
            color: Colors.orange,
          ),
          SizedBox(height: 16),
          MetricCard(
            title: 'Geographic Heatmap',
            value: 'View Heatmap',
            description: 'Where your item is getting the most views.',
            icon: Icons.map,
            color: Colors.purple,
          ),
        ],
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

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
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
                color: Colors.white,
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
