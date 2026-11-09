import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import 'as_button.dart';

/// Our dialog (never `showAdaptiveDialog`). Returns true for the primary
/// action, false for the secondary one, null if dismissed.
class AsDialog extends StatelessWidget {
  const AsDialog({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.secondaryLabel,
  });

  final String title;
  final String message;
  final String primaryLabel;
  final String? secondaryLabel;

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required String primaryLabel,
    String? secondaryLabel,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: AsColors.of(context).scrim,
      builder: (_) => AsDialog(
        title: title,
        message: message,
        primaryLabel: primaryLabel,
        secondaryLabel: secondaryLabel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return Dialog(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(AsSpacing.xl),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AsRadius.lg)),
      child: Padding(
        padding: const EdgeInsets.all(AsSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AsTextStyles.heading.copyWith(color: c.textPrimary)),
            const SizedBox(height: AsSpacing.sm),
            Text(message, style: AsTextStyles.body.copyWith(color: c.textSecondary)),
            const SizedBox(height: AsSpacing.xl),
            AsButton(
              label: primaryLabel,
              expand: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: AsSpacing.sm),
              AsButton(
                label: secondaryLabel!,
                expand: true,
                variant: AsButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
