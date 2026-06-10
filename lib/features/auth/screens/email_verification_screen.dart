import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  
  int _secondsRemaining = 59;
  Timer? _timer;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 59;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.isEmpty) {
      ToastNotification.show(context, 'Please enter the verification code', type: 'error');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).verifyEmail(widget.email, code);
      if (mounted) {
        ToastNotification.show(context, 'Email verified successfully!', type: 'success');
        context.go('/auth-success');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, e.toString().replaceAll('Exception: ', ''), type: 'error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Mock sending verification email
      await Future.delayed(const Duration(milliseconds: 600));
      _startTimer();
      if (mounted) {
        ToastNotification.show(context, 'Verification code resent!', type: 'info');
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Resend failed. Please try again.', type: 'error');
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
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cancel / Exit Options
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      onPressed: () => context.go('/login'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Illustration
                  Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.06),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.mark_email_read,
                          size: 64,
                          color: AppColors.primary.withOpacity(0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Header
                  Text(
                    'Verify Your Email',
                    textAlign: TextAlign.center,
                    style: AppTypography.display(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We sent a verification code to:',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption(color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.email,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tip for simulator
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.05),
                      borderRadius: AppSpacing.inputRadius,
                      border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Simulator: Enter "123456" to proceed.',
                            style: AppTypography.caption(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // OTP Code Input Field
                  JarvisInput(
                    label: 'Verification Code',
                    hintText: 'Enter 6-digit code',
                    controller: _otpController,
                    focusNode: _otpFocusNode,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Timer or Resend Button
                  Center(
                    child: _canResend
                        ? TextButton(
                            onPressed: _isLoading ? null : _handleResend,
                            child: Text(
                              'Resend verification link',
                              style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : Text(
                            'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                            style: AppTypography.body(color: AppColors.textSecondary),
                          ),
                  ),
                  const SizedBox(height: 32),

                  // Verify CTA
                  JarvisButton(
                    text: 'Verify Account',
                    isLoading: _isLoading,
                    onPressed: _handleVerify,
                  ),
                  const SizedBox(height: 16),
                  
                  // Open Mail App Shortcut
                  JarvisButton(
                    text: 'Open Mail App',
                    isOutline: true,
                    onPressed: () {
                      ToastNotification.show(context, 'Mail client opened (simulated)', type: 'info');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
