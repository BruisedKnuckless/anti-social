import 'package:anti_social/screens/widget_gallery.dart';
import 'package:anti_social/ui/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens render with Flutter's own engine, so one set of images is the
/// parity proof for iOS AND Android. Update with:
///   flutter test --update-goldens test/goldens
void main() {
  for (final brightness in Brightness.values) {
    testWidgets('widget gallery (${brightness.name})', (tester) async {
      tester.view.physicalSize = const Size(390, 2100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(brightness),
          home: const Scaffold(
            body: SingleChildScrollView(
              child: WidgetGalleryContent(interactive: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(WidgetGalleryContent),
        matchesGoldenFile('as_widgets_${brightness.name}.png'),
      );
    });
  }
}
