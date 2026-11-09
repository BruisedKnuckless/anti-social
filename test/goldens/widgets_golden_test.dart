// Parity proof: every As* widget is rendered as Android AND as iOS, and both
// must match the SAME golden image. If they differ, a platform default leaked.
//
// Regenerate after an intended visual change:
//   flutter test --update-goldens test/goldens

import 'package:anti_social/ui/as_icons.dart';
import 'package:anti_social/ui/theme/app_theme.dart';
import 'package:anti_social/ui/theme/tokens.dart';
import 'package:anti_social/ui/widgets/as_bottom_sheet.dart';
import 'package:anti_social/ui/widgets/as_button.dart';
import 'package:anti_social/ui/widgets/as_dialog.dart';
import 'package:anti_social/ui/widgets/as_error_view.dart';
import 'package:anti_social/ui/widgets/as_fab.dart';
import 'package:anti_social/ui/widgets/as_progress_bar.dart';
import 'package:anti_social/ui/widgets/as_snackbar.dart';
import 'package:anti_social/ui/widgets/as_toggle_tile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _loadFont(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final a in assets) {
    loader.addFont(rootBundle.load(a));
  }
  await loader.load();
}

class _Case {
  const _Case(this.name, this.size, this.build, {this.afterPump});
  final String name;
  final Size size;
  final WidgetBuilder build;
  final Future<void> Function(WidgetTester tester)? afterPump;
}

final _cases = <_Case>[
  _Case('toggle_tiles', const Size(390, 260), (context) {
    final c = AsColors.of(context);
    return Container(
      color: c.surface,
      child: const Column(mainAxisSize: MainAxisSize.min, children: [
        AsToggleTile(
          title: 'Block Reels',
          subtitle: 'Hide the Reels tab and reels in your feed',
          value: true,
          onChanged: _noopBool,
        ),
        AsToggleTile(title: 'Block Stories', value: false, onChanged: _noopBool),
        AsToggleTile(title: 'Disabled', value: true, onChanged: null),
      ]),
    );
  }),
  _Case('buttons', const Size(390, 300), (_) {
    return const Padding(
      padding: EdgeInsets.all(AsSpacing.lg),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        AsButton(label: 'Primary', onPressed: _noop),
        SizedBox(height: AsSpacing.sm),
        AsButton(
            label: 'Secondary',
            variant: AsButtonVariant.secondary,
            onPressed: _noop),
        SizedBox(height: AsSpacing.sm),
        AsButton(
            label: 'Danger', variant: AsButtonVariant.danger, onPressed: _noop),
        SizedBox(height: AsSpacing.sm),
        AsButton(
            label: 'Retry',
            icon: AsIcons.refresh,
            expand: false,
            onPressed: null),
      ]),
    );
  }),
  _Case('bottom_sheet', const Size(390, 320), (_) {
    return const Align(
      alignment: Alignment.bottomCenter,
      child: AsBottomSheet(
        title: 'Blocking',
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          AsToggleTile(title: 'Block Reels', value: true, onChanged: _noopBool),
          AsToggleTile(
              title: 'Block Explore', value: false, onChanged: _noopBool),
        ]),
      ),
    );
  }),
  _Case('dialog', const Size(390, 400), (_) {
    return const AsDialog(
      title: 'Turn off Reels block?',
      message: 'Take a breath. You can turn it off in 10 s.',
      actions: [
        AsButton(label: 'Keep blocking', onPressed: _noop),
        AsButton(
            label: 'Turn off (10)',
            variant: AsButtonVariant.secondary,
            onPressed: null),
      ],
    );
  }),
  _Case('error_view', const Size(390, 420), (_) {
    return const AsErrorView(onRetry: _noop);
  }),
  _Case('fab_progress', const Size(390, 140), (context) {
    return const Column(mainAxisSize: MainAxisSize.min, children: [
      AsProgressBar(progress: 0.6),
      SizedBox(height: AsSpacing.xl),
      AsFab(icon: AsIcons.settings, semanticLabel: 'Settings', onPressed: _noop),
    ]);
  }),
  _Case(
    'snackbar',
    const Size(390, 200),
    (context) => Builder(
      builder: (ctx) => AsButton(
        label: 'Show',
        onPressed: () =>
            AsSnackbar.show(ctx, 'Reels are blocked 🙂', icon: AsIcons.blocked),
      ),
    ),
    afterPump: (tester) async {
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    },
  ),
];

void _noop() {}
void _noopBool(bool _) {}

void main() {
  setUpAll(() async {
    await _loadFont('Inter', [
      'assets/fonts/Inter-Regular.ttf',
      'assets/fonts/Inter-SemiBold.ttf',
    ]);
    await _loadFont('MaterialIcons', ['fonts/MaterialIcons-Regular.otf']);
  });

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final brightness in Brightness.values) {
      for (final tc in _cases) {
        testWidgets('${tc.name} ${brightness.name} as ${platform.name}',
            (tester) async {
          debugDefaultTargetPlatformOverride = platform;
          try {
            tester.view.devicePixelRatio = 1;
            tester.view.physicalSize = tc.size;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildTheme(brightness),
              scrollBehavior: const AsScrollBehavior(),
              home: Scaffold(body: Center(child: Builder(builder: tc.build))),
            ));
            await tester.pumpAndSettle();
            if (tc.afterPump != null) await tc.afterPump!(tester);

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile('${tc.name}_${brightness.name}.png'),
            );

            // Let the snackbar timer finish so no timers are left pending.
            AsSnackbar.hide();
            await tester.pumpWidget(const SizedBox());
          } finally {
            debugDefaultTargetPlatformOverride = null;
          }
        });
      }
    }
  }
}
