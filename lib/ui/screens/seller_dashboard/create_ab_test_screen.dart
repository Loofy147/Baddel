import 'dart:io';
import 'package:baddel/core/models/item_model.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateABTestScreen extends StatefulWidget {
  final Item item;

  const CreateABTestScreen({super.key, required this.item});

  @override
  State<CreateABTestScreen> createState() => _CreateABTestScreenState();
}

class _CreateABTestScreenState extends State<CreateABTestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _variantTitleController;
  File? _variantImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _variantTitleController = TextEditingController(text: '${widget.item.title} - Variant');
  }

  @override
  void dispose() {
    _variantTitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _variantImage = File(pickedFile.path);
      });
    }
  }

  void _startTest() {
    if (_formKey.currentState!.validate()) {
      if (_variantImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please upload a variant image.')),
        );
        return;
      }

      // In a real application, you would send this data to your backend
      // to start the A/B test.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('A/B test started for "${widget.item.title}"!')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('A/B Test for ${widget.item.title}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Original Item (A)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    if (widget.item.imageUrls.isNotEmpty)
                      Image.network(widget.item.imageUrls.first, height: 150, width: double.infinity, fit: BoxFit.cover),
                    ListTile(
                      title: Text(widget.item.title),
                      subtitle: Text('${widget.item.price} DZD'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Variant Item (B)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _variantTitleController,
                decoration: const InputDecoration(labelText: 'Variant Title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title for the variant.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    if (_variantImage != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_variantImage!, height: 150, width: double.infinity, fit: BoxFit.cover),
                      ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload_file),
                      label: Text(_variantImage == null ? 'Upload Variant Image' : 'Change Variant Image'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startTest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Start A/B Test'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
