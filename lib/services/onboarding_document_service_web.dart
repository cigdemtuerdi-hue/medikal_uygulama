import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class OnboardingDocumentService {
  final ImagePicker _picker = ImagePicker();

  Future<String?> pickIdDocument(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      return pickedFile?.name;
    } catch (e) {
      debugPrint('Kimlik yüklenirken hata oluştu: $e');
      return null;
    }
  }

  Future<String?> pickDoctorReport() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: false,
      );
      if (result == null || result.files.isEmpty) return null;
      return result.files.single.name;
    } catch (e) {
      debugPrint('Doktor raporu yüklenirken hata oluştu: $e');
      return null;
    }
  }

  Future<String?> pickConditionVideo() async {
    try {
      final pickedVideo = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 10),
      );
      return pickedVideo?.name;
    } catch (e) {
      debugPrint('Video yüklenirken hata oluştu: $e');
      return null;
    }
  }

  String fileLabel(String? filePath) {
    if (filePath == null) return '';
    return filePath.split('/').last;
  }
}
