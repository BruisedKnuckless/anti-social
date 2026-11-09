import 'dart:convert';

import 'package:anti_social/models/blocker_config.dart';
import 'package:anti_social/services/script_builder.dart';
import 'package:anti_social/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults block everything except friends\' video posts', () {
    const c = BlockerConfig();
    final json = c.toJson()..remove('blockFeedVideos');
    expect(json.values, everyElement(isTrue));
    expect(c.blockFeedVideos, isFalse);
  });

  test('configs saved before blockFeedVideos existed still load', () {
    final c = BlockerConfig.fromJson({'blockReels': true, 'blockStories': false});
    expect(c.blockFeedVideos, isFalse);
    expect(c.blockStories, isFalse);
  });

  test('JSON round trip', () {
    const c = BlockerConfig(blockDmReels: false, blockStories: false);
    expect(BlockerConfig.fromJson(c.toJson()), c);
  });

  test('missing or wrong-typed keys fall back to defaults', () {
    final c = BlockerConfig.fromJson({'blockReels': false, 'blockStories': 'nope'});
    expect(c.blockReels, isFalse);
    expect(c.blockStories, isTrue);
  });

  test('config script is valid JSON assignment', () {
    const c = BlockerConfig(blockExplore: false);
    final src = configScriptSource(c);
    expect(src, startsWith('window.__AS_CONFIG = '));
    final json = src.substring('window.__AS_CONFIG = '.length, src.length - 1);
    expect(BlockerConfig.fromJson(jsonDecode(json) as Map<String, dynamic>), c);
  });

  test('content blockers follow the reels toggle', () {
    expect(buildContentBlockers(const BlockerConfig()), isNotEmpty);
    expect(buildContentBlockers(const BlockerConfig(blockReels: false)), isEmpty);
  });

  test('SettingsService persists across loads', () async {
    SharedPreferences.setMockInitialValues({});
    final s1 = await SettingsService.load();
    expect(s1.config, const BlockerConfig());
    var notified = 0;
    s1.addListener(() => notified++);
    await s1.update(s1.config.copyWith(blockStories: false));
    expect(notified, 1);

    final s2 = await SettingsService.load();
    expect(s2.config.blockStories, isFalse);
    expect(s2.config.blockReels, isTrue);
  });
}
