import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../models/blocker_config.dart';
import '../platform/webview_settings.dart';
import '../services/script_builder.dart';
import '../services/settings_service.dart';
import '../ui/as_icons.dart';
import '../ui/theme/tokens.dart';
import '../ui/widgets/as_error_view.dart';
import '../ui/widgets/as_fab.dart';
import '../ui/widgets/as_progress_bar.dart';
import '../ui/widgets/as_snackbar.dart';
import '../utils/url_rules.dart';
import 'settings_sheet.dart';

/// Instagram Web in a full-screen WebView, with the blocker injected and the
/// URL guard on every navigation.
class WebScreen extends StatefulWidget {
  const WebScreen({super.key});

  @override
  State<WebScreen> createState() => _WebScreenState();
}

class _WebScreenState extends State<WebScreen> {
  InAppWebViewController? _controller;
  final _settings = buildWebViewSettings();
  late final SettingsService _settingsService;
  late final ScriptBuilder _scripts;
  late BlockerConfig _cfg;

  double _progress = 0;
  bool _hasError = false;
  DateTime _lastToast = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _settingsService = context.read<SettingsService>();
    _scripts = context.read<ScriptBuilder>();
    _cfg = _settingsService.config;
    _settingsService.addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _settingsService.removeListener(_onConfigChanged);
    super.dispose();
  }

  // ---------------------------------------------------------------- config

  Future<void> _onConfigChanged() async {
    _cfg = _settingsService.config;
    final c = _controller;
    if (c == null) return;
    // Live: flip classes in the current page. Next load: new user scripts.
    await c.evaluateJavascript(source: _scripts.liveUpdateSource(_cfg));
    await c.removeUserScriptsByGroupName(groupName: ScriptBuilder.groupName);
    await c.addUserScripts(userScripts: _scripts.userScripts(_cfg));
  }

  // ----------------------------------------------------------- navigation

  /// Shared back handler. Android's system back calls it through PopScope;
  /// iOS uses the WebView's own swipe-back gesture with the same result.
  Future<void> _handleBack() async {
    final c = _controller;
    if (c != null && await c.canGoBack()) {
      await c.goBack();
    } else {
      await SystemNavigator.pop();
    }
  }

  Future<void> _retry() async {
    setState(() => _hasError = false);
    final current = await _controller?.getUrl();
    final url = (current == null || !isInstagramHost(current.host))
        ? WebUri(kHomeUrl)
        : current;
    await _controller?.loadUrl(urlRequest: URLRequest(url: url));
  }

  void _toastBlocked(BlockedFeature f) {
    final now = DateTime.now();
    if (now.difference(_lastToast) < const Duration(seconds: 2)) return;
    _lastToast = now;
    if (mounted) AsSnackbar.show(context, blockedMessage(f), icon: AsIcons.blocked);
  }

  Future<void> _openExternal(Uri uri) async {
    final target = externalTarget(uri);
    try {
      await launchUrl(target, mode: LaunchMode.externalApplication);
    } catch (_) {
      // No app can open it; nothing else to do.
    }
  }

  Future<void> _redirectAway(BlockedFeature f) async {
    final path = redirectPathFor(f);
    await _controller?.loadUrl(
        urlRequest: URLRequest(url: WebUri('https://www.instagram.com$path')));
  }

  /// Backup guard for page loads that blocker.js didn't stop (typed URLs,
  /// redirects, links opened by scripts).
  Future<void> _guardLoadStart(InAppWebViewController c, WebUri? url) async {
    if (url == null) return;
    switch (classifyUrl(url, _cfg)) {
      case UrlAction.allow:
        return;
      case UrlAction.cancel:
        await c.stopLoading();
      case UrlAction.external:
        await c.stopLoading();
        await _openExternal(url);
      case UrlAction.block:
        await c.stopLoading();
        final f = blockedFeature(url, _cfg)!;
        _toastBlocked(f);
        await _redirectAway(f);
    }
  }

  /// SPA route changes (history.pushState) don't trigger a page load.
  /// blocker.js redirects these itself; this is the safety net.
  void _guardHistory(InAppWebViewController c, WebUri? url) {
    if (url == null || !isBlockedPath(url, _cfg)) return;
    final f = blockedFeature(url, _cfg)!;
    _toastBlocked(f);
    Future.delayed(const Duration(milliseconds: 400), () async {
      final now = await c.getUrl();
      if (now != null && isBlockedPath(now, _cfg)) await _redirectAway(f);
    });
  }

  // --------------------------------------------------------------- bridge

  void _onJsEvent(List<dynamic> args) {
    if (args.isEmpty || args.first is! Map) return;
    final msg = (args.first as Map).cast<String, dynamic>();
    final data = msg['data'];
    switch (msg['type']) {
      case 'blocked':
        final name = data is Map ? data['feature'] : null;
        final f = BlockedFeature.values.where((v) => v.name == name);
        if (f.isNotEmpty) _toastBlocked(f.first);
      case 'open_external':
        final uri = data is String ? Uri.tryParse(data) : null;
        if (uri != null) _openExternal(uri);
      case 'selector_missing':
        debugPrint('[AntiSocial] selector missing: $data');
      default:
        if (kDebugMode) debugPrint('[AntiSocial] event: $msg');
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final c = AsColors.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: c.webBackground,
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri(kHomeUrl)),
                initialSettings: _settings,
                initialUserScripts:
                    UnmodifiableListView(_scripts.userScripts(_cfg)),
                onWebViewCreated: (controller) {
                  _controller = controller;
                  controller.addJavaScriptHandler(
                    handlerName: 'asEvent',
                    callback: (args) {
                      _onJsEvent(args);
                      return null;
                    },
                  );
                },
                onLoadStart: _guardLoadStart,
                onUpdateVisitedHistory: (controller, url, _) =>
                    _guardHistory(controller, url),
                onLoadStop: (controller, url) async {
                  // Fallback if document-start scripts didn't run.
                  await controller.evaluateJavascript(
                      source: _scripts.fallbackSource(_cfg));
                },
                onProgressChanged: (_, p) =>
                    setState(() => _progress = p / 100),
                onReceivedError: (_, request, error) {
                  if (request.isForMainFrame != true) return;
                  if (error.type == WebResourceErrorType.CANCELLED) return;
                  // Errors for URLs we redirected or opened elsewhere.
                  if (classifyUrl(request.url, _cfg) != UrlAction.allow) {
                    return;
                  }
                  setState(() => _hasError = true);
                },
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AsProgressBar(progress: _progress),
              ),
              if (_hasError)
                Positioned.fill(child: AsErrorView(onRetry: _retry)),
              if (!_hasError)
                Positioned(
                  right: AsSpacing.md,
                  bottom: 72, // above Instagram's bottom tab bar
                  child: AsFab(
                    icon: AsIcons.settings,
                    semanticLabel: 'Blocking settings',
                    onPressed: () => showSettingsSheet(context),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
