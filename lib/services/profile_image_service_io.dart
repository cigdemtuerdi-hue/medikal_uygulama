import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  final ImagePicker _picker = ImagePicker();
  static const String _imageKey = 'profile_image_path';

  Future<File?> pickAndSaveImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (pickedFile == null) return null;

      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basename(pickedFile.path);
      final File localImage =
          await File(pickedFile.path).copy('${appDir.path}/$fileName');

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_imageKey, localImage.path);

      return localImage;
    } catch (e) {
      debugPrint('Resim seçerken hata oluştu: $e');
      return null;
    }
  }

  Future<File?> loadSavedImage() async {
    final imagePath = await getSavedImagePath();
    if (imagePath == null) return null;
    return File(imagePath);
  }

  Future<String?> getSavedImagePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString(_imageKey);

    if (imagePath != null && await File(imagePath).exists()) {
      return imagePath;
    }
    return null;
  }
}
