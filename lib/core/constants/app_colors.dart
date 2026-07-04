// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Vaultix design system color tokens.
/// Re-designed for the Google Material 3 UI spec (Light & Dark modes).
abstract class AppColors {
  // ─── Light Theme Colors ───────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FE);
  static const Color surfaceLight = Colors.white;
  static const Color surfaceCardLight = Colors.white;
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color textPrimaryLight = Color(0xFF1C1B1F);
  static const Color textSecondaryLight = Color(0xFF49454F);
  static const Color textMutedLight = Color(0xFF79747E);
  static const Color dividerLight = Color(0xFFE0E0E0);

  // ─── Dark Theme Colors (AMOLED) ───────────────────────────────────
  static const Color backgroundDark = Color(0xFF09080C);
  static const Color surfaceDark = Color(0xFF121118);
  static const Color surfaceCardDark = Color(0xFF1C1B22);
  static const Color borderDark = Color(0xFF35343A);
  static const Color textPrimaryDark = Color(0xFFE6E1E9);
  static const Color textSecondaryDark = Color(0xFFCAC4D0);
  static const Color textMutedDark = Color(0xFF93909A);
  static const Color dividerDark = Color(0xFF25242A);

  // ─── Brand / Accents (Shared or Adaptive) ─────────────────────────
  static const Color primary = Color(0xFF6338F6);       // Vibrant Google Purple
  static const Color primaryLight = Color(0xFF8C66FF);
  static const Color secondary = Color(0xFF5B4BFF);     // Indigo
  static const Color accent = Color(0xFF36D7FF);        // Cyan
  static const Color accentGreen = Color(0xFF2ECC71);   // Green
  static const Color accentOrange = Color(0xFFFF9F0A);  // Orange
  static const Color accentRed = Color(0xFFFF3B30);     // Red

  // ─── Category Brand Colors ────────────────────────────────────────
  static const Color google = Color(0xFF4285F4);
  static const Color instagram = Color(0xFFE1306C);
  static const Color twitter = Color(0xFF1DA1F2);
  static const Color netflix = Color(0xFFE50914);
  static const Color spotify = Color(0xFF1DB954);
  static const Color amazon = Color(0xFFFF9900);

  // ─── Gradients ────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6338F6), Color(0xFF5B4BFF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF36D7FF), Color(0xFF6338F6)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1F35), Color(0xFF0F1221)],
  );

  static const LinearGradient securityGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF6338F6), Color(0xFF3B0A75)],
  );

  static const RadialGradient shieldGlow = RadialGradient(
    center: Alignment.center,
    radius: 0.85,
    colors: [Color(0x806338F6), Color(0x005B4BFF)],
  );

  // ─── Compatibility Aliases (to prevent syntax compilation errors) ───
  static const Color background = backgroundDark;
  static const Color surface = surfaceDark;
  static const Color surfaceElevated = surfaceDark;
  static const Color surfaceCard = surfaceCardDark;
  static const Color textPrimary = textPrimaryDark;
  static const Color textSecondary = textSecondaryDark;
  static const Color textMuted = textMutedDark;
  static const Color textHint = textMutedDark;
  static const Color border = borderDark;
  static const Color borderGlow = Color(0x406338F6);
  static const Color divider = dividerDark;
  static const Color glowPurple = Color(0x556338F6);
  static const Color glowCyan = Color(0x4036D7FF);
  static const Color glowGreen = Color(0x402ECC71);
  static const Color glowRed = Color(0x40FF3B30);
}
