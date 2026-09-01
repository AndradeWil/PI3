import 'package:flutter/material.dart';

abstract final class AppColors {
  static const teal = Color(0xFF0C7A9B);
  static const amber = Color(0xFFF2A54A);
}

abstract final class AppTheme {
  static final light = _build(
    ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
      primary: AppColors.teal,
      secondary: AppColors.amber,
      surface: Colors.white,
    ),
    const Color(0xFFF0F6FB),
  );

  static final dark = _build(
    ColorScheme.fromSeed(
      seedColor: const Color(0xFF56BCD6),
      brightness: Brightness.dark,
      primary: const Color(0xFF56BCD6),
      secondary: const Color(0xFFFFBD70),
      surface: const Color(0xFF102A35),
    ),
    const Color(0xFF081C24),
  );

  static ThemeData _build(ColorScheme colors, Color background) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: colors,
      scaffoldBackgroundColor: background,
      fontFamily: 'Segoe UI',
      fontFamilyFallback: const ['Trebuchet MS', 'sans-serif'],
    );

    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colors.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.primaryContainer,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
    );
  }
}
