import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gps_camera/models/photo_metadata.dart';
import 'package:gps_camera/services/camera_service.dart';
import 'dart:io';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final CameraService _service = CameraService();
  late Future<List<PhotoMetadata>> _photosFuture;
  final Set<String> _selectedPaths = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _photosFuture = _service.listSavedPhotos();
  }

  void _refreshPhotos() {
    setState(() {
      _selectedPaths.clear();
      _photosFuture = _service.listSavedPhotos();
    });
  }

  void _toggleSelection(String path) {
    setState(() {
      if (_selectedPaths.contains(path)) {
        _selectedPaths.remove(path);
      } else {
        _selectedPaths.add(path);
      }
    });
  }

  Future<void> _confirmDelete(List<PhotoMetadata> photos) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete selected photos?'),
          content: const Text(
            'Deleting here will remove the images from the app storage only. It will not delete them from your device gallery.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() {
        _isDeleting = true;
      });

      await _service.deletePhotos(photos);
      _refreshPhotos();

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Widget _buildSelectionBar() {
    if (_selectedPaths.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_selectedPaths.length} selected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedPaths.clear()),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _isDeleting
                ? null
                : () async {
                    final savedPhotos = await _photosFuture;
                    final selectedPhotos = savedPhotos
                        .where((photo) => _selectedPaths.contains(photo.path))
                        .toList();
                    await _confirmDelete(selectedPhotos);
                  },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PhotoMetadata>>(
      future: _photosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.photo_library,
                  size: 96,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No photos yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Take photos to see them here',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        final photos = snapshot.data!;
        return Column(
          children: [
            _buildSelectionBar(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final isSelected = _selectedPaths.contains(photo.path);
                  return GestureDetector(
                    onTap: () async {
                      if (_selectedPaths.isNotEmpty) {
                        _toggleSelection(photo.path);
                        return;
                      }
                      await OpenFilex.open(photo.path);
                    },
                    onLongPress: () => _toggleSelection(photo.path),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            children: [
                              Expanded(
                                child: Image.file(
                                  File(photo.path),
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: Text(
                                  photo.timestamp
                                      .toLocal()
                                      .toString()
                                      .split('.')
                                      .first,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        if (isSelected)
                          const Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.white70,
                              child: Icon(
                                Icons.check_circle,
                                size: 20,
                                color: Colors.green,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
