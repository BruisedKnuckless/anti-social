import 'package:anti_social/models/blocker_config.dart';
import 'package:anti_social/utils/url_rules.dart';
import 'package:flutter_test/flutter_test.dart';

NavDecision d(String url, [BlockerConfig cfg = const BlockerConfig()]) =>
    decideNavigation(Uri.parse(url), cfg);

const allOff = BlockerConfig(
  blockReels: false,
  blockFeedVideos: false,
  blockDmReels: false,
  blockExplore: false,
  blockStories: false,
  blockSuggested: false,
);

void main() {
  group('reels feed', () {
    test('/reels/ redirects home', () {
      final r = d('https://www.instagram.com/reels/');
      expect(r, isA<NavRedirect>());
      expect((r as NavRedirect).target.path, '/');
    });
    test('/reels/<id>/ and no trailing slash also redirect', () {
      expect(d('https://www.instagram.com/reels/abc123/'), isA<NavRedirect>());
      expect(d('https://www.instagram.com/reels'), isA<NavRedirect>());
    });
    test('profile reels tab redirects to the profile', () {
      final r = d('https://www.instagram.com/some.user/reels/') as NavRedirect;
      expect(r.target.path, '/some.user/');
    });
    test('allowed when the toggle is off', () {
      expect(d('https://www.instagram.com/reels/', allOff), isA<NavAllow>());
      expect(d('https://www.instagram.com/some.user/reels/', allOff), isA<NavAllow>());
    });
  });

  group('single reels (DMs)', () {
    test('blocked when blockDmReels is on', () {
      expect(d('https://www.instagram.com/reel/Cxyz123/'), isA<NavBlock>());
    });
    test('allowed when blockDmReels is off, even with the reels feed blocked', () {
      const cfg = BlockerConfig(blockDmReels: false);
      expect(d('https://www.instagram.com/reel/Cxyz123/', cfg), isA<NavAllow>());
      expect(d('https://www.instagram.com/reels/', cfg), isA<NavRedirect>());
    });
  });

  group('explore', () {
    test('explore grid goes to search', () {
      final r = d('https://www.instagram.com/explore/') as NavRedirect;
      expect(r.target.path, '/explore/search/');
      expect(d('https://www.instagram.com/explore/tags/cats/'), isA<NavRedirect>());
    });
    test('search itself is allowed', () {
      expect(d('https://www.instagram.com/explore/search/'), isA<NavAllow>());
      expect(d('https://www.instagram.com/explore/search/keyword/?q=x'), isA<NavAllow>());
    });
    test('allowed when off', () {
      expect(d('https://www.instagram.com/explore/', allOff), isA<NavAllow>());
    });
  });

  group('stories', () {
    test('stories pages redirect home when on', () {
      expect(d('https://www.instagram.com/stories/friend/123/'), isA<NavRedirect>());
    });
    test('allowed when off', () {
      expect(d('https://www.instagram.com/stories/friend/123/', allOff), isA<NavAllow>());
    });
  });

  group('always allowed', () {
    for (final path in ['/', '/direct/inbox/', '/direct/t/123/', '/some.user/', '/p/abc/', '/accounts/login/']) {
      test(path, () => expect(d('https://www.instagram.com$path'), isA<NavAllow>()));
    }
    test('Instagram CDN and Facebook login', () {
      expect(d('https://scontent.cdninstagram.com/v/x.jpg'), isA<NavAllow>());
      expect(d('https://m.facebook.com/login/'), isA<NavAllow>());
    });
    test('about:blank and blob', () {
      expect(d('about:blank'), isA<NavAllow>());
      expect(d('blob:https://www.instagram.com/abc'), isA<NavAllow>());
    });
  });

  group('leaving the app', () {
    test('instagram:// and app store links are cancelled', () {
      expect(d('instagram://user?username=x'), isA<NavCancel>());
      expect(d('itms-apps://apps.apple.com/app/id389801252'), isA<NavCancel>());
    });
    test('external hosts open outside', () {
      final r = d('https://example.com/page');
      expect(r, isA<NavExternal>());
      expect((r as NavExternal).uri.host, 'example.com');
    });
    test('look-alike host is external', () {
      expect(d('https://notinstagram.com/'), isA<NavExternal>());
    });
    test('mailto/tel open outside', () {
      expect(d('mailto:a@b.c'), isA<NavExternal>());
      expect(d('tel:123'), isA<NavExternal>());
    });
    test('l.instagram.com link shim unwraps to the real URL', () {
      final r = d('https://l.instagram.com/?u=https%3A%2F%2Fexample.com%2Fx&e=abc');
      expect(r, isA<NavExternal>());
      expect((r as NavExternal).uri.toString(), 'https://example.com/x');
    });
    test('iframes are not policed by host', () {
      expect(
        decideNavigation(Uri.parse('https://example.com/embed'), const BlockerConfig(),
            isMainFrame: false),
        isA<NavAllow>(),
      );
    });
  });

  test('normalizePath', () {
    expect(normalizePath(''), '/');
    expect(normalizePath('/'), '/');
    expect(normalizePath('/reels/'), '/reels');
    expect(normalizePath('/a//'), '/a');
  });
}
