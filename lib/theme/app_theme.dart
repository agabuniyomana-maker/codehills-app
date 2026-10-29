import 'package:flutter/material.dart';

/// Brand colors ported from the original Java Swing application.
class AppColors {
  AppColors._();

  static const Color gold = Color(0xFFBE964E);
  static const Color yellow = Color(0xFFFFD23C);
  static const Color cream = Color(0xFFFAF2D7);
  static const Color darkBrown = Color(0xFF372314);
  static const Color mutedBrown = Color(0xFF694E30);
  static const Color white = Color(0xFFFFFFFF);
}

/// Reusable styles matching the original portal's typography.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.gold,
        primary: AppColors.gold,
        secondary: AppColors.yellow,
        surface: AppColors.cream,
      ),
      scaffoldBackgroundColor: AppColors.cream,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.darkBrown,
        displayColor: AppColors.darkBrown,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.darkBrown,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBrown, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.white,
          minimumSize: const Size(0, 48),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 15,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.yellow, width: 1.5),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkBrown,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
