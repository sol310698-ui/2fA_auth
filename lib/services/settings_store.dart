import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// App-wide settings (theme, app lock) — persisted encrypted, same as
/// account data, so nothing lands in plain shared_preferences.
class SettingsStore extends ChangeNotifier {
  static const _key = 'app_settings_v1';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ThemeMode themeMode = ThemeMode.system;
  bool lockEnabled = false;
  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final raw = await _storage.read(key: _key);
    if (raw != null && raw.isNotEmpty) {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      themeMode = _themeFromString(map['themeMode'] as String? ?? 'system');
      lockEnabled = map['lockEnabled'] as bool? ?? false;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final raw = jsonEncode({
      'themeMode': themeMode.name,
      'lockEnabled': lockEnabled,
    });
    await _storage.write(key: _key, value: raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _persist();
  }

  Future<void> setLockEnabled(bool enabled) async {
    lockEnabled = enabled;
    notifyListeners();
    await _persist();
  }

  ThemeMode _themeFromString(String s) {
    switch (s) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
