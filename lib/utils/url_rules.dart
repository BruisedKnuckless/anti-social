import '../models/blocker_config.dart';

/// The features a URL path can belong to.
enum BlockedFeature { reels, explore, stories }

/// What the WebView should do with a main-frame navigation.
enum UrlAction {
  /// Load it inside the app.
  allow,

  /// A blocked Instagram page: cancel and show the "blocked" toast.
  block,

  /// Not Instagram: cancel and open in the system browser.
  external,

  /// An app-launch link (instagram://, intent://…): cancel silently.
  cancel,
}

/// Path patterns, shared with blocker.js (passed in through the injected
/// config) so Dart and JS always agree. JS-compatible RegExp syntax only.
abstract final class PathPatterns {
  /// /reels/, /reel/ID/, /user/reels/, /user/reel/ID/
  static const String reels = r'^/([^/]+/)?reels?(/|$)';

  /// /explore/ and its sub-pages, except search.
  static const String explore = r'^/explore(?!/search)(/|$)';

  /// /stories/user/ID/
  static const String stories = r'^/stories(/|$)';

  static final _reels = RegExp(reels);
  static final _explore = RegExp(explore);
  static final _stories = RegExp(stories);

  static Map<String, String> toJson() =>
      {'reels': reels, 'explore': explore, 'stories': stories};
}

/// Hosts that stay inside the app (login, media, Facebook login).
const _inAppHostSuffixes = <String>[
  'instagram.com',
  'cdninstagram.com',
  'facebook.com',
  'fbcdn.net',
  'fbsbx.com',
];

/// Schemes that try to open another app (the real Instagram app, the Play
/// Store…). Android web pages use intent:// for this.
const _appSchemes = <String>{
  'instagram',
  'intent',
  'fb',
  'market',
  'itms-apps',
  'itms-appss',
};

/// Schemes that are part of loading a page, never a "navigation away".
const _internalSchemes = <String>{'about', 'data', 'blob', 'javascript'};

bool _hostMatches(String host, String suffix) =>
    host == suffix || host.endsWith('.$suffix');

bool isInstagramHost(String host) =>
    _hostMatches(host.toLowerCase(), 'instagram.com');

/// Which blocked feature [uri] belongs to, if that feature is switched on.
BlockedFeature? blockedFeature(Uri uri, BlockerConfig cfg) {
  if (!isInstagramHost(uri.host)) return null;
  final path = uri.path.isEmpty ? '/' : uri.path;
  if (cfg.blockReels && PathPatterns._reels.hasMatch(path)) {
    return BlockedFeature.reels;
  }
  if (cfg.blockExplore && PathPatterns._explore.hasMatch(path)) {
    return BlockedFeature.explore;
  }
  if (cfg.blockStories && PathPatterns._stories.hasMatch(path)) {
    return BlockedFeature.stories;
  }
  return null;
}

bool isBlockedPath(Uri uri, BlockerConfig cfg) =>
    blockedFeature(uri, cfg) != null;

/// Decide what to do with a main-frame navigation to [uri].
UrlAction classifyUrl(Uri uri, BlockerConfig cfg) {
  final scheme = uri.scheme.toLowerCase();
  if (_internalSchemes.contains(scheme)) return UrlAction.allow;
  if (_appSchemes.contains(scheme)) return UrlAction.cancel;
  if (scheme != 'http' && scheme != 'https') return UrlAction.external;

  final host = uri.host.toLowerCase();
  if (isBlockedPath(uri, cfg)) return UrlAction.block;
  // l.instagram.com is Instagram's outbound link redirector.
  if (host == 'l.instagram.com') return UrlAction.external;
  if (_inAppHostSuffixes.any((s) => _hostMatches(host, s))) {
    return UrlAction.allow;
  }
  return UrlAction.external;
}

/// The real destination of an outbound link: unwraps l.instagram.com/?u=…
Uri externalTarget(Uri uri) {
  if (uri.host.toLowerCase() == 'l.instagram.com') {
    final u = uri.queryParameters['u'];
    final target = u == null ? null : Uri.tryParse(u);
    if (target != null &&
        (target.scheme == 'http' || target.scheme == 'https')) {
      return target;
    }
  }
  return uri;
}

/// Where to send the user instead of a blocked page. Explore goes to the
/// search-only page so search keeps working.
const String kSearchPath = '/explore/search/';

String redirectPathFor(BlockedFeature f) =>
    f == BlockedFeature.explore ? kSearchPath : '/';

/// Toast text for a blocked feature.
String blockedMessage(BlockedFeature f) => switch (f) {
      BlockedFeature.reels => 'Reels are blocked 🙂',
      BlockedFeature.explore => 'Explore is blocked. Search still works 🙂',
      BlockedFeature.stories => 'Stories are blocked 🙂',
    };
