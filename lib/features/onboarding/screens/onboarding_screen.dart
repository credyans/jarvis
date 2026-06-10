import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'emoji': '🤖',
      'title': 'Meet Jarvis',
      'subtitle': 'Your personal life operating system. Manage tasks, habits, money, and memories — all in one place.',
    },
    {
      'emoji': '✨',
      'title': 'One App, Your Entire Life',
      'subtitle': 'Tasks, habits, finances, and memories — all connected. Every action contributes to your life record.',
    },
    {
      'override': 'custom_visual_page3',
      'emoji': '🚀',
      'title': 'Start Your Journey',
      'subtitle': 'Let Jarvis prepare your world. Set up your profile and get started in seconds.',
    }
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar with Skip
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                  child: _currentPage < 2
                      ? TextButton(
                          onPressed: () => context.go('/setup'),
                          child: Text(
                            'Skip',
                            style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox(height: 48.0),
                ),
              ),

              // PageView Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _onboardingData.length,
                  itemBuilder: (context, index) {
                    final data = _onboardingData[index];
                    return _OnboardingPageView(
                      emoji: data['emoji']!,
                      title: data['title']!,
                      subtitle: data['subtitle']!,
                    );
                  },
                ),
              ),

              // Bottom Area (Indicators + Buttons)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dot Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _onboardingData.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          height: 8.0,
                          width: _currentPage == index ? 24.0 : 8.0,
                          decoration: BoxDecoration(
                            color: _currentPage == index ? AppColors.primary : AppColors.border,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Actions Button
                    JarvisButton(
                      text: _currentPage == 2 ? 'Get Started' : 'Next',
                      isFullWidth: true,
                      onPressed: () {
                        if (_currentPage < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOutCubic,
                          );
                        } else {
                          context.go('/setup');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;

  const _OnboardingPageView({
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Large Emoji
          Container(
            width: 140.0,
            height: 140.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppSpacing.cardRadius,
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20.0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 64.0),
            ),
          )
          .animate()
          .scaleXY(begin: 0.8, end: 1.0, duration: 800.ms, curve: Curves.easeOutBack),
          
          const SizedBox(height: 48.0),

          // Title
          Text(
            title,
            style: AppTypography.display(color: AppColors.textPrimary).copyWith(
              fontSize: 26.0,
            ),
            textAlign: TextAlign.center,
          )
          .animate()
          .fade(duration: 400.ms)
          .slideY(begin: 0.1, end: 0.0),

          const SizedBox(height: 16.0),

          // Subtitle
          Text(
            subtitle,
            style: AppTypography.body(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          )
          .animate()
          .fade(duration: 600.ms)
          .slideY(begin: 0.1, end: 0.0),
        ],
      ),
    );
  }
}
