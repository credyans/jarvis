import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_spacing.dart';

class JarvisCard extends StatelessWidget {
  final Widget child;
  final double padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? color;
  final bool animate;
  final BoxBorder? border;

  const JarvisCard({
    super.key,
    required this.child,
    this.padding = 20.0,
    this.onTap,
    this.gradient,
    this.color,
    this.animate = true,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: color ?? (gradient == null ? Colors.white.withOpacity(0.06) : null),
        gradient: gradient,
        borderRadius: AppSpacing.cardRadius,
        border: border ?? Border.all(
          color: Colors.white.withOpacity(0.08),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 24.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppSpacing.cardRadius,
        child: InkWell(
          borderRadius: AppSpacing.cardRadius,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: child,
          ),
        ),
      ),
    );

    Widget card;
    if (kIsWeb) {
      card = Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white.withOpacity(0.06),
          borderRadius: AppSpacing.cardRadius,
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.cardRadius,
          child: cardContent,
        ),
      );
    } else {
      card = Container(
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: AppSpacing.cardRadius,
        ),
        child: ClipRRect(
          borderRadius: AppSpacing.cardRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
            child: cardContent,
          ),
        ),
      );
    }

    if (animate) {
      return card
          .animate()
          .fade(duration: 300.ms, curve: Curves.easeOutCubic)
          .scaleXY(begin: 0.96, end: 1.0, duration: 300.ms, curve: Curves.easeOutCubic);
    }

    return card;
  }
}
