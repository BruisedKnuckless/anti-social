import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Our snackbar, drawn by Flutter (no native toasts), same on both OSes.
abstract final class AsSnackbar {
  static void show(BuildContext context, String message, {IconData? icon}) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(build(context, message, icon: icon));
  }

  static SnackBar build(BuildContext context, String message, {IconData? icon}) {
    final c = AsColors.of(context);
    return SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: c.snackbarBg,
      elevation: 0,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.fromLTRB(
          AsSpacing.lg, 0, AsSpacing.lg, AsSpacing.lg),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AsRadius.md)),
      content: AsSnackbarContent(message: message, icon: icon),
    );
  }
}

class AsSnackbarContent extends StatelessWidget {
  const AsSnackbarContent({super.key, required this.message, this.icon});

  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: c.snackbarText),
          const SizedBox(width: AsSpacing.sm),
        ],
        Expanded(
          child: Text(message,
              style: AsTextStyles.body.copyWith(color: c.snackbarText)),
        ),
      ],
    );
  }
}
