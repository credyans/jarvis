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

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  bool _isLoading = false;
  bool _isSuccess = false;

  // Validation states
  bool _isLengthValid = false;
  bool _isUpperValid = false;
  bool _isNumValid = false;
  bool _isSpecialValid = false;
  bool _isConfirmMatch = false;

  String? _passwordError;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    setState(() {
      _isLengthValid = pass.length >= 8;
      _isUpperValid = pass.contains(RegExp(r'[A-Z]'));
      _isNumValid = pass.contains(RegExp(r'[0-9]'));
      _isSpecialValid = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      final isStrengthValid = _isLengthValid && _isUpperValid && _isNumValid && _isSpecialValid;
      if (pass.isEmpty) {
        _passwordError = null;
      } else if (!isStrengthValid) {
        _passwordError = 'Password does not meet requirements';
      } else {
        _passwordError = null;
      }
    });
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _isConfirmMatch = pass == confirm && confirm.isNotEmpty;
      if (confirm.isEmpty) {
        _confirmError = null;
      } else if (!_isConfirmMatch) {
        _confirmError = 'Passwords do not match';
      } else {
        _confirmError = null;
      }
    });
  }

  bool get _isValid => _isLengthValid && _isUpperValid && _isNumValid && _isSpecialValid && _isConfirmMatch;

  Future<void> _handleResetPassword() async {
    if (!_isValid) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).confirmPasswordReset(widget.token, _passwordController.text);
      setState(() {
        _isSuccess = true;
      });
      if (mounted) {
        ToastNotification.show(context, 'Password updated successfully!', type: 'success');
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

  Widget _buildChecklistItem(String title, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_off,
            size: 14,
            color: isValid ? AppColors.success : AppColors.textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTypography.caption(
              color: isValid ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
                if (!_isSuccess) ...[
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    'Create New Password',
                    style: AppTypography.display(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please set your new secure password.',
                    style: AppTypography.body(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // Password Field
                  JarvisInput(
                    label: 'New Password',
                    hintText: '••••••••',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    isPassword: true,
                    errorText: _passwordError,
                    isSuccess: _isLengthValid && _isUpperValid && _isNumValid && _isSpecialValid,
                  ),
                  const SizedBox(height: 12),

                  // Requirements Checklist
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildChecklistItem('Minimum 8 characters', _isLengthValid),
                        _buildChecklistItem('One uppercase letter', _isUpperValid),
                        _buildChecklistItem('One numeric digit', _isNumValid),
                        _buildChecklistItem('One special character (!@#\$%^&*)', _isSpecialValid),
                      ],
                    ),
                  ),

                  // Confirm Password Field
                  JarvisInput(
                    label: 'Confirm Password',
                    hintText: '••••••••',
                    controller: _confirmPasswordController,
                    focusNode: _confirmFocusNode,
                    isPassword: true,
                    errorText: _confirmError,
                    isSuccess: _isConfirmMatch,
                  ),
                  const SizedBox(height: 32),

                  // Reset Button
                  JarvisButton(
                    text: 'Reset Password',
                    isLoading: _isLoading,
                    onPressed: _isValid ? _handleResetPassword : null,
                  ),
                ] else ...[
                  const Spacer(),
                  
                  // Success Card
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
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Password Updated',
                          style: AppTypography.h2(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Your password has been changed successfully. You can now use your new password to sign in to Jarvis.',
                          textAlign: TextAlign.center,
                          style: AppTypography.body(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Go to Login Button
                  JarvisButton(
                    text: 'Go to Login',
                    onPressed: () => context.go('/login'),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
