import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gps_camera/models/app_settings.dart';

class SettingsService {
  static const String _saveToGalleryKey = 'save_to_gallery';
  static const String _imageQualityKey = 'image_quality';
  static const String _themeModeKey = 'theme_mode';

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    return AppSettings(
      saveToGallery: prefs.getBool(_saveToGalleryKey) ?? true,
      imageQuality: prefs.getInt(_imageQualityKey) ?? 85,
      themeMode: _parseThemeMode(prefs.getString(_themeModeKey)),
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

  Future<void> saveThemeMode(ThemeMode value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, value.name);
  }

  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
