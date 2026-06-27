import 'package:shared_preferences/shared_preferences.dart';
import 'package:gps_camera/models/app_settings.dart';

class SettingsService {
  static const String _saveToGalleryKey = 'save_to_gallery';
  static const String _imageQualityKey = 'image_quality';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      saveToGallery: prefs.getBool(_saveToGalleryKey) ?? true,
      imageQuality: prefs.getInt(_imageQualityKey) ?? 85,
    );
  }

  Future<void> saveSaveToGallery(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_saveToGalleryKey, value);
  }

  Future<void> saveImageQuality(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_imageQualityKey, value);
  }
}
