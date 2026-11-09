import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'screens/web_screen.dart';
import 'services/settings_service.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Edge-to-edge on both platforms; insets are handled with padding/SafeArea.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final settings = await SettingsService.load();
  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const AntiSocialApp(),
    ),
  );
}

class AntiSocialApp extends StatelessWidget {
  const AntiSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AntiSocial',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      scrollBehavior: const AsScrollBehavior(),
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final dark = mq.platformBrightness == Brightness.dark;
        final iconBrightness = dark ? Brightness.light : Brightness.dark;
        return MediaQuery(
          // Clamp text scaling so huge system fonts don't break layouts.
          data: mq.copyWith(
              textScaler: mq.textScaler.clamp(maxScaleFactor: kMaxTextScale)),
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: iconBrightness, // Android
              statusBarBrightness: dark ? Brightness.dark : Brightness.light, // iOS
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarDividerColor: Colors.transparent,
              systemNavigationBarIconBrightness: iconBrightness,
              systemNavigationBarContrastEnforced: false,
            ),
            child: child!,
          ),
        );
      },
      home: const WebScreen(),
    );
  }
}
