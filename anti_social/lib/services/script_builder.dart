import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/blocker_config.dart';

const String kCssAsset = 'assets/inject/blocker.css';
const String kJsAsset = 'assets/inject/blocker.js';
const String kSkinAsset = 'assets/inject/skin.css';

/// `window.__AS_CONFIG = {...};`
String configScriptSource(BlockerConfig cfg) =>
    'window.__AS_CONFIG = ${jsonEncode(cfg.toJson())};';

/// Stores the CSS on window (so blocker.js can re-add it if React removes it)
/// and adds the <style> right away, before Instagram paints anything.
String cssInjectorSource(String css) => '''
(function () {
  window.__AS_CSS = ${jsonEncode(css)};
  if (document.getElementById('as-style')) return;
  var s = document.createElement('style');
  s.id = 'as-style';
  s.textContent = window.__AS_CSS;
  (document.head || document.documentElement).appendChild(s);
})();
''';

/// JS that pushes a new config into an already-loaded page.
String liveUpdateSource(BlockerConfig cfg) =>
    'window.__AS_CONFIG = ${jsonEncode(cfg.toJson())};'
    'if (window.__AS_UPDATE) { window.__AS_UPDATE(${jsonEncode(cfg.toJson())}); }';

String? _css;
String? _js;

/// Builds the document-start user scripts: config -> CSS -> engine.
Future<List<UserScript>> buildUserScripts(BlockerConfig cfg,
    {AssetBundle? bundle}) async {
  final b = bundle ?? rootBundle;
  _css ??= '${await b.loadString(kCssAsset)}\n${await b.loadString(kSkinAsset)}';
  _js ??= await b.loadString(kJsAsset);

  UserScript script(String source) => UserScript(
        groupName: 'antisocial',
        source: source,
        injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
        forMainFrameOnly: true,
      );

  return [
    script(configScriptSource(cfg)),
    script(cssInjectorSource(_css!)),
    script(_js!),
  ];
}

/// Native WKWebView content rules (iOS): the fastest, most stable hides.
/// Only simple href selectors go here; everything else lives in blocker.css.
List<ContentBlocker> buildContentBlockers(BlockerConfig cfg) {
  if (!cfg.blockReels) return const [];
  return [
    ContentBlocker(
      trigger: ContentBlockerTrigger(urlFilter: r'.*instagram\.com.*'),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: 'a[href="/reels/"]',
      ),
    ),
  ];
}
