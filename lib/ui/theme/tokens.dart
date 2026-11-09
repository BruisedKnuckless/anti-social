import 'package:flutter/material.dart';

/// Colour tokens, one set per brightness. Read with `AsColors.of(context)`.
@immutable
class AsColors extends ThemeExtension<AsColors> {
  const AsColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.onDanger,
    required this.switchTrackOff,
    required this.scrim,
    required this.shadow,
    required this.webBackground,
  });

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color onAccent;
  final Color danger;
  final Color onDanger;
  final Color switchTrackOff;
  final Color scrim;
  final Color shadow;

  /// Behind the WebView and under the system bars on the web screen.
  /// Matches Instagram's own page background so the bars blend in.
  final Color webBackground;

  static const light = AsColors(
    background: Color(0xFFFAFAF7),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF1F1EC),
    border: Color(0xFFE4E4DD),
    textPrimary: Color(0xFF16181A),
    textSecondary: Color(0xFF6B6F72),
    accent: Color(0xFF3F7A5E),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC2413A),
    onDanger: Color(0xFFFFFFFF),
    switchTrackOff: Color(0xFFD5D6CF),
    scrim: Color(0x66000000),
    shadow: Color(0x1F000000),
    webBackground: Color(0xFFFFFFFF),
  );

  static const dark = AsColors(
    background: Color(0xFF0E0F10),
    surface: Color(0xFF17191A),
    surfaceMuted: Color(0xFF222527),
    border: Color(0xFF2C3033),
    textPrimary: Color(0xFFF2F2EE),
    textSecondary: Color(0xFF9A9FA2),
    accent: Color(0xFF6FB28F),
    onAccent: Color(0xFF0E0F10),
    danger: Color(0xFFE5675F),
    onDanger: Color(0xFF0E0F10),
    switchTrackOff: Color(0xFF3A3E41),
    scrim: Color(0x99000000),
    shadow: Color(0x66000000),
    webBackground: Color(0xFF000000),
  );

  static AsColors of(BuildContext context) =>
      Theme.of(context).extension<AsColors>()!;

  @override
  AsColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? accent,
    Color? onAccent,
    Color? danger,
    Color? onDanger,
    Color? switchTrackOff,
    Color? scrim,
    Color? shadow,
    Color? webBackground,
  }) =>
      AsColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        border: border ?? this.border,
        textPrimary: textPrimary ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        danger: danger ?? this.danger,
        onDanger: onDanger ?? this.onDanger,
        switchTrackOff: switchTrackOff ?? this.switchTrackOff,
        scrim: scrim ?? this.scrim,
        shadow: shadow ?? this.shadow,
        webBackground: webBackground ?? this.webBackground,
      );

  @override
  AsColors lerp(AsColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AsColors(
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceMuted: l(surfaceMuted, other.surfaceMuted),
      border: l(border, other.border),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      switchTrackOff: l(switchTrackOff, other.switchTrackOff),
      scrim: l(scrim, other.scrim),
      shadow: l(shadow, other.shadow),
      webBackground: l(webBackground, other.webBackground),
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

abstract final class AsDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration snackbar = Duration(milliseconds: 2500);
}

/// Text styles without colour; colour comes from [AsColors] at use site.
abstract final class AsTextStyles {
  static const String fontFamily = 'Inter';

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.4,
    fontWeight: FontWeight.w400,
  );
  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
  );
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
  );
}
