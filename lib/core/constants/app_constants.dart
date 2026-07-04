// lib/core/constants/app_constants.dart

/// Global spacing, radius and animation constants for Vaultix.
abstract class AppConstants {
  // ─── Spacing (8pt grid) ───────────────────────────────────────────
  static const double spaceXxs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;
  static const double spaceHuge = 48.0;

  // ─── Border Radius ────────────────────────────────────────────────
  static const double radiusXs = 8.0;
  static const double radiusSm = 12.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 20.0;
  static const double radiusXl = 24.0;
  static const double radiusXxl = 28.0;
  static const double radiusFull = 100.0;

  // ─── Animation Durations ──────────────────────────────────────────
  static const Duration durationFast = Duration(milliseconds: 200);
  static const Duration durationNormal = Duration(milliseconds: 350);
  static const Duration durationSlow = Duration(milliseconds: 500);
  static const Duration durationVeryFast = Duration(milliseconds: 120);

  // ─── Glass Card ───────────────────────────────────────────────────
  static const double glassBlur = 20.0;
  static const double glassBorderWidth = 0.8;
  static const double glassBorderOpacity = 0.15;
  static const double glassOpacity = 0.06;

  // ─── Bottom Nav ───────────────────────────────────────────────────
  static const double bottomNavHeight = 76.0;
  static const double fabSize = 56.0;

  // ─── App name ─────────────────────────────────────────────────────
  static const String appName = 'Vaultix';
  static const String appTagline = 'Secure. Simple. Powerful.';
}
