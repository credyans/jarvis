import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _signInDemoUser() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).signInAnonymously();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(
          context,
          'Demo login failed: $e. Make sure Anonymous Sign-in is enabled in Supabase.',
          type: 'error',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(flex: 2),
                
                // 1. Ethereal Life Core Orb Logo
                Center(
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: AppColors.secondary.withOpacity(0.15),
                          blurRadius: 60,
                          spreadRadius: 2,
                        ),
                      ],
                      gradient: AppColors.jarvisButtonGradient,
                    ),
                    child: Center(
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.background.withOpacity(0.85),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.12),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.blur_on,
                            size: 44,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(duration: 800.ms).scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),
                
                const SizedBox(height: 32),

                // 2. Title & Subtitle
                Text(
                  'Jarvis',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary).copyWith(
                    letterSpacing: -0.5,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fade(delay: 200.ms, duration: 600.ms),

                const SizedBox(height: 12),

                Text(
                  'Your Personal Life Operating System.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(color: AppColors.textSecondary).copyWith(
                    letterSpacing: 0.2,
                  ),
                ).animate().fade(delay: 350.ms, duration: 600.ms),

                const Spacer(flex: 3),

                // 3. Action CTAs
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Try Demo User action
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _signInDemoUser,
                        child: _isLoading 
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : Text(
                              'Try Demo User',
                              style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                      ),
                    ).animate().fade(delay: 450.ms, duration: 500.ms),
                    
                    const SizedBox(height: 8),

                    // Get Started Button
                    JarvisButton(
                      text: 'Get Started',
                      onPressed: () => context.push('/signup'),
                    ).animate().fade(delay: 500.ms, duration: 500.ms).slideY(
                          begin: 0.2,
                          curve: Curves.easeOut,
                        ),
                    
                    const SizedBox(height: 16),
                    
                    // Already Have Account Button
                    JarvisButton(
                      text: 'I Already Have An Account',
                      isOutline: true,
                      onPressed: () => context.push('/login'),
                    ).animate().fade(delay: 600.ms, duration: 500.ms).slideY(
                          begin: 0.2,
                          curve: Curves.easeOut,
                        ),
                  ],
                ),

                const SizedBox(height: 32),

                // 4. Muted Legal Footer
                Text(
                  'By continuing, you agree to our\nTerms of Service & Privacy Policy.',
                  textAlign: TextAlign.center,
                  style: AppTypography.caption(color: AppColors.textTertiary).copyWith(
                    height: 1.4,
                  ),
                ).animate().fade(delay: 750.ms, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
