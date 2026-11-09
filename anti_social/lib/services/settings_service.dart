import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/blocker_config.dart';

/// Loads and saves [BlockerConfig] and notifies listeners (the WebScreen)
/// when a toggle changes.
class SettingsService extends ChangeNotifier {
  SettingsService._(this._prefs, this._config);

  static const _key = 'blocker_config_v1';

  final SharedPreferences _prefs;
  BlockerConfig _config;

  BlockerConfig get config => _config;

  static Future<SettingsService> load() async {
    final prefs = await SharedPreferences.getInstance();
    var config = const BlockerConfig();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        config = BlockerConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        // Corrupt value: fall back to defaults.
      }
    }
    return SettingsService._(prefs, config);
  }

  Future<void> update(BlockerConfig next) async {
    if (next == _config) return;
    _config = next;
    notifyListeners();
    await _prefs.setString(_key, jsonEncode(next.toJson()));
  }
}
