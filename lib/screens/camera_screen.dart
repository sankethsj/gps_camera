import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late Future<CameraController> _controllerFuture;
  CameraController? _controller;
  bool _isTakingPicture = false;
  bool _isFlashOn = false;

  bool get isTakingPicture => _isTakingPicture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initializeCamera();
    _isFlashOn = false;
  }

  Future<CameraController> _initializeCamera({
    CameraDescription? preferredCamera,
  }) async {
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

    final selectedCamera = preferredCamera ?? cameras.first;

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller.initialize();
    _controller = controller;

    setState(() {
      _isFlashOn = controller.value.flashMode == FlashMode.torch;
    });

    return controller;
  }

  Future<void> _switchCamera() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isTakingPicture) {
      return;
    }

    final cameras = await availableCameras();
    if (cameras.length < 2) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No second camera available.')),
        );
      }
      return;
    }

    final currentLensDirection = controller.description.lensDirection;
    final nextCamera = cameras.firstWhere(
      (camera) => camera.lensDirection != currentLensDirection,
      orElse: () => cameras.first,
    );

    await controller.dispose();
    _controller = null;

    setState(() {
      _controllerFuture = _initializeCamera(preferredCamera: nextCamera);
    });
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture ||
        _isTakingPicture) {
      return;
    }
    if (controller.value.flashMode == FlashMode.torch) {
      controller.setFlashMode(FlashMode.off);
      _isFlashOn = false;
    } else {
      controller.setFlashMode(FlashMode.torch);
      _isFlashOn = true;
    }
    setState(() {
      _isFlashOn = _isFlashOn;
    });
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
        controller.value.isTakingPicture ||
        _isTakingPicture) {
      return;
    }

    setState(() => _isTakingPicture = true);
    try {
      final image = await controller.takePicture();

      // Save to Album
      String album = "GPS Camera";
      debugPrint(image.path);

      await Gal.putImage(image.path, album: album);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo saved to album: $album.'),
          duration: Durations.short1,
        ),
      );
    } catch (e) {
      debugPrint('Error taking picture: $e');
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final previewSize = controller.value.previewSize;

                  if (previewSize == null) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return SizedBox.expand(
                    child: ClipRect(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: previewSize.height,
                          height: previewSize.width,
                          child: CameraPreview(controller),
                        ),
                      ),
                    ),
                  );
                },
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
        Positioned(
          bottom: 10,
          right: 24,
          child: Row(
            children: [
              FloatingActionButton(
                heroTag: 'camera_flash',
                onPressed: _toggleFlash,
                child: _isFlashOn
                    ? const Icon(Icons.flash_on)
                    : const Icon(Icons.flash_off),
              ),
              SizedBox(width: 10),
              FloatingActionButton(
                heroTag: 'flip_camera',
                onPressed: _switchCamera,
                child: const Icon(Icons.flip_camera_android),
              ),
            ],
          ),
        ),
        const CameraOverlay(),
      ],
    );
  }
}

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 80,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Overlay goes here',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
