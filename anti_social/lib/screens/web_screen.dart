import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../models/blocker_config.dart';
import '../services/script_builder.dart';
import '../services/settings_service.dart';
import '../ui/theme/tokens.dart';
import '../ui/widgets/as_error_view.dart';
import '../ui/widgets/as_progress_bar.dart';
import '../ui/widgets/as_snackbar.dart';
import '../utils/url_rules.dart';
import 'settings_sheet.dart';

/// Network failures that get the offline screen. Everything else (e.g. the
/// CANCELLED error WebKit reports when the URL guard cancels a load) is ignored.
final Set<WebResourceErrorType> _networkErrors = {
  WebResourceErrorType.NOT_CONNECTED_TO_INTERNET,
  WebResourceErrorType.HOST_LOOKUP,
  WebResourceErrorType.CANNOT_CONNECT_TO_HOST,
  WebResourceErrorType.TIMEOUT,
  WebResourceErrorType.NETWORK_CONNECTION_LOST,
  WebResourceErrorType.SERVER_UNREACHABLE,
  WebResourceErrorType.SECURE_CONNECTION_FAILED,
  WebResourceErrorType.FAILED_SSL_HANDSHAKE,
  WebResourceErrorType.CANNOT_LOAD_FROM_NETWORK,
  WebResourceErrorType.DATA_NOT_ALLOWED,
  WebResourceErrorType.INTERNATIONAL_ROAMING_OFF,
};

