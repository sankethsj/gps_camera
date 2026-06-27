import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:gps_camera/models/camera_overlay_data.dart';
import 'package:gps_camera/painters/camera_overlay_painter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageOverlayPainterService {
  const ImageOverlayPainterService();

  Future<String> paintOverlayOnImage({
    required String imagePath,
    required CameraOverlayData overlayData,
    required Size previewSize,
  }) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final sourceImage = await _decodeImage(imageBytes);
    final imageSize = Size(
      sourceImage.width.toDouble(),
      sourceImage.height.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(sourceImage, Offset.zero, Paint());

    final style = CameraOverlayPaintStyle.forScale(
      _overlayScale(imageSize: imageSize, previewSize: previewSize),
    );
    CameraOverlayPainter.paintOverlay(
      canvas: canvas,
      size: imageSize,
      data: overlayData,
      style: style,
    );

    final picture = recorder.endRecording();
    final composedImage = await picture.toImage(
      sourceImage.width,
      sourceImage.height,
    );
    final pngBytes = await composedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    sourceImage.dispose();
    picture.dispose();
    composedImage.dispose();

    if (pngBytes == null) {
      throw StateError('Unable to encode photo with overlay.');
    }

    final outputPath = await _outputPath();
    await File(outputPath).writeAsBytes(
      pngBytes.buffer.asUint8List(),
      flush: true,
    );
    return outputPath;
  }

  Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }

  double _overlayScale({
    required Size imageSize,
    required Size previewSize,
  }) {
    if (previewSize.width <= 0 || previewSize.height <= 0) {
      return 1;
    }

    return imageSize.width / previewSize.width;
  }

  Future<String> _outputPath() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return p.join(directory.path, 'gps_camera_$timestamp.png');
  }
}
