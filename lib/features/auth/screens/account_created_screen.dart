import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';

class AccountCreatedScreen extends StatelessWidget {
  const AccountCreatedScreen({super.key});

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

                // Celebration Orb Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.35),
                          blurRadius: 32,
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.secondary,
                          AppColors.secondaryLight,
                        ],
                      ),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: AppColors.background,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Title & Tagline
                Text(
                  'Welcome to Jarvis',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Personal Life Operating System is Ready.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 48),

                // Focus area list cards
                JarvisCard(
                  padding: 20.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cloud_sync, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Secure Cloud Sync Enabled',
                            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your habits, goals, wellness markers, and journals will be kept safe and in perfect sync across all your devices.',
                        style: AppTypography.body(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.border),
                      const SizedBox(height: 16),
                      Text(
                        'Focus Areas Available:',
                        style: AppTypography.caption(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildFocusChip('📈 Goals'),
                          _buildFocusChip('🔄 Habits'),
                          _buildFocusChip('💰 Money'),
                          _buildFocusChip('📝 Journaling'),
                          _buildFocusChip('🏥 Wellness'),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),

                // Start Setup CTA
                JarvisButton(
                  text: 'Set Up Security',
                  onPressed: () => context.go('/biometrics-setup'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFocusChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceHover,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Text(
        text,
        style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
