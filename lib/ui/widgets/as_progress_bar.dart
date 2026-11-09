import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Thin page-loading bar. [progress] is 0..1; it fades out once complete.
class AsProgressBar extends StatelessWidget {
  const AsProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final p = progress.clamp(0.0, 1.0);
    return AnimatedOpacity(
      duration: AsDurations.normal,
      opacity: p >= 1 ? 0 : 1,
      child: SizedBox(
        height: 2,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: p),
            duration: AsDurations.normal,
            curve: Curves.easeOut,
            builder: (_, v, _) => FractionallySizedBox(
              widthFactor: v,
              heightFactor: 1,
              child: ColoredBox(color: c.accent),
            ),
          ),
        ),
      ),
    );
  }
}
