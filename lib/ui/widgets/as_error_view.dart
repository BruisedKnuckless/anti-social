import 'package:flutter/material.dart';

import '../as_icons.dart';
import '../theme/tokens.dart';
import 'as_button.dart';

/// Full-screen offline / load error message with a retry button.
class AsErrorView extends StatelessWidget {
  const AsErrorView({
    super.key,
    this.title = "Can't load the page",
    this.message = 'Check your internet connection and try again.',
    this.icon = AsIcons.offline,
    required this.onRetry,
  });

  final String title;
  final String message;
  final IconData icon;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return ColoredBox(
      color: c.background,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AsSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 40, color: c.textSecondary),
                const SizedBox(height: AsSpacing.lg),
                Text(title,
                    textAlign: TextAlign.center,
                    style: AsTextStyles.title.copyWith(color: c.textPrimary)),
                const SizedBox(height: AsSpacing.sm),
                Text(message,
                    textAlign: TextAlign.center,
                    style: AsTextStyles.body.copyWith(color: c.textSecondary)),
                const SizedBox(height: AsSpacing.xl),
                AsButton(
                  label: 'Try again',
                  icon: AsIcons.refresh,
                  expand: false,
                  onPressed: onRetry,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
