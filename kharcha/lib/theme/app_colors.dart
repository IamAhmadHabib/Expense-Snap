import 'package:flutter/material.dart';

/// Kharcha Design System — Color Tokens
/// Inspired by Finora's warm neutral premium aesthetic.
class AppColors {
  AppColors._();

  // ─── Background ──────────────────────────────────────
  static const Color background = Color(0xFFFAF9F6); // Soft Claude-style cream
  static const Color backgroundDark = Color(0xFF1C1C1E);

  // ─── Surface (Cards, Sheets) ─────────────────────────
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF2C2C2E);
  static const Color surfaceVariant = Color(0xFFF0EDE8);
  static const Color surfaceVariantDark = Color(0xFF3A3A3C);

  // ─── Primary (Buttons, Headers) ──────────────────────
  static const Color primary = Color(0xFF1C1C1E); // Premium Deep Charcoal (Buttons/Icons)
  static const Color primaryLight = Color(0xFFFAF7F2);

  // ─── Accent (Highlights, CTAs) ───────────────────────
  static const Color accent = Color(0xFFE5A33C);
  static const Color accentLight = Color(0xFFF5DEB3);

  // ─── Semantic ────────────────────────────────────────
  static const Color success = Color(0xFF34C759);
  static const Color successDark = Color(0xFF30D158);
  static const Color danger = Color(0xFFE8634A);
  static const Color dangerDark = Color(0xFFFF6961);

  // ─── Text ────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF3D3D3D); // Sophisticated Deep Grey (Font)
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFFAEAEB2);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  // ─── Borders & Dividers ──────────────────────────────
  static const Color border = Color(0xFFE5E5EA);
  static const Color borderDark = Color(0xFF3A3A3C);
  static const Color divider = Color(0xFFF2F2F7);

  // ─── Page Indicator ──────────────────────────────────
  static const Color dotActive = Color(0xFF1C1C1E);
  static const Color dotInactive = Color(0xFFD1D1D6);
}
