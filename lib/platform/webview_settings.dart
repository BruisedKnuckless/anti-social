import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../core/constants.dart';

/// One settings object for both platforms. The plugin ignores flags that
/// don't apply to the current platform, so no Platform checks are needed.
InAppWebViewSettings buildWebViewSettings() => InAppWebViewSettings(
      // Shared
      javaScriptEnabled: true,
      mediaPlaybackRequiresUserGesture: true, // no autoplay with sound
      isInspectable: kDebugMode, // chrome://inspect / Safari Web Inspector
      // OFF on purpose: on Android the plugin cancels every main-frame
      // navigation (even server redirects) and re-issues it with loadUrl,
      // which breaks Instagram's login/2FA flow. The URL guard runs from
      // blocker.js link interception + onLoadStart + onUpdateVisitedHistory
      // instead (same on both platforms).
      useShouldOverrideUrlLoading: false,
      userAgent: kUserAgent, // same Instagram layout on both
      transparentBackground: true, // our background shows, no white flash
      disableDefaultErrorPage: true, // we show AsErrorView instead

      // Android
      domStorageEnabled: true,
      databaseEnabled: true,
      thirdPartyCookiesEnabled: true, // "Log in with Facebook"
      supportMultipleWindows: false, // popups load in the same view
      algorithmicDarkeningAllowed: false, // use Instagram's own dark theme
      forceDark: ForceDark.OFF,

      // iOS
      allowsInlineMediaPlayback: true,
      allowsBackForwardNavigationGestures: true,
      sharedCookiesEnabled: true,
    );
