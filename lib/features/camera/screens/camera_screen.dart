import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gps_camera/services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  final CameraService _service = CameraService();
  late final Future<CameraController> _controllerFuture;
  CameraController? _controller;
  bool _isTakingPicture = false;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initializeCamera();
  }

  Future<CameraController> _initializeCamera() async {
    final permission = await Permission.camera.request();
    if (!permission.isGranted) {
      throw CameraException(
        'cameraPermission',
        'Camera permission is required to show the preview.',
      );
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw CameraException('noCamera', 'No camera found on this device.');
    }

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await controller.initialize();
    _controller = controller;
    return controller;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> takePhoto() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);
    try {
      final image = await controller.takePicture();

      // Save the captured image using the service
      final capturedPath = await File(image.path).readAsBytes();
      final dir = await getApplicationDocumentsDirectory();
      final photosDir = Directory(_service.getPhotosDirectory(dir));
      if (!photosDir.existsSync()) photosDir.createSync(recursive: true);

      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final saveFile = File('${photosDir.path}/$fileName');
      await saveFile.writeAsBytes(capturedPath);
    } catch (e) {
      print('Error taking picture: $e');
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
    return Stack(
      children: [
        FutureBuilder<CameraController>(
          future: _controllerFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final controller = snapshot.data!;
              return Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio,
                  child: CameraPreview(controller),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to open camera.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        if (_isTakingPicture)
          const Positioned.fill(
            child: ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}
