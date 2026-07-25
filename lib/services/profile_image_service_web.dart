import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileImageService {
  static const String _imageKey = 'profile_image_path';

  Future<Object?> pickAndSaveImage(ImageSource source) async => null;

  Future<Object?> loadSavedImage() async => null;

  Future<String?> getSavedImagePath() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_imageKey);
  }
}
