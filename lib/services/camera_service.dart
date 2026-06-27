import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  Future<bool> _requestPermissions() async {
    final statusCamera = await Permission.camera.request();
    final statusStorage = Platform.isIOS
        ? await Permission.photos.request()
        : await Permission.storage.request();
    return statusCamera.isGranted && statusStorage.isGranted;
  }

  String getPhotosDirectory(Directory appDocDir) {
    return p.join(appDocDir.path, 'photos');
  }

  Future<String?> pickAndSaveImage(BuildContext context) async {
    final ok = await _requestPermissions();
    if (!ok) return null;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return null;
    if (!context.mounted) return null;

    final capturedPath = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => CameraCaptureScreen(camera: cameras.first),
      ),
    );
    if (capturedPath == null) return null;

    final bytes = await File(capturedPath).readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

    final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File(p.join(photosDir.path, fileName));
    await file.writeAsBytes(bytes);

    return file.path;
  }

  Future<List<String>> listSavedPhotos() async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!photosDir.existsSync()) return [];
    final files = photosDir.listSync().whereType<File>().toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    return files.map((f) => f.path).toList();
  }
}

class CameraCaptureScreen extends StatefulWidget {
  const CameraCaptureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  late final CameraController _controller;
  late final Future<void> _initializeControllerFuture;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_controller.value.isInitialized || _controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);
    try {
      final image = await _controller.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop(image.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture photo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTakingPicture = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Photo')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            );
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to open camera.'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isTakingPicture ? null : _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
