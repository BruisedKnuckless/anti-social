import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Opens [AsBottomSheet] content over the current screen (the screen below is
/// kept alive, so the WebView is not reloaded).
Future<T?> showAsBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final c = AsColors.of(context);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    elevation: 0,
    builder: builder,
  );
}

/// Sheet layout: handle, optional title, content, bottom inset padding.
class AsBottomSheet extends StatelessWidget {
  const AsBottomSheet({super.key, this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(AsRadius.lg)),
      ),
      padding: EdgeInsets.only(bottom: bottomInset + AsSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AsSpacing.sm),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(AsRadius.pill),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AsSpacing.lg, AsSpacing.lg, AsSpacing.lg, AsSpacing.sm),
              child: Text(title!,
                  style: AsTextStyles.title.copyWith(color: c.textPrimary)),
            )
          else
            const SizedBox(height: AsSpacing.md),
          Flexible(child: child),
        ],
      ),
    );
  }
}
