import 'package:flutter/material.dart';

/// Design tokens. Every colour, spacing and radius in the Flutter UI comes
/// from here, never hard-coded, so one change updates both platforms.
@immutable
class AsColors extends ThemeExtension<AsColors> {
  const AsColors({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.toggleOff,
    required this.knob,
    required this.snackbarBg,
    required this.snackbarText,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color toggleOff;
  final Color knob;
  final Color snackbarBg;
  final Color snackbarText;
  final Color scrim;

  static const light = AsColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF4F4F6),
    border: Color(0xFFE4E4E8),
    textPrimary: Color(0xFF111114),
    textSecondary: Color(0xFF6B6B76),
    accent: Color(0xFF2F6BFF),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFE5484D),
    toggleOff: Color(0xFFD9D9DF),
    knob: Color(0xFFFFFFFF),
    snackbarBg: Color(0xFF1C1C21),
    snackbarText: Color(0xFFFFFFFF),
    scrim: Color(0x66000000),
  );

  static const dark = AsColors(
    background: Color(0xFF000000),
    surface: Color(0xFF0C0C0E),
    surfaceRaised: Color(0xFF1A1A1E),
    border: Color(0xFF26262B),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF9A9AA5),
    accent: Color(0xFF5B8CFF),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFFF6369),
    toggleOff: Color(0xFF3A3A40),
    knob: Color(0xFFFFFFFF),
    snackbarBg: Color(0xFFF5F5F7),
    snackbarText: Color(0xFF111114),
    scrim: Color(0x99000000),
  );

  static AsColors of(BuildContext context) =>
      Theme.of(context).extension<AsColors>() ?? light;

  @override
  AsColors copyWith() => this;

  @override
  AsColors lerp(ThemeExtension<AsColors>? other, double t) {
    if (other is! AsColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AsColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      toggleOff: l(toggleOff, other.toggleOff),
      knob: l(knob, other.knob),
      snackbarBg: l(snackbarBg, other.snackbarBg),
      snackbarText: l(snackbarText, other.snackbarText),
      scrim: l(scrim, other.scrim),
    );
  }
}

abstract final class AsSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class AsRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
  static const double pill = 999;
}

abstract final class AsSizes {
  static const double topBarHeight = 48;
  static const double iconButton = 40;
  static const double icon = 22;
  static const double progressBar = 2;
}

abstract final class AsTextStyles {
  static const String fontFamily = 'Inter';

  static const title = TextStyle(
      fontFamily: fontFamily, fontSize: 17, fontWeight: FontWeight.w600, height: 1.25);
  static const heading = TextStyle(
      fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, height: 1.25);
  static const body = TextStyle(
      fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w400, height: 1.35);
  static const label = TextStyle(
      fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, height: 1.2);
  static const caption = TextStyle(
      fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w400, height: 1.3);
}
