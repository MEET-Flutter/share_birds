// lib/core/constants/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  // ── Dark Theme ──────────────────────────────────────────────────────────────
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primaryGlow;
          return AppColors.surfaceMid;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.border,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primaryGlow,
      ),
    );
  }

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    const lightScaffoldBg = Color(0xFFF4F7FC);
    const lightSurfaceBg  = Color(0xFFFFFFFF);
    const lightPrimary    = Color(0xFF007AFF);
    const lightSecondary  = Color(0xFF5856D6);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSec     = Color(0xFF64748B);
    const lightBorder      = Color(0xFFE2E8F0);

    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: lightPrimary,
      onPrimary: Color(0xFFFFFFFF),
      primaryContainer: Color(0xFFE0F2FE),
      onPrimaryContainer: lightPrimary,
      secondary: lightSecondary,
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFFEEF2FF),
      onSecondaryContainer: lightSecondary,
      error: AppColors.errorRed,
      onError: Color(0xFFFFFFFF),
      errorContainer: Color(0xFFFFE4E6),
      onErrorContainer: AppColors.errorRed,
      surface: lightSurfaceBg,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: Color(0xFFF8FAFC),
      onSurfaceVariant: lightTextSec,
      outline: lightBorder,
      outlineVariant: Color(0xFFCBD5E1),
      shadow: Color(0x1A000000),
      scrim: Color(0x33000000),
      inverseSurface: lightTextPrimary,
      onInverseSurface: lightScaffoldBg,
      inversePrimary: lightPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightScaffoldBg,
      fontFamily: 'Outfit',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurfaceBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return lightPrimary;
          return lightTextSec;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return const Color(0xFFBAE6FD);
          return const Color(0xFFE2E8F0);
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: lightPrimary,
        inactiveTrackColor: lightBorder,
        thumbColor: lightPrimary,
        overlayColor: Color(0x33007AFF),
      ),
    );
  }
}
