import 'package:flutter/material.dart';

import '../ui/as_icons.dart';
import '../ui/theme/tokens.dart';
import '../ui/widgets/as_bottom_sheet.dart';
import '../ui/widgets/as_button.dart';
import '../ui/widgets/as_dialog.dart';
import '../ui/widgets/as_error_view.dart';
import '../ui/widgets/as_fab.dart';
import '../ui/widgets/as_progress_bar.dart';
import '../ui/widgets/as_snackbar.dart';
import '../ui/widgets/as_toggle_tile.dart';

/// Debug-only screen that shows every As* widget, for side-by-side
/// parity checks. Not reachable in release builds.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _reels = true;
  bool _stories = false;
  double _progress = 0.6;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    Widget section(String name) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AsSpacing.lg, AsSpacing.xl, AsSpacing.lg, AsSpacing.sm),
          child: Text(name.toUpperCase(),
              style: AsTextStyles.caption.copyWith(color: c.textSecondary)),
        );

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                Padding(
                  padding: const EdgeInsets.all(AsSpacing.lg),
                  child: Text('Widget gallery',
                      style: AsTextStyles.title.copyWith(color: c.textPrimary)),
                ),
                section('Progress bar'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AsSpacing.lg),
                  child: GestureDetector(
                    onTap: () => setState(
                        () => _progress = _progress >= 1 ? 0.2 : _progress + 0.2),
                    child: Container(
                      color: c.surfaceMuted,
                      child: AsProgressBar(progress: _progress),
                    ),
                  ),
                ),
                section('Toggle tiles'),
                Container(
                  color: c.surface,
                  child: Column(children: [
                    AsToggleTile(
                      title: 'Block Reels',
                      subtitle: 'Hide the Reels tab and reels in your feed',
                      value: _reels,
                      onChanged: (v) => setState(() => _reels = v),
                    ),
                    AsToggleTile(
                      title: 'Block Stories',
                      value: _stories,
                      onChanged: (v) => setState(() => _stories = v),
                    ),
                    const AsToggleTile(
                        title: 'Disabled', value: true, onChanged: null),
                  ]),
                ),
                section('Buttons'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AsSpacing.lg),
                  child: Column(children: [
                    AsButton(label: 'Primary', onPressed: () {}),
                    const SizedBox(height: AsSpacing.sm),
                    AsButton(
                        label: 'Secondary',
                        variant: AsButtonVariant.secondary,
                        onPressed: () {}),
                    const SizedBox(height: AsSpacing.sm),
                    AsButton(
                        label: 'Danger',
                        variant: AsButtonVariant.danger,
                        onPressed: () {}),
                    const SizedBox(height: AsSpacing.sm),
                    const AsButton(label: 'Disabled', onPressed: null),
                  ]),
                ),
                section('Overlays'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AsSpacing.lg),
                  child: Column(children: [
                    AsButton(
                      label: 'Show snackbar',
                      variant: AsButtonVariant.secondary,
                      onPressed: () => AsSnackbar.show(
                          context, 'Reels are blocked 🙂',
                          icon: AsIcons.blocked),
                    ),
                    const SizedBox(height: AsSpacing.sm),
                    AsButton(
                      label: 'Show dialog',
                      variant: AsButtonVariant.secondary,
                      onPressed: () => showAsDialog(
                        context,
                        builder: (ctx) => AsDialog(
                          title: 'Turn off Reels block?',
                          message: 'Take a breath. You can turn it off in 10 s.',
                          actions: [
                            AsButton(
                                label: 'Keep blocking',
                                onPressed: () => Navigator.pop(ctx)),
                            AsButton(
                                label: 'Turn off',
                                variant: AsButtonVariant.secondary,
                                onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AsSpacing.sm),
                    AsButton(
                      label: 'Show bottom sheet',
                      variant: AsButtonVariant.secondary,
                      onPressed: () => showAsBottomSheet(
                        context,
                        builder: (_) => AsBottomSheet(
                          title: 'Settings',
                          child: AsToggleTile(
                            title: 'Example toggle',
                            value: true,
                            onChanged: (_) {},
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AsSpacing.sm),
                    AsButton(
                      label: 'Show error view',
                      variant: AsButtonVariant.secondary,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => Scaffold(
                            body: AsErrorView(
                                onRetry: () => Navigator.pop(ctx)),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),
          Positioned(
            right: AsSpacing.lg,
            bottom: MediaQuery.paddingOf(context).bottom + AsSpacing.lg,
            child: AsFab(
              icon: AsIcons.settings,
              semanticLabel: 'Settings',
              onPressed: () =>
                  AsSnackbar.show(context, 'Settings tapped'),
            ),
          ),
        ],
      ),
    );
  }
}
