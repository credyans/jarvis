import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class AccountLockedScreen extends StatefulWidget {
  const AccountLockedScreen({super.key});

  @override
  State<AccountLockedScreen> createState() => _AccountLockedScreenState();
}

class _AccountLockedScreenState extends State<AccountLockedScreen> {
  int _secondsRemaining = 15 * 60; // 15 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        if (mounted) {
          ToastNotification.show(context, 'Lockout period ended. You can try logging in again.', type: 'info');
          context.go('/login');
        }
      }
    });
  }

  String _formatTimer() {
    final mins = _secondsRemaining ~/ 60;
    final secs = _secondsRemaining % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
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

                // Warning Icon
                Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withOpacity(0.06),
                      border: Border.all(
                        color: AppColors.error.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error.withOpacity(0.12),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          size: 44,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Header
                Text(
                  'Account Locked',
                  textAlign: TextAlign.center,
                  style: AppTypography.display(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Too many login attempts. For your security, this account has been temporarily locked.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),

                // Countdown Card
                JarvisCard(
                  padding: 20.0,
                  child: Column(
                    children: [
                      Text(
                        'Remaining Lock Duration',
                        style: AppTypography.caption(color: AppColors.textTertiary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTimer(),
                        style: AppTypography.display(color: AppColors.error).copyWith(
                          fontFamily: 'monospace',
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // CTAs
                JarvisButton(
                  text: 'Contact Support',
                  onPressed: () {
                    ToastNotification.show(context, 'Support request submitted', type: 'info');
                  },
                ),
                const SizedBox(height: 16),
                JarvisButton(
                  text: 'Return to Welcome',
                  isOutline: true,
                  onPressed: () => context.go('/welcome'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
