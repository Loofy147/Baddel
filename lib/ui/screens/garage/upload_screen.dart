import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  File? _imageFile;
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  bool _acceptsSwaps = true;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera); // Or gallery
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add to Garage"),
        backgroundColor: Colors.black,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. IMAGE PICKER
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  image: _imageFile != null
                    ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                    : null,
                ),
                child: _imageFile == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey, size: 50),
                          Text("Tap to Snap", style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // 2. FORM FIELDS
            const Text("What are you selling?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(hintText: "e.g. PlayStation 5", hintStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),

            const Text("Price (DZD)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 18),
              decoration: const InputDecoration(hintText: "0", hintStyle: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 20),

            // 3. SWAP TOGGLE
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Accept Swaps?", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Switch(
                    value: _acceptsSwaps,
                    activeColor: const Color(0xFFBB86FC),
                    onChanged: (val) => setState(() => _acceptsSwaps = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 4. SUBMIT BUTTON
            ElevatedButton(
              onPressed: () {
                // TODO: Upload to Supabase
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Uploading to Garage...")));
                Future.delayed(const Duration(seconds: 2), () => Navigator.pop(context));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2962FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("POST ITEM", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
