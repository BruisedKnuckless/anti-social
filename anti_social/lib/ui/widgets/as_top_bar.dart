import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// App top bar: leading actions, centred title, trailing actions.
/// Draws behind the status bar (edge-to-edge) and pads itself below it.
class AsTopBar extends StatelessWidget {
  const AsTopBar({
    super.key,
    required this.title,
    this.leading = const [],
    this.trailing = const [],
    this.onTitleLongPress,
  });

  final String title;
  final List<Widget> leading;
  final List<Widget> trailing;
  final VoidCallback? onTitleLongPress;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.only(top: topInset),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border, width: 0.5)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AsSizes.topBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AsSpacing.xs),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: Row(
                  children: [
                    ...leading,
                    const Spacer(),
                    ...trailing,
                  ],
                ),
              ),
              GestureDetector(
                onLongPress: onTitleLongPress,
                child: Text(
                  title,
                  style: AsTextStyles.title.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
