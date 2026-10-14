import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide user settings. Dark mode is on by default.
class AppSettings {
  AppSettings._();

  static const String _darkKey = 'dark_mode';

  static final ValueNotifier<bool> darkMode = ValueNotifier<bool>(true);

  static SharedPreferences? _prefs;

  /// Call once before runApp.
  static Future<void> load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      darkMode.value = _prefs?.getBool(_darkKey) ?? true;
    } catch (_) {
      // Settings are a convenience: fall back to the default.
    }
  }

  static Future<void> setDarkMode(bool value) async {
    darkMode.value = value;
    try {
      await _prefs?.setBool(_darkKey, value);
    } catch (_) {}
  }
}
