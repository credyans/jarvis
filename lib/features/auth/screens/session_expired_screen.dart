import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';

class SessionExpiredScreen extends StatelessWidget {
  const SessionExpiredScreen({super.key});

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

                // Timer Expired Icon
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.04),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.timer_off_outlined,
                        size: 56,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'Session Expired',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'For your security, you have been signed out due to inactivity. Please sign in again to resume your session.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textSecondary).copyWith(
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Action CTAs
                JarvisButton(
                  text: 'Sign In Again',
                  onPressed: () {
                    context.go('/login');
                  },
                ),
                const SizedBox(height: 16),
                JarvisButton(
                  text: 'Cancel',
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
