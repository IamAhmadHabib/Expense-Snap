import 'package:flutter/material.dart';

/// Kharcha Design System — Color Tokens
/// Inspired by Finora's warm neutral premium aesthetic.
class AppColors {
  AppColors._();

  // ─── Background ──────────────────────────────────────
  static const Color background = Color(
    0xFFFAF8F4,
  ); // Restored requested warm neutral
  static const Color backgroundDark = Color(0xFF1C1C1E);

  // ─── Surface (Cards, Sheets) ─────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2C2C2E);
  static const Color surfaceVariant = Color(0xFFF0EDE8);
  static const Color surfaceVariantDark = Color(0xFF3A3A3C);
  static const Color warmSurface = Color(0xFFFAF9F6);
  static const Color warmSurfaceMuted = Color(0xFFFAF6F0);

  // ─── Primary (Buttons, Headers) ──────────────────────
  static const Color primary = Color(
    0xFF1C1C1E,
  ); // Premium Deep Charcoal (Buttons/Icons)
  static const Color primaryLight = Color(0xFFFAF7F2);

  // ─── Accent (Highlights, CTAs) ───────────────────────
  static const Color accent = Color(0xFFE5A33C);
  static const Color accentLight = Color(0xFFF5DEB3);
  static const Color accentDeep = Color(0xFFE6A300);

  // ─── Semantic ────────────────────────────────────────
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF30D158);
  static const Color danger = Color(0xFFE8634A);
  static const Color dangerDark = Color(0xFFFF6961);

  // ─── Text ────────────────────────────────────────────
  static const Color textPrimary = Color(
    0xFF3D3D3D,
  ); // Sophisticated Deep Grey (Font)
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFAEAEB2);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ─── Borders & Dividers ──────────────────────────────
  static const Color border = Color(0xFFE5E5EA);
  static const Color borderDark = Color(0xFF3A3A3C);
  static const Color divider = Color(0xFFF2F2F7);
  static const Color warmBorder = Color(0xFFE8DDD0);

  // ─── Profile & Specific Tones ───────────────────────
  static const Color headerCard = Color(0xFF141210);
  static const Color sectionCard = Color(
    0xFFFFFFFF,
  ); // Pure white for high contrast
  static const Color sectionLabel = Color(0xFF1C1C1E); // Darker labels
  static const Color amberGold = Color(0xFFC9973A);
  static const Color dangerMuted = Color(0xFFA0392B);
  static const Color profileDivider = Color(0xFFEDE6DC);
  static const Color profileChevron = Color(0xFFC4B8A8);
  static const Color profileSubtext = Color(0xFF9C8E7E);
  static const Color warmCharcoal = Color(0xFF1A1612);
  static const Color softCharcoal = Color(0xFF333336);
  static const Color chartCharcoal = Color(0xFF4A4A4A);
  static const Color chartCharcoalDark = Color(0xFF383838);
  static const Color chartNeutral = Color(0xFF908D89);
  static const Color chartTrack = Color(0xFFF1F4F8);
  static const Color navInactive = Color(0xFF8C7E6E);
  static const Color insightSurface = Color(0xFF1E1E20);
  static const Color cameraBlack = Color(0xFF0A0A0A);
  static const Color cameraSurface = Color(0xFF0C0C0C);
  static const Color dangerSurface = Color(0xFFFFECEC);

  // ─── Page Indicator ──────────────────────────────────
  static const Color dotActive = Color(0xFF1C1C1E);
  static const Color dotInactive = Color(0xFFD1D1D6);
}
