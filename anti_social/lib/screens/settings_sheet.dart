import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/blocker_config.dart';
import '../services/settings_service.dart';
import '../ui/theme/tokens.dart';
import '../ui/widgets/as_bottom_sheet.dart';
import '../ui/widgets/as_toggle_tile.dart';
import 'widget_gallery.dart';

/// Feature toggles. Changes save immediately and apply to the page live.
class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) => AsBottomSheet.show<void>(
        context,
        title: 'Blocking',
        builder: (_) => const SettingsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final settings = context.watch<SettingsService>();
    final cfg = settings.config;
    void set(BlockerConfig next) => settings.update(next);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AsToggleTile(
          title: 'Reels',
          subtitle: 'Hide the Reels tab, the Reels feed and profile reels',
          value: cfg.blockReels,
          onChanged: (v) => set(cfg.copyWith(blockReels: v)),
        ),
        AsToggleTile(
          title: 'Videos in your feed',
          subtitle: 'Also hide video posts from people you follow',
          value: cfg.blockFeedVideos,
          onChanged: (v) => set(cfg.copyWith(blockFeedVideos: v)),
        ),
        AsToggleTile(
          title: 'Reels sent in DMs',
          subtitle: "Don't open single reels people send you",
          value: cfg.blockDmReels,
          onChanged: (v) => set(cfg.copyWith(blockDmReels: v)),
        ),
        AsToggleTile(
          title: 'Explore',
          subtitle: 'Open Search instead of the endless Explore grid',
          value: cfg.blockExplore,
          onChanged: (v) => set(cfg.copyWith(blockExplore: v)),
        ),
        AsToggleTile(
          title: 'Stories',
          subtitle: 'Hide the stories bar at the top of your feed',
          value: cfg.blockStories,
          onChanged: (v) => set(cfg.copyWith(blockStories: v)),
        ),
        AsToggleTile(
          title: 'Suggested & sponsored',
          subtitle: 'Hide suggested posts and ads in your feed',
          value: cfg.blockSuggested,
          onChanged: (v) => set(cfg.copyWith(blockSuggested: v)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AsSpacing.lg, AsSpacing.sm, AsSpacing.lg, AsSpacing.sm),
          child: Text(
            'Changes apply right away. Your feed, DMs, profile and posting always stay on.',
            style: AsTextStyles.caption.copyWith(color: c.textSecondary),
          ),
        ),
        if (kDebugMode)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => const WidgetGalleryScreen())),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AsSpacing.lg, vertical: AsSpacing.sm),
              child: Text(
                'Debug: long-press here for the widget gallery.',
                style: AsTextStyles.caption.copyWith(color: c.textSecondary),
              ),
            ),
          ),
      ],
    );
  }
}
