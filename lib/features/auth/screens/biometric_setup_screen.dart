import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen> {
  bool _isLoading = false;

  Future<void> _handleEnableNow() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).enableBiometrics(true);
      if (mounted) {
        ToastNotification.show(context, 'Biometrics enabled successfully!', type: 'success');
        context.go('/setup'); // Go to onboarding setup steps
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Could not configure biometrics: $e', type: 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSkip() {
    context.go('/setup');
  }

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

                // Center Graphic
                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary.withOpacity(0.06),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.1),
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Title
                Text(
                  'Secure Quick Access',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Enable Face ID or Fingerprint recognition to access Jarvis instantly and securely without entering your password.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textSecondary).copyWith(
                    height: 1.5,
                  ),
                ),
                
                const Spacer(),

                // Privacy Trust Banner
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: AppColors.textTertiary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Your biometric data never leaves your device.',
                      style: AppTypography.caption(color: AppColors.textTertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Action CTAs
                JarvisButton(
                  text: 'Enable Now',
                  isLoading: _isLoading,
                  onPressed: _handleEnableNow,
                ),
                const SizedBox(height: 16),
                JarvisButton(
                  text: 'Enable Later',
                  isOutline: true,
                  onPressed: _handleSkip,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
