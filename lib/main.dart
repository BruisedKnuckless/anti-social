import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'platform/system_ui.dart';
import 'screens/gallery_screen.dart';
import 'screens/web_screen.dart';
import 'services/script_builder.dart';
import 'services/settings_service.dart';

/// Debug-only widget gallery: `flutter run --dart-define=GALLERY=true`.
const bool _showGallery = bool.fromEnvironment('GALLERY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureSystemUi();
  final settings = await SettingsService.load();
  final scripts = await ScriptBuilder.load();

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      Provider<ScriptBuilder>.value(value: scripts),
    ],
    child: AsApp(
      home: _showGallery ? const GalleryScreen() : const WebScreen(),
    ),
  ));
}
