import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Thin loading bar under the top bar. Fades out when [progress] reaches 1.
class AsProgressBar extends StatelessWidget {
  const AsProgressBar({super.key, required this.progress});

  /// 0.0 – 1.0
  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final done = progress >= 1.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: done ? 0 : 1,
      child: SizedBox(
        height: AsSizes.progressBar,
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: AsSizes.progressBar,
          color: c.accent,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
