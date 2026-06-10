import 'package:flutter/material.dart';

/// Jarvis Design System — Color Palette
///
/// Premium deep indigo / periwinkle dark theme matching Google Stitch designs.
class AppColors {
  AppColors._();

  // ── Background ──────────────────────────────────────────────────────
  static const Color background = Color(0xFF0B1326);
  static const Color backgroundGradientEnd = Color(0xFF060D20);

  // ── Surface ─────────────────────────────────────────────────────────
  static const Color surface = Color(0xFF171F33);
  static const Color surfaceHover = Color(0xFF222A3E);
  static const Color surfaceContainerHigh = Color(0xFF222A3E);
  static const Color surfaceContainerHighest = Color(0xFF2D3449);
  static const Color surfaceContainerLow = Color(0xFF131B2E);
  static const Color surfaceContainerLowest = Color(0xFF060D20);

  // ── Primary (soft periwinkle/lavender) ────────────────────────────────────────────
  static const Color primary = Color(0xFFC0C1FF);
  static const Color primaryButton = Color(0xFF6366FF);
  static const Color primaryLight = Color(0xFFE1DFFF);
  static const Color primaryDark = Color(0xFF404176);

  // ── Secondary (soft emerald/mint) ───────────────────────────────────────
  static const Color secondary = Color(0xFF4EDEA3);
  static const Color secondaryLight = Color(0xFF6FFBBE);

  // ── Semantic ────────────────────────────────────────────────────────
  static const Color success = Color(0xFF4EDEA3);
  static const Color successLight = Color(0xFF005236);

  static const Color warning = Color(0xFFF0DAFF);
  static const Color warningLight = Color(0xFFDDB7FF);

  static const Color error = Color(0xFFFFB4AB);
  static const Color errorLight = Color(0xFF93000A);

  // ── Navigation Bar ──────────────────────────────────────────────────
  static const Color navBar = Color(0xFF171F33);
  static const Color navBarIcon = Color(0x80DBE2FD); // 50% text primary
  static const Color navBarActive = Color(0xFFDBE2FD);

  // ── Text ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFDBE2FD);
  static const Color textSecondary = Color(0xFFC7C5D0);
  static const Color textTertiary = Color(0xFF918F9A);

  // ── Border ──────────────────────────────────────────────────────────
  static const Color border = Color(0xFF46464F);

  // ── Gradients ───────────────────────────────────────────────────────

  /// Main background gradient: deep indigo -> space black.
  static LinearGradient get backgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [background, backgroundGradientEnd],
      );

  /// Jarvis AI orb button gradient: soft periwinkle to orchid.
  static LinearGradient get jarvisButtonGradient => const LinearGradient(
        colors: [
          Color(0xFFC0C1FF),
          Color(0xFFDDB7FF),
          Color(0xFFF0DAFF),
        ],
      );

  /// Mood arc background gradient.
  static LinearGradient get moodArcGradient => const LinearGradient(
        colors: [
          Color(0xFFC0C1FF),
          Color(0xFFDDB7FF),
        ],
      );
}
