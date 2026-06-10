import 'package:flutter/material.dart';

import 'package:jarvis/core/theme/app_colors.dart';

/// Jarvis Design System — Spacing, Radii, Shadows & Layout Constants
///
/// Provides a consistent spatial scale, border-radius presets,
/// shadow definitions, and common padding patterns used across the app.
class AppSpacing {
  AppSpacing._();

  // ── Spacing Scale ───────────────────────────────────────────────────

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double massive = 64;

  // ── Radius Values ──────────────────────────────────────────────────

  static const double radiusCard = 28;
  static const double radiusButton = 16;
  static const double radiusInput = 16;
  static const double radiusChip = 24;
  static const double radiusBottomNav = 32;
  static const double radiusFull = 999;

  // ── BorderRadius Getters ───────────────────────────────────────────

  static BorderRadius get cardRadius =>
      const BorderRadius.all(Radius.circular(radiusCard));

  static BorderRadius get buttonRadius =>
      const BorderRadius.all(Radius.circular(radiusButton));

  static BorderRadius get inputRadius =>
      const BorderRadius.all(Radius.circular(radiusInput));

  static BorderRadius get chipRadius =>
      const BorderRadius.all(Radius.circular(radiusChip));

  static BorderRadius get bottomNavRadius =>
      const BorderRadius.all(Radius.circular(radiusBottomNav));

  static BorderRadius get fullRadius =>
      const BorderRadius.all(Radius.circular(radiusFull));

  // ── Shadows ─────────────────────────────────────────────────────────

  /// Subtle card shadow for elevated surfaces.
  static BoxShadow get cardShadow => BoxShadow(
        color: AppColors.textPrimary.withOpacity(0.04),
        blurRadius: 16,
        offset: const Offset(0, 4),
      );

  /// List of box shadows ready to drop into a [BoxDecoration].
  static List<BoxShadow> get cardShadows => [cardShadow];

  // ── Common Padding Patterns ─────────────────────────────────────────

  /// Horizontal screen padding (24px left/right).
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: xl);

  /// Internal card padding (20px all sides).
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Vertical section spacing (24px top/bottom).
  static const EdgeInsets sectionPadding =
      EdgeInsets.symmetric(vertical: xl);

  /// Symmetric padding for list items / rows.
  static const EdgeInsets listItemPadding =
      EdgeInsets.symmetric(horizontal: base, vertical: md);
}
