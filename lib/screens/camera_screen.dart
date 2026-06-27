import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'dart:io';

import 'package:gps_camera/models/camera_overlay_data.dart';
import 'package:gps_camera/services/camera_service.dart';
import 'package:gps_camera/services/image_overlay_painter_service.dart';
import 'package:gps_camera/services/location_overlay_service.dart';
import 'package:gps_camera/widgets/camera_overlay.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => CameraScreenState();
}

class CameraScreenState extends State<CameraScreen> {
  late Future<CameraController> _controllerFuture;
  late Stream<CameraOverlayData> _overlayDataStream;
  StreamSubscription<CameraOverlayData>? _overlayDataSubscription;
  CameraOverlayData? _latestOverlayData;
  CameraController? _controller;
  final LocationOverlayService _locationOverlayService =
      const LocationOverlayService();
  final ImageOverlayPainterService _imageOverlayPainterService =
      const ImageOverlayPainterService();
  final CameraService _cameraService = CameraService();
  bool _isTakingPicture = false;
  bool _isFlashOn = false;

  bool get isTakingPicture => _isTakingPicture;

  @override
  void initState() {
    super.initState();
    _controllerFuture = _initializeCamera();
    _overlayDataStream = _locationOverlayService
        .watchOverlayData()
        .asBroadcastStream();
    _overlayDataSubscription = _overlayDataStream.listen(
      (data) => _latestOverlayData = data,
      onError: (_) {},
    );
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
    _overlayDataSubscription?.cancel();
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
      final overlayData =
          _latestOverlayData ?? await _locationOverlayService.getOverlayData();
      if (!mounted) return;
      final previewSize = context.size ?? MediaQuery.sizeOf(context);
      final imageWithOverlayPath = await _imageOverlayPainterService
          .paintOverlayOnImage(
            imagePath: image.path,
            overlayData: overlayData,
            previewSize: previewSize,
          );

      await _cameraService.savePhoto(File(imageWithOverlayPath));

      // Save to Album
      String album = "GPS Camera";
      debugPrint(imageWithOverlayPath);

      await Gal.putImage(imageWithOverlayPath, album: album);

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
                mini: true,
                backgroundColor: Theme.of(context).primaryColorDark,
                heroTag: 'camera_flash',
                onPressed: _toggleFlash,
                child: _isFlashOn
                    ? const Icon(Icons.flash_on)
                    : const Icon(Icons.flash_off),
              ),
              SizedBox(width: 8),
              FloatingActionButton(
                mini: true,
                backgroundColor: Theme.of(context).primaryColorDark,
                heroTag: 'flip_camera',
                onPressed: _switchCamera,
                child: const Icon(Icons.flip_camera_android),
              ),
            ],
          ),
        ),
        CameraOverlay(overlayDataStream: _overlayDataStream),
      ],
    );
  }
}
