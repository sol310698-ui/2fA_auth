import 'package:flutter/material.dart';

class AppTheme {
  static const _primary = Color(0xFF4C6FFF);
  static const _accent = Color(0xFF00C2A8);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      secondary: _accent,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF5F6FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: _primary,
      secondary: _accent,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF101319),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1B1F27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
      ),
    );
  }

  /// Deterministic color for an account's avatar, seeded from its name so
  /// the same issuer always gets the same color.
  static Color colorFor(String seed) {
    const palette = [
      Color(0xFF4C6FFF),
      Color(0xFF00C2A8),
      Color(0xFFFF7A59),
      Color(0xFF9B5DE5),
      Color(0xFFF15BB5),
      Color(0xFF00BBF9),
      Color(0xFFFEE440),
      Color(0xFF06D6A0),
    ];
    if (seed.isEmpty) return palette.first;
    final idx = seed.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }
}
