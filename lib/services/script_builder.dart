import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../models/blocker_config.dart';
import '../utils/url_rules.dart';

/// Builds the user scripts injected at document start. The same assets are
/// used on iOS and Android.
class ScriptBuilder {
  ScriptBuilder._(this._css, this._js, this._selectors);

  static const groupName = 'anti_social';

  final String _css;
  final String _js;
  final Map<String, dynamic> _selectors;

  static Future<ScriptBuilder> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final css = await b.loadString('assets/inject/blocker.css');
    final js = await b.loadString('assets/inject/blocker.js');
    final selectors = (jsonDecode(
            await b.loadString('assets/inject/selectors.json')) as Map)
        .cast<String, dynamic>();
    return ScriptBuilder._(css, js, selectors);
  }

  /// CSS for the nav links, generated from selectors.json so every selector
  /// lives in one file. These rules apply before any JS runs (no flicker).
  String get _navCss {
    final out = StringBuffer();
    void rule(String cls, Object? sels) {
      if (sels is! List || sels.isEmpty) return;
      out.writeln('html.$cls :is(${sels.join(', ')}) '
          '{ display: none !important; }');
    }

    rule('as-block-reels', _selectors['reelsNav']);
    // Explore's nav link is NOT hidden: it doubles as the Search tab, and
    // blocker.js sends it to the search-only page instead.
    return out.toString();
  }

  /// Everything blocker.js needs, as one JS object literal.
  String configJson(BlockerConfig cfg) => jsonEncode({
        ...cfg.toJson(),
        'paths': PathPatterns.toJson(),
      });

  /// JS that pushes a new config into an already-loaded page.
  String liveUpdateSource(BlockerConfig cfg) =>
      'window.__AS_UPDATE && window.__AS_UPDATE(${configJson(cfg)});';

  /// Fallback for when document-start scripts did not run (e.g. an old
  /// WebView): runs the full engine once if it is missing.
  String fallbackSource(BlockerConfig cfg) =>
      'if (!window.__AS_LOADED) { ${_bootSource(cfg)}\n$_js }'
      ' else if (window.__AS_ENSURE) { window.__AS_ENSURE(); }';

  String _bootSource(BlockerConfig cfg) => '''
window.__AS_CONFIG = ${configJson(cfg)};
window.__AS_SELECTORS = ${jsonEncode(_selectors)};
window.__AS_CSS = ${jsonEncode('$_css\n$_navCss')};
''';

  List<UserScript> userScripts(BlockerConfig cfg) => [
        UserScript(
          groupName: groupName,
          source: _bootSource(cfg),
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: true,
        ),
        UserScript(
          groupName: groupName,
          source: _js,
          injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
          forMainFrameOnly: true,
        ),
      ];
}
