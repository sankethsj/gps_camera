import 'package:flutter/material.dart';
import 'package:gps_camera/services/settings_service.dart';
import 'screens/camera_screen.dart';
import 'screens/gallery_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final SettingsService _settingsService = SettingsService();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final settings = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _themeMode = settings.themeMode;
    });
  }

  Future<void> _updateThemeMode(ThemeMode value) async {
    await _settingsService.saveThemeMode(value);
    if (!mounted) return;
    setState(() {
      _themeMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color seedColor = Color.fromARGB(255, 21, 49, 80);

    final ColorScheme lightScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );

    final ThemeData light = ThemeData(
      colorScheme: lightScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: lightScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: lightScheme.primary,
        foregroundColor: lightScheme.onPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: lightScheme.onPrimary,
          fontSize: 20,
        ),
      ),
      textTheme: ThemeData().textTheme.apply(
        bodyColor: lightScheme.onSurface,
        displayColor: lightScheme.onSurface,
      ),
    );

    final ColorScheme darkScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );

    final ThemeData dark = ThemeData(
      colorScheme: darkScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: darkScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkScheme.primary,
        foregroundColor: darkScheme.onPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: darkScheme.onPrimary,
          fontSize: 20,
        ),
      ),
      textTheme: ThemeData(brightness: Brightness.dark).textTheme.apply(
        bodyColor: darkScheme.onSurface,
        displayColor: darkScheme.onSurface,
      ),
    );

    return MaterialApp(
      title: 'GPS Camera',
      theme: light,
      darkTheme: dark,
      themeMode: _themeMode,
      home: HomePage(onThemeChanged: _updateThemeMode),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onThemeChanged});

  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<CameraScreenState> _cameraKey =
      GlobalKey<CameraScreenState>();
  int _selectedIndex = 1;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final bool isTakingPicture =
        _cameraKey.currentState?.isTakingPicture ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'GPS Camera',
          style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.surfaceBright,
        elevation: 0,
      ),
      body: _getBody(),
      bottomNavigationBar: BottomAppBar(
        color: colors.surface,
        height: 120,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              tooltip: 'Gallery',
              selectedIcon: const Icon(Icons.photo_library),
              icon: const Icon(Icons.photo_library_outlined),
              isSelected: _selectedIndex == 0,
              onPressed: () => setState(() => _selectedIndex = 0),
            ),
            _selectedIndex == 1
                ? GestureDetector(
                    onTap: isTakingPicture
                        ? null
                        : () => _cameraKey.currentState?.takePhoto(),
                    child: Opacity(
                      opacity: isTakingPicture ? 0.5 : 1.0,
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.primary, width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      if (_selectedIndex != 1) {
                        setState(() => _selectedIndex = 1);
                        return;
                      }
                    },
                    child: Opacity(
                      opacity: 0.7,
                      child: Container(
                        width: 72,
                        height: 72,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.camera_alt_outlined,
                            size: 30,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ),
            IconButton(
              tooltip: 'Settings',
              selectedIcon: const Icon(Icons.settings),
              icon: const Icon(Icons.settings_outlined),
              isSelected: _selectedIndex == 2,
              onPressed: () => setState(() => _selectedIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return const GalleryScreen();
      case 1:
        return CameraScreen(key: _cameraKey);
      case 2:
        return SettingsScreen(onThemeChanged: widget.onThemeChanged);
      default:
        return CameraScreen(key: _cameraKey);
    }
  }
}
