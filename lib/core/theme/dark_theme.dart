import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.info,
    brightness: Brightness.dark,
    primary: AppColors.info,
    surface: AppColors.darkPanel,
    error: AppColors.urgent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.darkPrimaryText,
    ),
    textTheme:
        const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
          titleLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
          titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
          bodyLarge: TextStyle(letterSpacing: 0),
          bodyMedium: TextStyle(letterSpacing: 0),
        ).apply(
          bodyColor: AppColors.darkPrimaryText,
          displayColor: AppColors.darkPrimaryText,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkPanel.withValues(alpha: 0.42),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.darkBorder.withValues(alpha: 0.7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.darkBorder.withValues(alpha: 0.7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppColors.info, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    ),
  );
}
