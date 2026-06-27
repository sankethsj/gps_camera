import 'dart:io';
import 'package:gps_camera/models/photo_metadata.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class CameraService {
  Future<PhotoMetadata> savePhoto(File sourceFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!photosDir.existsSync()) {
      await photosDir.create(recursive: true);
    }

    final timestamp = DateTime.now();
    final fileName =
        '${timestamp.millisecondsSinceEpoch}${p.extension(sourceFile.path)}';
    final targetFile = File(p.join(photosDir.path, fileName));

    await sourceFile.copy(targetFile.path);

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
}
