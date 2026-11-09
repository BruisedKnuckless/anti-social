// The ONLY cupertino import allowed in lib/: the shared page transition.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'tokens.dart';

/// The ONE theme used on both iOS and Android.
///
/// `platform` is fixed so Flutter uses the same scroll physics, text
/// selection handles and defaults everywhere, and both platforms use the
/// same page transition.
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AsColors.dark : AsColors.light;
  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: c.onAccent,
    surface: c.surface,
    onSurface: c.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    platform: TargetPlatform.iOS, // fixed for BOTH platforms
    fontFamily: AsTextStyles.fontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    splashFactory: NoSplash.splashFactory, // same tap feedback everywhere
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(), // same!
    }),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.3),
      selectionHandleColor: c.accent,
    ),
    extensions: [c],
  );
}

/// Same scroll feel on both platforms: iOS-style bounce, no Android glow or
/// stretch, no platform scrollbars.
class AsScrollBehavior extends ScrollBehavior {
  const AsScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;

  @override
  Widget buildScrollbar(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
