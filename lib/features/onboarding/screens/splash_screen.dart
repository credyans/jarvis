import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/core/services/notification_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    // Wait for the splash animation to finish (2.5 seconds)
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    final userState = ref.read(userProvider);
    final user = userState.value;
    
    if (!mounted) return;
    
    if (user == null) {
      context.go('/welcome');
    } else if (!user.onboardingComplete) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon Container
              Container(
                width: 96.0,
                height: 96.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.jarvisButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 24.0,
                      spreadRadius: 2.0,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    'J',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 48.0,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              .animate()
              .fade(duration: 800.ms, curve: Curves.easeOutCubic)
              .scaleXY(begin: 0.7, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack),
              
              const SizedBox(height: 24.0),
              
              // Title
              Text(
                'Jarvis',
                style: AppTypography.display(color: AppColors.textPrimary),
              )
              .animate()
              .fade(delay: 300.ms, duration: 600.ms),
              
              const SizedBox(height: 8.0),
              
              // Tagline
              Text(
                'Your Personal Life Operating System',
                style: AppTypography.body(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              )
              .animate()
              .fade(delay: 600.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
