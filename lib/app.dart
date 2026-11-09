import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'platform/system_ui.dart';
import 'ui/theme/app_theme.dart';

/// Root widget: one theme for both platforms, light/dark from the system,
/// same scroll behaviour, clamped text scale, transparent system bars.
class AsApp extends StatelessWidget {
  const AsApp({super.key, required this.home});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anti-Social',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      scrollBehavior: const AsScrollBehavior(),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        return AnnotatedRegion(
          value: overlayStyleFor(brightness),
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: kMaxTextScale,
            child: child!,
          ),
        );
      },
      home: home,
    );
  }
}
