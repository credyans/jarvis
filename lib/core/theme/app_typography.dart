import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jarvis/core/theme/app_colors.dart';

/// Jarvis Design System — Typography
///
/// All text styles use Plus Jakarta Sans via [GoogleFonts].
/// Each factory accepts an optional [color] that defaults to
/// [AppColors.textPrimary].
class AppTypography {
  AppTypography._();

  // ── Display ─────────────────────────────────────────────────────────

  /// 32px / bold — hero numbers, splash titles.
  static TextStyle display({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  // ── Headings ────────────────────────────────────────────────────────

  /// 28px / bold — page titles.
  static TextStyle h1({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  /// 22px / semi-bold — section headers.
  static TextStyle h2({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// 18px / semi-bold — card titles, sub-sections.
  static TextStyle h3({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  // ── Body ────────────────────────────────────────────────────────────

  /// 15px / regular — default body text.
  static TextStyle body({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  /// 15px / medium — emphasized body text, labels.
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  // ── Small ───────────────────────────────────────────────────────────

  /// 13px / regular — captions, metadata, timestamps.
  static TextStyle caption({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  /// 11px / semi-bold — badges, tags, tiny labels.
  static TextStyle micro({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textSecondary,
      );
}
