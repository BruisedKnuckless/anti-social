import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Our bottom sheet: rounded top, drag handle, title, scrollable content.
class AsBottomSheet extends StatelessWidget {
  const AsBottomSheet({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
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
      builder: (ctx) => AsBottomSheet(title: title, child: builder(ctx)),
    );
  }

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
      padding: EdgeInsets.only(bottom: bottomInset + AsSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AsSpacing.sm),
          Center(
            child: Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(AsRadius.pill),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AsSpacing.lg, AsSpacing.lg, AsSpacing.lg, AsSpacing.sm),
            child: Text(title,
                style: AsTextStyles.heading.copyWith(color: c.textPrimary)),
          ),
          Flexible(child: SingleChildScrollView(child: child)),
        ],
      ),
    );
  }
}
