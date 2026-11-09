/// Values shared by iOS and Android. Change them here only.
library;

const String kHomeUrl = 'https://www.instagram.com/';

/// One mobile user agent for both platforms, so Instagram serves the same
/// layout everywhere. Chrome's reduced UA format (no `; wv` WebView token).
const String kUserAgent =
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/142.0.0.0 Mobile Safari/537.36';

/// Largest system text scale the Flutter UI follows.
const double kMaxTextScale = 1.3;
