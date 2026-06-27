import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.saveToGallery,
    required this.imageQuality,
    this.themeMode = ThemeMode.system,
  });

  final bool saveToGallery;
  final int imageQuality;
  final ThemeMode themeMode;

  AppSettings copyWith({
    bool? saveToGallery,
    int? imageQuality,
    ThemeMode? themeMode,
  }) {
    return AppSettings(
      saveToGallery: saveToGallery ?? this.saveToGallery,
      imageQuality: imageQuality ?? this.imageQuality,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}
