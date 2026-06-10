import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isSent = false;
  String? _errorText;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _errorText = 'Email is required';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      await ref.read(userProvider.notifier).sendPasswordReset(email);
      setState(() {
        _isSent = true;
      });
      if (mounted) {
        ToastNotification.show(context, 'Reset link sent!', type: 'success');
      }
    } catch (e) {
      setState(() {
        _errorText = e.toString().replaceAll('Exception: ', '');
      });
      if (mounted) {
        ToastNotification.show(context, _errorText!, type: 'error');
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back Button
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                    onPressed: () => context.pop(),
                  ),
                ),
                const SizedBox(height: 24),

                if (!_isSent) ...[
                  // Header
                  Text(
                    'Reset Password',
                    style: AppTypography.display(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your email address and we will send you a link to reset your password.',
                    style: AppTypography.body(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 40),

                  // Email Input
                  JarvisInput(
                    label: 'Email Address',
                    hintText: 'hello@example.com',
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    errorText: _errorText,
                  ),
                  const SizedBox(height: 24),

                  // Send CTA
                  JarvisButton(
                    text: 'Send Reset Link',
                    isLoading: _isLoading,
                    onPressed: _handleSendResetLink,
                  ),
                ] else ...[
                  const Spacer(),
                  
                  // Success State Card
                  JarvisCard(
                    padding: 24.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success.withOpacity(0.15),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppColors.success,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Check Your Inbox',
                          style: AppTypography.h2(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We sent a reset link to:',
                          style: AppTypography.caption(color: AppColors.textTertiary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _emailController.text.trim(),
                          style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please click the link inside the email to configure your new password.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Actions
                  JarvisButton(
                    text: 'Open Mail App',
                    onPressed: () {
                      // Navigate to password reset simulator route with a mock token
                      context.pushReplacement('/reset-password', extra: 'mock_token_123456');
                    },
                  ),
                  const SizedBox(height: 16),
                  JarvisButton(
                    text: 'Back to Login',
                    isOutline: true,
                    onPressed: () => context.pop(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
