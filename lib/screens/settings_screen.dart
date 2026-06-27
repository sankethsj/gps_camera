import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _saveToGallery = true;
  int _imageQuality = 85;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Camera Settings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Save to Gallery'),
          subtitle: const Text('Automatically save photos to device gallery'),
          value: _saveToGallery,
          onChanged: (value) {
            setState(() => _saveToGallery = value);
          },
        ),
        const SizedBox(height: 24),
        Text('Image Quality', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Slider(
          value: _imageQuality.toDouble(),
          min: 50,
          max: 100,
          divisions: 10,
          label: '$_imageQuality%',
          onChanged: (value) {
            setState(() => _imageQuality = value.toInt());
          },
        ),
        Text(
          'Current: $_imageQuality%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
