import 'package:baddel/core/models/item_model.dart';
import 'package:flutter/material.dart';

class CreateABTestScreen extends StatelessWidget {
  final Item item;

  const CreateABTestScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('A/B Test for ${item.title}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'A/B test configuration for this item will be implemented here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              if (item.imageUrls.isNotEmpty)
                Image.network(
                  item.imageUrls.first,
                  height: 150,
                  fit: BoxFit.cover,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
