import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../ui/theme/app_theme.dart';
import '../ui/theme/tokens.dart';
import '../ui/widgets/as_bottom_sheet.dart';
import '../ui/widgets/as_button.dart';
import '../ui/widgets/as_dialog.dart';
import '../ui/widgets/as_error_view.dart';
import '../ui/widgets/as_icon_button.dart';
import '../ui/widgets/as_progress_bar.dart';
import '../ui/widgets/as_snackbar.dart';
import '../ui/widgets/as_toggle_tile.dart';
import '../ui/widgets/as_top_bar.dart';

/// Debug screen showing every As* widget in light and dark.
class WidgetGalleryScreen extends StatelessWidget {
  const WidgetGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return Scaffold(
      backgroundColor: c.background,
      body: Column(
        children: [
          AsTopBar(
            title: 'Widget gallery',
            leading: [
              AsIconButton(
                icon: LucideIcons.chevronLeft,
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Theme(
                  data: buildTheme(Brightness.light),
                  child: const WidgetGalleryContent(),
                ),
                Theme(
                  data: buildTheme(Brightness.dark),
                  child: const WidgetGalleryContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The gallery body. Also used by the golden tests.
class WidgetGalleryContent extends StatelessWidget {
  const WidgetGalleryContent({super.key, this.interactive = true});

  /// False in golden tests (no sheets/dialogs to open).
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(
              AsSpacing.lg, AsSpacing.xl, AsSpacing.lg, AsSpacing.sm),
          child: Text(text.toUpperCase(),
              style: AsTextStyles.caption.copyWith(color: c.textSecondary)),
        );

    return ColoredBox(
      color: c.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          label('Top bar'),
          MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: AsTopBar(
              title: 'AntiSocial',
              leading: [
                AsIconButton(icon: LucideIcons.chevronLeft, tooltip: 'Back', onPressed: () {}),
                AsIconButton(icon: LucideIcons.house, tooltip: 'Home', onPressed: () {}),
              ],
              trailing: [
                AsIconButton(icon: LucideIcons.rotateCw, tooltip: 'Refresh', onPressed: () {}),
                AsIconButton(icon: LucideIcons.slidersHorizontal, tooltip: 'Settings', onPressed: () {}),
              ],
            ),
          ),
          label('Progress bar'),
          const AsProgressBar(progress: 0.6),
          label('Toggle tiles'),
          AsToggleTile(title: 'Reels', subtitle: 'On', value: true, onChanged: (_) {}),
          AsToggleTile(title: 'Stories', subtitle: 'Off', value: false, onChanged: (_) {}),
          const AsToggleTile(title: 'Disabled', value: true, onChanged: null),
          label('Buttons'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AsSpacing.lg),
            child: Wrap(
              spacing: AsSpacing.sm,
              runSpacing: AsSpacing.sm,
              children: [
                AsButton(
                  label: interactive ? 'Open sheet' : 'Primary',
                  onPressed: () {
                    if (!interactive) return;
                    AsBottomSheet.show<void>(context,
                        title: 'Bottom sheet',
                        builder: (_) => Padding(
                              padding: const EdgeInsets.all(AsSpacing.lg),
                              child: Text('Sheet content',
                                  style: AsTextStyles.body.copyWith(color: c.textPrimary)),
                            ));
                  },
                ),
                AsButton(
                  label: interactive ? 'Open dialog' : 'Secondary',
                  variant: AsButtonVariant.secondary,
                  onPressed: () {
                    if (!interactive) return;
                    AsDialog.show(context,
                        title: 'Turn off a block?',
                        message: 'This is the shared dialog.',
                        primaryLabel: 'Keep blocking',
                        secondaryLabel: 'Turn off');
                  },
                ),
                AsButton(
                  label: 'Snackbar',
                  icon: LucideIcons.shieldCheck,
                  variant: AsButtonVariant.secondary,
                  onPressed: () {
                    if (interactive) AsSnackbar.show(context, 'Reels are blocked', icon: LucideIcons.shieldCheck);
                  },
                ),
                const AsButton(label: 'Disabled', onPressed: null),
              ],
            ),
          ),
          label('Snackbar content'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AsSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AsSpacing.lg),
              decoration: BoxDecoration(
                color: c.snackbarBg,
                borderRadius: BorderRadius.circular(AsRadius.md),
              ),
              child: const AsSnackbarContent(
                  message: 'Reels are blocked', icon: LucideIcons.shieldCheck),
            ),
          ),
          label('Dialog'),
          const IgnorePointer(
            child: AsDialog(
              title: 'Turn off a block?',
              message: 'This is the shared dialog.',
              primaryLabel: 'Keep blocking',
              secondaryLabel: 'Turn off',
            ),
          ),
          label('Error view'),
          SizedBox(
            height: 320,
            child: AsErrorView(
              title: "You're offline",
              message: 'Check your connection and try again.',
              onRetry: () {},
            ),
          ),
        ],
      ),
    );
  }
}
