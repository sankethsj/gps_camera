import 'dart:io';
import 'package:gps_camera/models/photo_metadata.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CameraService {
  Future<PhotoMetadata> savePhoto(File sourceFile, {int quality = 85}) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!photosDir.existsSync()) {
      await photosDir.create(recursive: true);
    }

    final timestamp = DateTime.now();
    final fileName = '${timestamp.millisecondsSinceEpoch}.jpg';
    final targetFile = File(p.join(photosDir.path, fileName));

    final sourceBytes = await sourceFile.readAsBytes();
    final decodedImage = img.decodeImage(sourceBytes);

    if (decodedImage != null) {
      final encodedBytes = img.encodeJpg(
        decodedImage,
        quality: quality.clamp(1, 100),
      );
      await targetFile.writeAsBytes(encodedBytes, flush: true);
    } else {
      await sourceFile.copy(targetFile.path);
    }

    return PhotoMetadata(path: targetFile.path, timestamp: timestamp);
  }

  Future<List<PhotoMetadata>> listSavedPhotos() async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!photosDir.existsSync()) return [];

    final files = photosDir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files.map(PhotoMetadata.fromFile).toList();
  }

  Future<void> deletePhotos(List<PhotoMetadata> photos) async {
    for (final photo in photos) {
      final file = File(photo.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
