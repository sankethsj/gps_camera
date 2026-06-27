import 'dart:io';
import 'package:flutter/material.dart';

class GalleryGrid extends StatelessWidget {
  final List<String> photos;

  const GalleryGrid({super.key, required this.photos});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final path = photos[index];
        return GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => _PhotoViewer(path: path)));
          },
          child: Image.file(File(path), fit: BoxFit.cover),
        );
      },
    );
  }
}

class _PhotoViewer extends StatelessWidget {
  final String path;

  const _PhotoViewer({required this.path});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: InteractiveViewer(child: Image.file(File(path)))),
    );
  }
}
