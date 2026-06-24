import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/data/seed_data.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';

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
    var user = userState.value;
    
    if (user == null) {
      try {
        final authBox = await Hive.openBox('auth_mock_db');
        final email = 'demo@jarvis.local';
        final uid = 'demo_user_santhosh';
        
        final usersMap = Map<String, dynamic>.from(authBox.get('users', defaultValue: {}));
        usersMap[email] = {
          'id': uid,
          'name': 'Santhosh',
          'password': 'Password123!',
          'joinDate': DateTime.now().toIso8601String(),
          'currency': '₹',
          'onboardingComplete': true,
          'focusAreas': ['tasks', 'habits', 'money', 'journaling'],
          'wakeTime': '07:00'
        };
        await authBox.put('users', usersMap);
        await authBox.put('current_user_email', email);
        await authBox.put('is_verified', true);
        
        final userBox = await Hive.openBox('user_profile');
        await userBox.put('profile', {
          'id': uid,
          'name': 'Santhosh',
          'joinDate': DateTime.now().toIso8601String(),
          'currency': '₹',
          'onboardingComplete': true,
          'focusAreas': ['tasks', 'habits', 'money', 'journaling'],
          'wakeTime': '07:00'
        });

        // Seed default dummy data in Hive box
        await SeedData.seed(uid, force: true);
        
        // Load the session into Riverpod state
        await ref.read(userProvider.notifier).loadUser();
      } catch (e) {
        debugPrint('Error seeding demo user: $e');
      }
    }
    
    if (!mounted) return;
    context.go('/');
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
