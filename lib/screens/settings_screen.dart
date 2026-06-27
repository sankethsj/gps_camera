import 'package:flutter/material.dart';
import 'package:gps_camera/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.onThemeChanged});

  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  bool _saveToGallery = true;
  int _imageQuality = 85;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _saveToGallery = settings.saveToGallery;
      _imageQuality = settings.imageQuality;
      _themeMode = settings.themeMode;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    await _settingsService.saveSaveToGallery(_saveToGallery);
    await _settingsService.saveImageQuality(_imageQuality);
  }

  Future<void> _saveThemeMode(ThemeMode value) async {
    setState(() => _themeMode = value);
    await _settingsService.saveThemeMode(value);
    widget.onThemeChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Camera Settings', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Save to Gallery'),
          subtitle: const Text('Automatically save photos to device gallery'),
          value: _saveToGallery,
          onChanged: (value) async {
            setState(() => _saveToGallery = value);
            await _saveSettings();
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
          onChangeEnd: (_) async {
            await _saveSettings();
          },
        ),
        Text(
          'Current: $_imageQuality%',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),

        Text('Theme', style: Theme.of(context).textTheme.titleMedium),

        const SizedBox(height: 12),

        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto),
              label: Text('System'),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode),
              label: Text('Dark'),
            ),
          ],
          selected: {_themeMode},
          onSelectionChanged: (selection) async {
            await _saveThemeMode(selection.first);
          },
        ),
      ],
    );
  }
}
