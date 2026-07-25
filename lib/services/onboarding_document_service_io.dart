import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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
      if (pickedFile == null) return null;
      return _persistFile(pickedFile.path, prefix: 'id_');
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

      final file = result.files.single;
      final sourcePath = file.path;
      if (sourcePath == null) return file.name;

      return _persistFile(sourcePath, prefix: 'report_');
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
      if (pickedVideo == null) return null;
      return _persistFile(pickedVideo.path, prefix: 'video_');
    } catch (e) {
      debugPrint('Video yüklenirken hata oluştu: $e');
      return null;
    }
  }

  Future<String> _persistFile(String sourcePath, {required String prefix}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = '$prefix${path.basename(sourcePath)}';
    final destination = File('${appDir.path}/$fileName');
    await File(sourcePath).copy(destination.path);
    return destination.path;
  }

  String fileLabel(String? filePath) {
    if (filePath == null) return '';
    return path.basename(filePath);
  }
}
