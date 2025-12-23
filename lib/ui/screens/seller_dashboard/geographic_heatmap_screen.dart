import 'package:flutter/material.dart';

class GeographicHeatmapScreen extends StatelessWidget {
  const GeographicHeatmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geographic Heatmap'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const Center(
        child: Text('Heatmap visualization will be implemented here.'),
      ),
    );
  }
}
