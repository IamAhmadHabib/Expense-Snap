import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Kharcha Design System — Typography Scale
/// Uses DM Sans for a clean, geometric, premium feel.
class AppTypography {
  AppTypography._();

  // ─── Base Font Family ────────────────────────────────
  static String get _fontFamily => GoogleFonts.dmSans().fontFamily!;

  // ─── Display (Large hero numbers) ────────────────────
  static TextStyle get display => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 48,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.1,
        letterSpacing: -1.0,
      );

  // ─── Heading 1 (Screen titles) ───────────────────────
  static TextStyle get h1 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 42,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.15,
        letterSpacing: -1.5,
      );

  // ─── Heading 2 (Section titles) ──────────────────────
  static TextStyle get h2 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.3,
        letterSpacing: -0.5,
      );

  // ─── Heading 3 (Card titles) ─────────────────────────
  static TextStyle get h3 => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.3,
      );

  // ─── Body (Main content) ─────────────────────────────
  static TextStyle get body => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.4,
      );

  // ─── Body Small ──────────────────────────────────────
  static TextStyle get bodySmall => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ─── Label (Buttons, Tags) ───────────────────────────
  static TextStyle get label => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnPrimary,
        height: 1.2,
      );

  // ─── Caption (Hints, timestamps) ─────────────────────
  static TextStyle get caption => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textTertiary,
        height: 1.4,
      );

  // ─── Overline (Small uppercase labels) ───────────────
  static TextStyle get overline => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.4,
        letterSpacing: 1.2,
      );

  // ─── Button (Action buttons) ────────────────────────
  static TextStyle get button => TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnPrimary,
        height: 1.0,
      );
}
