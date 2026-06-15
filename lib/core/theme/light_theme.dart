import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.info,
    brightness: Brightness.light,
    primary: AppColors.info,
    surface: AppColors.lightPanel,
    error: AppColors.urgent,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.lightBackground,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      foregroundColor: AppColors.lightPrimaryText,
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
          bodyColor: AppColors.lightPrimaryText,
          displayColor: AppColors.lightPrimaryText,
        ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.lightBorder.withValues(alpha: 0.65),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: AppColors.lightBorder.withValues(alpha: 0.65),
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
