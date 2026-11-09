import 'package:flutter/material.dart';

import 'tokens.dart';

/// One ThemeData for iOS and Android. Every default that Flutter changes per
/// platform is pinned here, so both builds render the same pixels.
ThemeData buildTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AsColors.dark : AsColors.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: c.onDanger,
    surface: c.surface,
    onSurface: c.textPrimary,
    onSurfaceVariant: c.textSecondary,
    surfaceContainerLowest: c.background,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceMuted,
    surfaceContainerHighest: c.surfaceMuted,
    outline: c.border,
    outlineVariant: c.border,
    shadow: c.shadow,
    scrim: c.scrim,
    surfaceTint: Colors.transparent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    // Fixed for BOTH platforms: same scroll physics, text selection handles
    // and default behaviours.
    platform: TargetPlatform.iOS,
    fontFamily: AsTextStyles.fontFamily,
    colorScheme: scheme,
    scaffoldBackgroundColor: c.background,
    canvasColor: c.background,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
    }),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: c.background,
      foregroundColor: c.textPrimary,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: c.accent,
      selectionColor: c.accent.withValues(alpha: 0.3),
      selectionHandleColor: c.accent,
    ),
    extensions: [c],
  );
}

/// Same scroll feel everywhere: bounce, no Android glow or stretch.
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
