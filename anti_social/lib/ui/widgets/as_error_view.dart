import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';
import 'as_button.dart';

/// Full-screen offline / error state with a retry button.
class AsErrorView extends StatelessWidget {
  const AsErrorView({
    super.key,
    required this.title,
    required this.message,
    required this.onRetry,
    this.icon = LucideIcons.wifiOff,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return ColoredBox(
      color: c.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AsSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: c.textSecondary),
              ),
              const SizedBox(height: AsSpacing.lg),
              Text(title,
                  textAlign: TextAlign.center,
                  style: AsTextStyles.heading.copyWith(color: c.textPrimary)),
              const SizedBox(height: AsSpacing.sm),
              Text(message,
                  textAlign: TextAlign.center,
                  style: AsTextStyles.body.copyWith(color: c.textSecondary)),
              const SizedBox(height: AsSpacing.xl),
              AsButton(
                label: 'Try again',
                icon: LucideIcons.rotateCw,
                onPressed: onRetry,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
