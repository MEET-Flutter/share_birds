// lib/core/constants/app_theme.dart
// Material 3 dark theme configuration for SpyEar

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF003545),
      onPrimaryContainer: AppColors.primary,
      secondary: AppColors.secondary,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF2A1F5F),
      onSecondaryContainer: AppColors.secondary,
      error: AppColors.errorRed,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFF4A0010),
      onErrorContainer: AppColors.errorRed,
      surface: AppColors.surfaceBg,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceElevated,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderBright,
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: AppColors.textPrimary,
      onInverseSurface: AppColors.scaffoldBg,
      inversePrimary: AppColors.primaryDim,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffoldBg,
      fontFamily: 'Outfit',

      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.scaffoldBg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: 0.5,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: AppColors.surfaceBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),

      // Switches
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGlow;
          }
          return AppColors.surfaceMid;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryDim;
          }
          return AppColors.border;
        }),
      ),

      // Sliders
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primaryGlow,
        valueIndicatorColor: AppColors.surfaceElevated,
        valueIndicatorTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Outfit',
        ),
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceElevated,
        contentTextStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontFamily: 'Outfit',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Dividers
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // Icon
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),

      // Text
      textTheme: const TextTheme(
        displayLarge:  TextStyle(fontFamily: 'Outfit', fontSize: 57, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
        displayMedium: TextStyle(fontFamily: 'Outfit', fontSize: 45, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        displaySmall:  TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineLarge: TextStyle(fontFamily: 'Outfit', fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineMedium:TextStyle(fontFamily: 'Outfit', fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        headlineSmall: TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleLarge:    TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        titleMedium:   TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
        titleSmall:    TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        bodyLarge:     TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary),
        bodyMedium:    TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        bodySmall:     TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary),
        labelLarge:    TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        labelMedium:   TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
        labelSmall:    TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textDisabled),
      ),
    );
  }
}
