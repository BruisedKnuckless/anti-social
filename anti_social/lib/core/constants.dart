/// Values shared by iOS and Android. Keep them in ONE place so both
/// platforms get the same Instagram layout (same user agent) and URLs.
library;

const String kHomeUrl = 'https://www.instagram.com/';
const String kSearchUrl = 'https://www.instagram.com/explore/search/';

/// One modern mobile Safari user agent, used on BOTH platforms.
/// Instagram picks its layout from the UA, so the same UA means the same page.
const String kUserAgent =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) '
    'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1';

/// Max text scale for our Flutter UI, so huge system fonts don't break layouts.
const double kMaxTextScale = 1.3;

/// Space taken by the floating tab bar (skin.css: 62px pill + gap), so
/// snackbars appear above it.
const double kTabBarClearance = 72;
