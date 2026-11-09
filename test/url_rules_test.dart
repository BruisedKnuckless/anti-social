import 'package:anti_social/models/blocker_config.dart';
import 'package:anti_social/utils/url_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const all = BlockerConfig(
      blockReels: true,
      blockStories: true,
      blockExplore: true,
      blockSuggested: true);
  const none = BlockerConfig(
      blockReels: false,
      blockStories: false,
      blockExplore: false,
      blockSuggested: false);
  Uri u(String s) => Uri.parse(s);

  group('blockedFeature', () {
    test('reels paths', () {
      for (final p in [
        '/reels/',
        '/reels',
        '/reel/C9xYz123/',
        '/someone/reels/',
        '/someone/reel/C9xYz123/',
      ]) {
        expect(blockedFeature(u('https://www.instagram.com$p'), all),
            BlockedFeature.reels,
            reason: p);
      }
    });

    test('explore paths, but search stays allowed', () {
      expect(blockedFeature(u('https://www.instagram.com/explore/'), all),
          BlockedFeature.explore);
      expect(
          blockedFeature(u('https://www.instagram.com/explore/tags/cats/'), all),
          BlockedFeature.explore);
      expect(
          blockedFeature(u('https://www.instagram.com/explore/search/'), all),
          isNull);
    });

    test('stories paths', () {
      expect(
          blockedFeature(
              u('https://www.instagram.com/stories/someone/123/'), all),
          BlockedFeature.stories);
    });

    test('normal pages are allowed', () {
      for (final p in [
        '/',
        '/p/C9xYz123/',
        '/direct/inbox/',
        '/direct/t/123/',
        '/someone/',
        '/accounts/edit/',
        '/reelsfan/', // a username that starts with "reels"
        '/someone/tagged/',
      ]) {
        expect(blockedFeature(u('https://www.instagram.com$p'), all), isNull,
            reason: p);
      }
    });

    test('nothing is blocked when toggles are off', () {
      expect(isBlockedPath(u('https://www.instagram.com/reels/'), none),
          isFalse);
      expect(isBlockedPath(u('https://www.instagram.com/explore/'), none),
          isFalse);
      expect(
          isBlockedPath(u('https://www.instagram.com/stories/a/1/'), none),
          isFalse);
    });

    test('only Instagram hosts are checked', () {
      expect(isBlockedPath(u('https://example.com/reels/'), all), isFalse);
    });
  });

  group('classifyUrl', () {
    test('Instagram pages load in the app', () {
      expect(classifyUrl(u('https://www.instagram.com/'), all), UrlAction.allow);
      expect(classifyUrl(u('https://instagram.com/p/abc/'), all),
          UrlAction.allow);
      expect(classifyUrl(u('https://scontent.cdninstagram.com/x.jpg'), all),
          UrlAction.allow);
    });

    test('blocked Instagram pages are blocked', () {
      expect(classifyUrl(u('https://www.instagram.com/reels/'), all),
          UrlAction.block);
      expect(classifyUrl(u('https://www.instagram.com/explore/'), all),
          UrlAction.block);
    });

    test('Facebook login stays in the app', () {
      expect(classifyUrl(u('https://m.facebook.com/login.php'), all),
          UrlAction.allow);
      expect(classifyUrl(u('https://www.facebook.com/dialog/oauth'), all),
          UrlAction.allow);
    });

    test('app-launch schemes are cancelled', () {
      for (final s in [
        'instagram://user?username=x',
        'intent://instagram.com/#Intent;package=com.instagram.android;end',
        'fb://profile',
        'market://details?id=com.instagram.android',
        'itms-apps://apps.apple.com/app/id389801252',
      ]) {
        expect(classifyUrl(u(s), all), UrlAction.cancel, reason: s);
      }
    });

    test('other sites open externally', () {
      expect(classifyUrl(u('https://example.com/'), all), UrlAction.external);
      expect(classifyUrl(u('https://l.instagram.com/?u=https%3A%2F%2Fexample.com'), all),
          UrlAction.external);
      expect(classifyUrl(u('mailto:a@b.c'), all), UrlAction.external);
      // Look-alike hosts are not Instagram.
      expect(classifyUrl(u('https://notinstagram.com/'), all),
          UrlAction.external);
    });

    test('page-internal schemes are allowed', () {
      expect(classifyUrl(u('about:blank'), all), UrlAction.allow);
      expect(classifyUrl(u('blob:https://www.instagram.com/x'), all),
          UrlAction.allow);
    });
  });

  test('externalTarget unwraps l.instagram.com', () {
    expect(
        externalTarget(u(
            'https://l.instagram.com/?u=https%3A%2F%2Fexample.com%2Fa&e=xyz')),
        u('https://example.com/a'));
    expect(externalTarget(u('https://example.com/')), u('https://example.com/'));
  });

  test('BlockerConfig json round-trip', () {
    const cfg = BlockerConfig(blockReels: false, blockSuggested: true);
    expect(BlockerConfig.fromJson(cfg.toJson()), cfg);
    expect(BlockerConfig.fromJson({}), const BlockerConfig());
  });
}
