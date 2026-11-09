import 'package:flutter/services.dart';

/// Edge-to-edge on both platforms: draw behind the status bar and the Android
/// navigation bar; screens handle insets with SafeArea.
Future<void> configureSystemUi() =>
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

/// Transparent bars with icon colour that follows the app's brightness.
SystemUiOverlayStyle overlayStyleFor(Brightness appBrightness) {
  final icons =
      appBrightness == Brightness.dark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: const Color(0x00000000),
    statusBarIconBrightness: icons, // Android
    statusBarBrightness: appBrightness, // iOS
    systemNavigationBarColor: const Color(0x00000000),
    systemNavigationBarDividerColor: const Color(0x00000000),
    systemNavigationBarIconBrightness: icons,
    systemNavigationBarContrastEnforced: false,
  );
}
