import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class NetworkErrorScreen extends StatefulWidget {
  const NetworkErrorScreen({super.key});

  @override
  State<NetworkErrorScreen> createState() => _NetworkErrorScreenState();
}

class _NetworkErrorScreenState extends State<NetworkErrorScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    // Simulate network validation check
    await Future.delayed(const Duration(milliseconds: 1000));

    if (mounted) {
      setState(() {
        _isRetrying = false;
      });
      ToastNotification.show(context, 'Internet connection restored (simulated)', type: 'success');
      context.pop(); // Return to previous screen
    }
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

                // Offline Illustration
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
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: AppColors.primary.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Title
                Text(
                  'No Internet Connection',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Please check your network connection and try again. Jarvis needs an active internet connection to sync your dashboard data securely.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textSecondary).copyWith(
                    height: 1.5,
                  ),
                ),

                const Spacer(),

                // Action CTAs
                JarvisButton(
                  text: 'Retry Connection',
                  isLoading: _isRetrying,
                  onPressed: _handleRetry,
                ),
                const SizedBox(height: 16),
                JarvisButton(
                  text: 'Work Offline',
                  isOutline: true,
                  onPressed: () {
                    ToastNotification.show(context, 'Switched to offline preview mode', type: 'info');
                    context.go('/');
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
