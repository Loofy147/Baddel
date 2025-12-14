import 'package:baddel/core/services/error_handler.dart';
import 'package:baddel/core/services/logger.dart';
import 'package:baddel/core/services/supabase_service.dart';
import 'package:baddel/core/validators/input_validator.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = [
    'Electronics',
    'Vehicles',
    'Furniture',
    'Clothing & Apparel',
    'Home & Garden',
    'Collectibles & Art',
    'Sporting Goods',
    'Other',
  ];
  bool _acceptsSwaps = true;
  bool _isUploading = false;

  final List<File> _imageFiles = [];
  int _primaryImageIndex = 0;
  final int _maxPhotos = 5;

  Future<File?> _compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath = '${dir.absolute.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1024,
        minHeight: 1024,
      );

      return result != null ? File(result.path) : null;
    } catch (e) {
      Logger.error("Image Compression Error", e);
      return null;
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      for (var file in pickedFiles) {
        if (_imageFiles.length < _maxPhotos) {
          final compressedFile = await _compressImage(File(file.path));
          if (compressedFile != null) {
            setState(() {
              _imageFiles.add(compressedFile);
            });
          }
        } else {
          break;
        }
      }
    }
  }

  Future<void> _takePhoto() async {
    if (_imageFiles.length >= _maxPhotos) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final compressedFile = await _compressImage(File(pickedFile.path));
      if (compressedFile != null) {
        setState(() {
          _imageFiles.add(compressedFile);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageFiles.removeAt(index);
      if (_primaryImageIndex == index) {
        _primaryImageIndex = 0;
      } else if (_primaryImageIndex > index) {
        _primaryImageIndex--;
      }
    });
  }

  void _setPrimaryImage(int index) {
    setState(() {
      _primaryImageIndex = index;
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    setState(() {
      final primaryImage = _imageFiles[_primaryImageIndex];
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final File item = _imageFiles.removeAt(oldIndex);
      _imageFiles.insert(newIndex, item);

      _primaryImageIndex = _imageFiles.indexOf(primaryImage);
    });
  }

  Future<void> _submitListing() async {
    if (_formKey.currentState!.validate() && _imageFiles.isNotEmpty) {
      setState(() => _isUploading = true);

      try {
        Position? position;
        try {
          LocationPermission permission = await Geolocator.checkPermission();
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
          }

          if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
            position = await Geolocator.getCurrentPosition();
          }
        } catch (e) {
          Logger.error("GPS Error", e);
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("🚀 Uploading images...")));

        final service = SupabaseService();

        final List<Future<String>> uploadTasks = [];
        for (var imageFile in _imageFiles) {
          uploadTasks.add(service.uploadImage(imageFile));
        }
        final List<String> imageUrls = await Future.wait(uploadTasks);

        final primaryImageUrl = imageUrls[_primaryImageIndex];
        imageUrls.removeAt(_primaryImageIndex);
        imageUrls.insert(0, primaryImageUrl);

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Images uploaded, creating listing...")));

        await service.postItem(
          title: _titleController.text,
          price: int.parse(_priceController.text),
          imageUrls: imageUrls,
          acceptsSwaps: _acceptsSwaps,
          category: _selectedCategory,
          latitude: position?.latitude,
          longitude: position?.longitude,
        );

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Item Live in the Deck!")));
        Navigator.pop(context);
      } on AppException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error: ${e.message}"),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    } else if (_imageFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one image")));
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoSection(),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: "e.g. PlayStation 5",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                validator: InputValidator.validateTitle,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [DecimalTextInputFormatter()],
                style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold, fontSize: 18),
                decoration: const InputDecoration(
                  labelText: "Price (DZD)",
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: "0",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                validator: InputValidator.validatePriceString,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  labelText: "Category",
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                validator: (value) => value == null ? 'Please select a category' : null,
                dropdownColor: Colors.grey[900],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accept Swaps?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Allow users to offer items in exchange',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _acceptsSwaps,
                      activeColor: const Color(0xFFBB86FC),
                      onChanged: (value) {
                        setState(() => _acceptsSwaps = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _submitListing,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'LIST ITEM',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Photos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_imageFiles.length}/$_maxPhotos',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'First photo will be the cover image',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 16),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _imageFiles.length + 1,
          onReorder: (oldIndex, newIndex) {
            if (oldIndex < _imageFiles.length) {
              _reorderImages(oldIndex, newIndex);
            }
          },
          itemBuilder: (context, index) {
            if (index < _imageFiles.length) {
              return _buildPhotoItem(index);
            } else {
              return _buildAddPhotoButton();
            }
          },
        ),
      ],
    );
  }

  Widget _buildPhotoItem(int index) {
    final isPrimary = index == _primaryImageIndex;

    return Container(
      key: ValueKey(_imageFiles[index].path),
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _imageFiles[index],
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          if (isPrimary)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2962FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'COVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                if (!isPrimary)
                  _buildActionButton(
                    icon: Icons.star_border,
                    onTap: () => _setPrimaryImage(index),
                    color: Colors.amber,
                  ),
                const SizedBox(width: 8),
                _buildActionButton(
                  icon: Icons.delete,
                  onTap: () => _removeImage(index),
                  color: Colors.red,
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.drag_handle,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    if (_imageFiles.length >= _maxPhotos) {
      return const SizedBox.shrink();
    }

    return Container(
      key: const ValueKey('add_photo'),
      margin: const EdgeInsets.only(bottom: 12),
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _takePhoto,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[800]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_alt,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Camera',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _pickImages,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[800]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.photo_library,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gallery',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final regEx = RegExp(r"^\d*\.?\d{0,2}");
    final String newString = regEx.stringMatch(newValue.text) ?? "";
    return TextEditingValue(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
