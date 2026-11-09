import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/blocker_config.dart';
import '../services/settings_service.dart';
import '../ui/theme/tokens.dart';
import '../ui/widgets/as_bottom_sheet.dart';
import '../ui/widgets/as_button.dart';
import '../ui/widgets/as_dialog.dart';
import '../ui/widgets/as_toggle_tile.dart';

/// How long friction mode makes you wait before a block can be turned off.
const Duration kFrictionDelay = Duration(seconds: 10);

Future<void> showSettingsSheet(BuildContext context) => showAsBottomSheet(
      context,
      builder: (_) => const SettingsSheet(),
    );

/// The blocking toggles. Opened as a sheet over the WebView, so the page is
/// kept alive and changes apply live.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final cfg = settings.config;
    final c = AsColors.of(context);

    Future<void> set(String name, bool value,
        BlockerConfig Function(bool) apply) async {
      // Turning a block ON is instant. Turning it OFF needs a pause.
      if (!value) {
        final ok = await confirmTurnOff(context, name);
        if (!ok) return;
      }
      await settings.update(apply(value));
    }

    return AsBottomSheet(
      title: 'Blocking',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AsToggleTile(
              title: 'Block Reels',
              subtitle: 'Reels tab, reels in your feed and reel links',
              value: cfg.blockReels,
              onChanged: (v) =>
                  set('Reels', v, (v) => cfg.copyWith(blockReels: v)),
            ),
            AsToggleTile(
              title: 'Block Stories',
              subtitle: 'The stories row at the top of your feed',
              value: cfg.blockStories,
              onChanged: (v) =>
                  set('Stories', v, (v) => cfg.copyWith(blockStories: v)),
            ),
            AsToggleTile(
              title: 'Block Explore',
              subtitle: 'The Explore grid. Search still works',
              value: cfg.blockExplore,
              onChanged: (v) =>
                  set('Explore', v, (v) => cfg.copyWith(blockExplore: v)),
            ),
            AsToggleTile(
              title: 'Block suggested posts',
              subtitle: 'Posts from accounts you don\'t follow',
              value: cfg.blockSuggested,
              onChanged: (v) => set(
                  'suggested posts', v, (v) => cfg.copyWith(blockSuggested: v)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AsSpacing.lg, AsSpacing.md, AsSpacing.lg, 0),
              child: Text(
                'Turning a block off makes you wait '
                '${kFrictionDelay.inSeconds} seconds.',
                style: AsTextStyles.caption.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Friction mode: a countdown before a block can be switched off.
/// Returns true only if the user waits it out and confirms.
Future<bool> confirmTurnOff(BuildContext context, String feature) async {
  final result = await showAsDialog<bool>(
    context,
    barrierDismissible: true,
    builder: (_) => _FrictionDialog(feature: feature),
  );
  return result ?? false;
}

class _FrictionDialog extends StatefulWidget {
  const _FrictionDialog({required this.feature});

  final String feature;

  @override
  State<_FrictionDialog> createState() => _FrictionDialogState();
}

class _FrictionDialogState extends State<_FrictionDialog> {
  late int _left = kFrictionDelay.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _left--);
      if (_left <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ready = _left <= 0;
    return AsDialog(
      title: 'Turn off the ${widget.feature} block?',
      message: 'Take a breath. Is this what you opened the app for?',
      actions: [
        AsButton(
          label: 'Keep blocking',
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AsButton(
          label: ready ? 'Turn off' : 'Turn off ($_left)',
          variant: AsButtonVariant.secondary,
          onPressed: ready ? () => Navigator.of(context).pop(true) : null,
        ),
      ],
    );
  }
}
