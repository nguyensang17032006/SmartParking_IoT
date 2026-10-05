import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF7F9FB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFECEEF0);
  static const surfaceHigh = Color(0xFFE6E8EA);
  static const primary = Color(0xFF131B2E);
  static const secondary = Color(0xFFE21E49);
  static const secondaryDark = Color(0xFFBA0035);
  static const green = Color(0xFF4EDEA3);
  static const greenDark = Color(0xFF005236);
  static const amber = Color(0xFFF59E0B);
  static const text = Color(0xFF191C1E);
  static const textMuted = Color(0xFF61646B);
  static const outline = Color(0xFFC6C6CD);
  // Aliases kept for existing screens using the earlier color names.
  static const ink = primary;
  static const muted = textMuted;
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.secondary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: AppColors.surface,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Tahoma',
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLow,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.secondary),
      ),
    ),
  );
}
