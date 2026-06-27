class AppSettings {
  const AppSettings({required this.saveToGallery, required this.imageQuality});

  final bool saveToGallery;
  final int imageQuality;

  AppSettings copyWith({bool? saveToGallery, int? imageQuality}) {
    return AppSettings(
      saveToGallery: saveToGallery ?? this.saveToGallery,
      imageQuality: imageQuality ?? this.imageQuality,
    );
  }
}
