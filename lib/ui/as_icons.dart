import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart' show Icons;

/// The only icon set in the app (Material Icons, bundled with Flutter).
/// Screens use these names, never `Icons.*` or `CupertinoIcons.*` directly.
abstract final class AsIcons {
  static const IconData settings = Icons.tune_rounded;
  static const IconData back = Icons.arrow_back_ios_new_rounded;
  static const IconData close = Icons.close_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData offline = Icons.wifi_off_rounded;
  static const IconData blocked = Icons.block_rounded;
  static const IconData timer = Icons.hourglass_bottom_rounded;
}
