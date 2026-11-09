import '../core/constants.dart';
import '../models/blocker_config.dart';

/// What to do with a navigation. Pure Dart so it is easy to unit test.
sealed class NavDecision {
  const NavDecision();
}

/// Let it load.
class NavAllow extends NavDecision {
  const NavAllow();
}

/// Silently drop it (e.g. `instagram://` "open in app" links).
class NavCancel extends NavDecision {
  const NavCancel();
}

/// Open outside the app (Safari / mail / phone).
class NavExternal extends NavDecision {
  const NavExternal(this.uri);
  final Uri uri;
}

/// Load [target] instead.
class NavRedirect extends NavDecision {
  const NavRedirect(this.target, this.reason);
  final Uri target;
  final String reason;
}

/// Refuse to open it, stay where we are.
class NavBlock extends NavDecision {
  const NavBlock(this.reason);
  final String reason;
}

final Uri homeUri = Uri.parse(kHomeUrl);
final Uri searchUri = Uri.parse(kSearchUrl);

/// Hosts that may load inside the app. Everything else opens in the browser.
const List<String> kAllowedHosts = [
  'instagram.com',
  'cdninstagram.com',
  'facebook.com', // "Log in with Facebook"
  'fbcdn.net',
];

/// Schemes the web view handles itself.
const Set<String> _webSchemes = {'http', 'https', 'about', 'blob', 'data'};

/// Schemes we hand to the OS.
const Set<String> _externalSchemes = {'mailto', 'tel', 'sms'};

bool isAllowedHost(String host) {
  final h = host.toLowerCase();
  return kAllowedHosts.any((d) => h == d || h.endsWith('.$d'));
}

bool isInstagramHost(String host) {
  final h = host.toLowerCase();
  return h == 'instagram.com' || h.endsWith('.instagram.com');
}

/// `/reels/` -> `/reels`, but `/` stays `/`.
String normalizePath(String path) {
  if (path.isEmpty) return '/';
  final stripped = path.replaceAll(RegExp(r'/+$'), '');
  return stripped.isEmpty ? '/' : stripped;
}

final RegExp _profileReelsTab = RegExp(r'^/([^/]+)/reels$');

/// Path-only rules for instagram.com, shared by full loads and SPA route changes.
NavDecision decideInstagramPath(String rawPath, BlockerConfig cfg) {
  final p = normalizePath(rawPath);

  if (cfg.blockReels) {
    if (p == '/reels' || p.startsWith('/reels/')) {
      return NavRedirect(homeUri, 'Reels are blocked');
    }
    final m = _profileReelsTab.firstMatch(p);
    if (m != null) {
      return NavRedirect(homeUri.replace(path: '/${m.group(1)}/'),
          'Reels are blocked');
    }
  }

  if (cfg.blockDmReels && (p == '/reel' || p.startsWith('/reel/'))) {
    return const NavBlock('Reels are blocked');
  }

  if (cfg.blockExplore &&
      (p == '/explore' ||
          (p.startsWith('/explore/') && !p.startsWith('/explore/search')))) {
    return NavRedirect(searchUri, 'Explore is blocked. Here\'s Search');
  }

  if (cfg.blockStories && (p == '/stories' || p.startsWith('/stories/'))) {
    return NavRedirect(homeUri, 'Stories are blocked');
  }

  return const NavAllow();
}

/// Full decision for any URL the web view wants to open.
///
/// [isMainFrame] is false for iframes; those are only checked for scheme so
/// Instagram's own embeds keep working.
NavDecision decideNavigation(Uri uri, BlockerConfig cfg,
    {bool isMainFrame = true}) {
  final scheme = uri.scheme.toLowerCase();

  if (_externalSchemes.contains(scheme)) return NavExternal(uri);
  // instagram://, itms-apps://, fb:// ... never jump to another app.
  if (!_webSchemes.contains(scheme)) return const NavCancel();
  if (scheme != 'http' && scheme != 'https') return const NavAllow();
  if (!isMainFrame) return const NavAllow();

  final host = uri.host.toLowerCase();

  // Instagram's link shim: l.instagram.com/?u=<real url>
  if (host == 'l.instagram.com') {
    final target = Uri.tryParse(uri.queryParameters['u'] ?? '');
    if (target != null && target.hasScheme) {
      return isAllowedHost(target.host)
          ? decideNavigation(target, cfg)
          : NavExternal(target);
    }
  }

  if (!isAllowedHost(host)) return NavExternal(uri);
  if (isInstagramHost(host)) return decideInstagramPath(uri.path, cfg);
  return const NavAllow();
}
