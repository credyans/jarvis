import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';

class GenericErrorScreen extends StatelessWidget {
  const GenericErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // Warning Symbol
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.06),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.error_outline_rounded,
                        size: 56,
                        color: AppColors.error.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Something Went Wrong',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'An unexpected system error occurred. Please try again. If this issue persists, please get in touch with support.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textSecondary).copyWith(
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Action CTAs
                JarvisButton(
                  text: 'Try Again',
                  onPressed: () => context.pop(),
                ),
                const SizedBox(height: 16),
                JarvisButton(
                  text: 'Contact Support',
                  isOutline: true,
                  onPressed: () {
                    context.go('/welcome');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
