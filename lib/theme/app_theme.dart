import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF6C7CFF);
  static const accent = Color(0xFF00E0C6);
  static const danger = Color(0xFFFF5C7A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: accent,
      brightness: Brightness.light,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFF3F4FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      secondary: accent,
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFF0B0D14),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF171B26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// Deterministic gradient for an account's avatar, seeded from its name
  /// so the same issuer always gets the same colors.
  static List<Color> gradientFor(String seed) {
    const palette = [
      [Color(0xFF6C7CFF), Color(0xFF00E0C6)],
      [Color(0xFFFF7A59), Color(0xFFFFC15E)],
      [Color(0xFF9B5DE5), Color(0xFFF15BB5)],
      [Color(0xFF00BBF9), Color(0xFF00E0C6)],
      [Color(0xFFFEE440), Color(0xFFFF7A59)],
      [Color(0xFF06D6A0), Color(0xFF00BBF9)],
      [Color(0xFFF15BB5), Color(0xFF9B5DE5)],
      [Color(0xFFFF5C7A), Color(0xFFFEE440)],
    ];
    if (seed.isEmpty) return palette.first;
    final idx = seed.codeUnits.fold<int>(0, (a, b) => a + b) % palette.length;
    return palette[idx];
  }

  static Color colorFor(String seed) => gradientFor(seed).first;

  static BoxDecoration heroGradientDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: isDark
            ? [const Color(0xFF1B2036), const Color(0xFF0B0D14)]
            : [const Color(0xFFEDEFFF), const Color(0xFFF3F4FA)],
      ),
    );
  }
}