class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  late final SettingsService _settings;
  late BlockerConfig _config;

  InAppWebViewController? _controller;
  List<UserScript>? _initialScripts;

  double _progress = 0;
  String? _error;
  DateTime _lastBlockSnack = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _settings = context.read<SettingsService>();
    _config = _settings.config;
    _settings.addListener(_onConfigChanged);
    buildUserScripts(_config).then((s) {
      if (mounted) setState(() => _initialScripts = s);
    });
  }

  @override
  void dispose() {
    _settings.removeListener(_onConfigChanged);
    super.dispose();
  }

  InAppWebViewSettings _webSettings(BlockerConfig cfg) => InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        allowsInlineMediaPlayback: true, // videos play inside, not fullscreen
        mediaPlaybackRequiresUserGesture: true, // no autoplay sound
        allowsBackForwardNavigationGestures: true, // iOS edge swipe
        sharedCookiesEnabled: true, // keep login
        isInspectable: kDebugMode, // Safari Web Inspector, debug builds only
        userAgent: kUserAgent, // same UA on both platforms
        transparentBackground: true, // our background shows while loading (no white flash)
        supportMultipleWindows: true, // route target=_blank through onCreateWindow
        javaScriptCanOpenWindowsAutomatically: true,
        algorithmicDarkeningAllowed: false, // Android: use Instagram's own dark theme
        contentBlockers: buildContentBlockers(cfg),
      );

  // ---- Settings -> page ---------------------------------------------------

  Future<void> _onConfigChanged() async {
    final cfg = _settings.config;
    _config = cfg;
    final c = _controller;
    if (c == null) return;
    // 1. Update the loaded page instantly (no reload).
    await c.evaluateJavascript(source: liveUpdateSource(cfg));
    // 2. Make the next page load use the new config too.
    await c.removeUserScriptsByGroupName(groupName: 'antisocial');
    await c.addUserScripts(userScripts: await buildUserScripts(cfg));
    await c.setSettings(settings: _webSettings(cfg));
  }

  // ---- Navigation helpers ---------------------------------------------------

  Future<void> _load(Uri uri) async {
    await _controller?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(uri)));
  }

  Future<void> _goHome() => _load(homeUri);

  Future<void> _reload() async {
    if (_error != null) {
      setState(() => _error = null);
      final url = await _controller?.getUrl();
      await _load(url ?? homeUri);
      return;
    }
    await _controller?.reload();
  }

  /// One back handler for both platforms (iOS edge swipe is native to
  /// WKWebView; Android's system back comes through PopScope).
  Future<void> _handleBack() async {
    final c = _controller;
    if (c != null && await c.canGoBack()) await c.goBack();
  }

  void _showBlocked(String reason) {
    final now = DateTime.now();
    if (now.difference(_lastBlockSnack) < const Duration(milliseconds: 1200)) return;
    _lastBlockSnack = now;
    HapticFeedback.lightImpact();
    if (mounted) {
      AsSnackbar.show(context, reason,
          icon: LucideIcons.shieldCheck,
          bottomOffset: kTabBarClearance);
    }
  }

  Future<void> _openExternal(Uri uri) async {
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open $uri: $e');
    }
  }

  /// Applies a decision for a navigation we have already cancelled or that
  /// already happened (SPA). Returns true if it acted.
  Future<bool> _act(NavDecision d) async {
    switch (d) {
      case NavAllow():
        return false;
      case NavCancel():
        return true;
      case NavExternal(:final uri):
        await _openExternal(uri);
        return true;
      case NavRedirect(:final target, :final reason):
        _showBlocked(reason);
        await _load(target);
        return true;
      case NavBlock(:final reason):
        _showBlocked(reason);
        return true;
    }
  }

  // ---- InAppWebView callbacks -----------------------------------------------

  Future<NavigationActionPolicy> _shouldOverrideUrlLoading(
      InAppWebViewController c, NavigationAction action) async {
    final url = action.request.url;
    if (url == null) return NavigationActionPolicy.ALLOW;
    final d = decideNavigation(url, _config, isMainFrame: action.isForMainFrame);
    if (d is NavAllow) return NavigationActionPolicy.ALLOW;
    await _act(d);
    return NavigationActionPolicy.CANCEL;
  }

  /// SPA route changes (history.pushState) don't hit shouldOverrideUrlLoading.
  /// blocker.js handles them first; this is the backstop if the JS failed.
  void _onUpdateVisitedHistory(
      InAppWebViewController c, WebUri? url, bool? isReload) {
    if (url == null) return;
    if (decideNavigation(url, _config) is NavAllow) return;
    Future.delayed(const Duration(milliseconds: 400), () async {
      final now = await c.getUrl();
      if (now == null) return;
      final d = decideNavigation(now, _config);
      if (d is NavAllow) return;
      if (d is NavBlock) {
        _showBlocked(d.reason);
        if (await c.canGoBack()) {
          await c.goBack();
        } else {
          await _goHome();
        }
        return;
      }
      await _act(d);
    });
  }

  /// target=_blank links and window.open: load in this same view (or send
  /// outside the app), never a second web view.
  Future<bool> _onCreateWindow(
      InAppWebViewController c, CreateWindowAction action) async {
    final url = action.request.url;
    if (url == null) return false;
    final d = decideNavigation(url, _config);
    if (d is NavAllow) {
      await _load(url);
    } else {
      await _act(d);
    }
    return false;
  }

  void _onJsEvent(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map) return;
    final event = Map<String, dynamic>.from(args.first as Map);
    final type = event['type'];
    final data = event['data'];
    debugPrint('Blocker event: $type $data');
    if (type == 'blocked' && data is Map) {
      _showBlocked((data['reason'] as String?) ?? 'Blocked');
    } else if (type == 'open_settings') {
      HapticFeedback.lightImpact();
      _openSettings();
    }
  }

  void _onReceivedError(InAppWebViewController c, WebResourceRequest request,
      WebResourceError error) {
    if (request.isForMainFrame == false) return;
    if (!_networkErrors.contains(error.type)) return;
    setState(() => _error = error.description);
  }

  // ---- UI ---------------------------------------------------------------------

  void _openSettings() => SettingsSheet.show(context);

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    final scripts = _initialScripts;
    final loading = scripts == null || _progress < 1.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: c.background,
        // Full screen like the native app: Instagram's own header and tab bar
        // are the app's chrome (restyled by skin.css). Top stays clear of the
        // status bar; the bottom runs under the home indicator so posts scroll
        // behind the floating tab bar.
        body: SafeArea(
          bottom: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (scripts != null)
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(kHomeUrl)),
                  initialSettings: _webSettings(_config),
                  initialUserScripts: UnmodifiableListView(scripts),
                  onWebViewCreated: (controller) {
                    _controller = controller;
                    controller.addJavaScriptHandler(
                      handlerName: 'asEvent',
                      callback: _onJsEvent,
                    );
                  },
                  shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
                  onUpdateVisitedHistory: _onUpdateVisitedHistory,
                  onCreateWindow: _onCreateWindow,
                  onProgressChanged: (_, p) {
                    final next = p / 100;
                    // Only rebuild when the bar needs to appear/move/disappear.
                    if (next != _progress) setState(() => _progress = next);
                  },
                  onReceivedError: _onReceivedError,
                ),
              if (_error != null)
                Positioned.fill(
                  child: AsErrorView(
                    title: "You're offline",
                    message: 'Check your connection and try again.',
                    onRetry: _reload,
                  ),
                ),
              // Only in the tree while loading, so nothing is drawn over the
              // web view while you scroll.
              if (loading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AsProgressBar(progress: scripts == null ? 0 : _progress),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
