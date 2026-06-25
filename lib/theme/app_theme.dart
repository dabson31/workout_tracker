import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// central place for all colors used across the app
class AppColors {
  static const background = Color(0xFF0E0B16);
  static const surface = Color(0xFF1B1625);
  static const surfaceLight = Color(0xFF241D31);
  static const primary = Color(0xFF8B5CF6);
  static const primaryDark = Color(0xFF5B21B6);
  static const textPrimary = Color(0xFFF4F1FA);
  static const textSecondary = Color(0xFF9A93AD);
  static const danger = Color(0xFFEF5A6F);
}

// theme used in main.dart
ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: GoogleFonts.manrope().fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      foregroundColor: AppColors.textPrimary,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
    ),
    cardColor: AppColors.surface,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: AppColors.textPrimary),
      bodySmall: TextStyle(color: AppColors.textSecondary),
    ),
  );
}