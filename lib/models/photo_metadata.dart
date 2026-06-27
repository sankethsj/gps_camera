import 'dart:io';

class PhotoMetadata {
  final String path;
  final DateTime timestamp;

  PhotoMetadata({required this.path, required this.timestamp});

  factory PhotoMetadata.fromFile(File file) {
    final ts = file.existsSync() ? file.lastModifiedSync() : DateTime.now();
    return PhotoMetadata(path: file.path, timestamp: ts);
  }
}
