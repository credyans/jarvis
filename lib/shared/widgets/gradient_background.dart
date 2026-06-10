import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Solid deep background color
        Container(
          color: AppColors.background,
        ),
        // Top Left Flare (Primary periwinkle blur)
        Positioned(
          left: -150,
          top: -150,
          child: Container(
            width: 400,
            height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.08),
            ),
          ),
        ),
        // Middle Right Flare (Orchid blur)
        Positioned(
          right: -100,
          top: MediaQuery.of(context).size.height * 0.4,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.warning.withOpacity(0.06),
            ),
          ),
        ),
        // Bottom Left/Center Flare (Emerald blur)
        Positioned(
          left: 50,
          bottom: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.05),
            ),
          ),
        ),
        // Blur filter to blend everything seamlessly
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Actual page content on top
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }
}
