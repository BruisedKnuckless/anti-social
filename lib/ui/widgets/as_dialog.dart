import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Opens a dialog with the same fade + scale animation on both platforms.
/// Never `showAdaptiveDialog`.
Future<T?> showAsDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  final c = AsColors.of(context);
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss',
    barrierColor: c.scrim,
    transitionDuration: AsDurations.normal,
    pageBuilder: (ctx, _, _) => builder(ctx),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Dialog layout: title, message (or custom content) and stacked actions.
class AsDialog extends StatelessWidget {
  const AsDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.actions = const [],
  });

  final String title;
  final String? message;
  final Widget? content;

  /// Usually [AsButton]s, stacked full width (primary first).
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AsSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                padding: const EdgeInsets.all(AsSpacing.xl),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(AsRadius.lg),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style:
                            AsTextStyles.title.copyWith(color: c.textPrimary)),
                    if (message != null) ...[
                      const SizedBox(height: AsSpacing.sm),
                      Text(message!,
                          style: AsTextStyles.body
                              .copyWith(color: c.textSecondary)),
                    ],
                    if (content != null) ...[
                      const SizedBox(height: AsSpacing.lg),
                      content!,
                    ],
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: AsSpacing.xl),
                      for (var i = 0; i < actions.length; i++) ...[
                        if (i > 0) const SizedBox(height: AsSpacing.sm),
                        actions[i],
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
