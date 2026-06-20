// lib/core/constants/app_colors.dart
// Futuristic dark-mode color palette for SpyEar

import 'package:flutter/material.dart';

/// App-wide color constants — deep space dark mode with cyan/electric blue accents
class AppColors {
  AppColors._();

  // ── Backgrounds ──────────────────────────────────────────────────────────────
  static const Color scaffoldBg     = Color(0xFF080C14);   // near black
  static const Color surfaceBg      = Color(0xFF0D1421);   // card/panel bg
  static const Color surfaceMid     = Color(0xFF111927);   // slightly lighter
  static const Color surfaceElevated = Color(0xFF162033);  // elevated card

  // ── Primary Accents ──────────────────────────────────────────────────────────
  static const Color primary        = Color(0xFF00D4FF);   // electric cyan
  static const Color primaryDim     = Color(0xFF0099CC);   // dimmed cyan
  static const Color primaryGlow    = Color(0x4400D4FF);   // glow effect

  // ── Secondary Accents ────────────────────────────────────────────────────────
  static const Color secondary      = Color(0xFF7B5CE4);   // electric violet
  static const Color secondaryDim   = Color(0xFF5B3FBF);
  static const Color secondaryGlow  = Color(0x447B5CE4);

  // ── Status Colors ─────────────────────────────────────────────────────────────
  static const Color liveGreen      = Color(0xFF00FF87);   // LIVE status
  static const Color liveGreenDim   = Color(0xFF00CC6A);
  static const Color liveGreenGlow  = Color(0x4400FF87);

  static const Color warningAmber   = Color(0xFFFFC107);
  static const Color errorRed       = Color(0xFFFF4757);
  static const Color errorRedGlow   = Color(0x44FF4757);

  // ── Text ──────────────────────────────────────────────────────────────────────
  static const Color textPrimary    = Color(0xFFF0F4FF);
  static const Color textSecondary  = Color(0xFF8B9BB4);
  static const Color textDisabled   = Color(0xFF3D4F68);
  static const Color textHint       = Color(0xFF4A5C78);

  // ── Borders / Dividers ───────────────────────────────────────────────────────
  static const Color border         = Color(0xFF1E2D45);
  static const Color borderBright   = Color(0xFF2A3F5F);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7B5CE4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient liveGradient = LinearGradient(
    colors: [Color(0xFF00FF87), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0D1B2E), Color(0xFF0D1421)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient micGlowGradient = RadialGradient(
    colors: [Color(0x6600D4FF), Color(0x0000D4FF)],
    radius: 0.7,
  );
}
