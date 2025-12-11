import 'dart:io';
import 'package:baddel/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package.path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = locator<SupabaseService>().client;

  Future<String?> pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);

    if (imageFile == null) {
      return null;
    }

    final File file = File(imageFile.path);
    final String fileName = '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';
    final String userId = _client.auth.currentUser!.id;
    final String path = '$userId/$fileName';

    try {
      await _client.storage.from('items').upload(path, file);
      final String publicUrl = _client.storage.from('items').getPublicUrl(path);
      return publicUrl;
    } on StorageException catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<File> getImageFileFromUrl(String url) async {
    final http.Response response = await http.get(Uri.parse(url));
    final String documentDirectory = (await getApplicationDocumentsDirectory()).path;
    final String fileName = p.basename(url);
    final File file = File(p.join(documentDirectory, fileName));
    await file.writeAsBytes(response.bodyBytes);
    return file;
  }
}
