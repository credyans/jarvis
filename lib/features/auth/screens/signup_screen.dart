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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusFocusNode = FocusNode();

  bool _acceptTerms = false;
  bool _isLoading = false;

  // Validation States
  bool _isNameValid = false;
  bool _isEmailValid = false;
  bool _isPasswordLengthValid = false;
  bool _isPasswordUpperValid = false;
  bool _isPasswordNumValid = false;
  bool _isPasswordSpecialValid = false;
  bool _isPasswordStrengthValid = false;
  bool _isConfirmPasswordValid = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _passwordController.addListener(_validatePassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusFocusNode.dispose();
    super.dispose();
  }

  void _validateName() {
    setState(() {
      _isNameValid = _nameController.text.trim().length >= 2;
    });
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    setState(() {
      if (email.isEmpty) {
        _isEmailValid = false;
        _emailError = null;
      } else if (!emailRegExp.hasMatch(email)) {
        _isEmailValid = false;
        _emailError = 'Please enter a valid email address';
      } else {
        _isEmailValid = true;
        _emailError = null;
      }
    });
  }

  void _validatePassword() {
    final pass = _passwordController.text;
    setState(() {
      _isPasswordLengthValid = pass.length >= 8;
      _isPasswordUpperValid = pass.contains(RegExp(r'[A-Z]'));
      _isPasswordNumValid = pass.contains(RegExp(r'[0-9]'));
      _isPasswordSpecialValid = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      
      _isPasswordStrengthValid = _isPasswordLengthValid &&
          _isPasswordUpperValid &&
          _isPasswordNumValid &&
          _isPasswordSpecialValid;

      if (pass.isEmpty) {
        _passwordError = null;
      } else if (!_isPasswordStrengthValid) {
        _passwordError = 'Password does not meet requirements';
      } else {
        _passwordError = null;
      }
    });
    _validateConfirmPassword(); // Recalculate match
  }

  void _validateConfirmPassword() {
    final pass = _passwordController.text;
    final confirmPass = _confirmPasswordController.text;
    setState(() {
      if (confirmPass.isEmpty) {
        _isConfirmPasswordValid = false;
        _confirmPasswordError = null;
      } else if (pass != confirmPass) {
        _isConfirmPasswordValid = false;
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _isConfirmPasswordValid = true;
        _confirmPasswordError = null;
      }
    });
  }

  bool get _isFormValid {
    return _isNameValid &&
        _isEmailValid &&
        _isPasswordStrengthValid &&
        _isConfirmPasswordValid &&
        _acceptTerms;
  }

  Future<void> _handleSignUp() async {
    if (!_isFormValid) return;
    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).signUp(
            _nameController.text.trim(),
            _emailController.text.trim(),
            _passwordController.text,
          );
      
      if (mounted) {
        ToastNotification.show(context, 'Account created successfully!', type: 'success');
        context.push('/verify-email', extra: _emailController.text.trim());
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

  Future<void> _handleSocialLogin(String type) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (type == 'google') {
        await ref.read(userProvider.notifier).signInWithGoogle();
      } else {
        await ref.read(userProvider.notifier).signInWithApple();
      }
      
      if (mounted) {
        ToastNotification.show(context, 'Logged in via $type', type: 'success');
        context.go('/setup'); // New users go to onboarding setup
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Social sign in failed: $e', type: 'error');
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
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(24.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Back Button & Progress
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                          onPressed: () => context.pop(),
                        ),
                        Text(
                          'Step 1 of 2',
                          style: AppTypography.caption(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'Create Account',
                      style: AppTypography.display(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start your personal life operating system.',
                      style: AppTypography.body(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 32),

                    // Name Input
                    JarvisInput(
                      label: 'Full Name',
                      hintText: 'John Doe',
                      controller: _nameController,
                      focusNode: _nameFocusNode,
                      isSuccess: _isNameValid,
                    ),
                    const SizedBox(height: 16),

                    // Email Input
                    JarvisInput(
                      label: 'Email Address',
                      hintText: 'john@example.com',
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      isSuccess: _isEmailValid,
                    ),
                    const SizedBox(height: 16),

                    // Password Input
                    JarvisInput(
                      label: 'Password',
                      hintText: '••••••••',
                      controller: _passwordController,
                      focusNode: _passwordFocusNode,
                      isPassword: true,
                      errorText: _passwordError,
                      isSuccess: _isPasswordStrengthValid,
                    ),
                    const SizedBox(height: 12),

                    // Password Strength Checklist
                    if (_passwordController.text.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildChecklistItem('Minimum 8 characters', _isPasswordLengthValid),
                            _buildChecklistItem('One uppercase letter', _isPasswordUpperValid),
                            _buildChecklistItem('One numeric digit', _isPasswordNumValid),
                            _buildChecklistItem('One special character (!@#\$%^&*)', _isPasswordSpecialValid),
                          ],
                        ),
                      ),
                    ],

                    // Confirm Password Input
                    JarvisInput(
                      label: 'Confirm Password',
                      hintText: '••••••••',
                      controller: _confirmPasswordController,
                      focusNode: _confirmFocusFocusNode,
                      isPassword: true,
                      errorText: _confirmPasswordError,
                      isSuccess: _isConfirmPasswordValid && _passwordController.text.isNotEmpty,
                    ),
                    const SizedBox(height: 16),

                    // Terms Checklist
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          activeColor: AppColors.primary,
                          checkColor: AppColors.background,
                          onChanged: (val) {
                            setState(() {
                              _acceptTerms = val ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: Text(
                            'I accept the Terms of Service & Privacy Policy',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Continue Button
                    JarvisButton(
                      text: 'Continue',
                      isLoading: _isLoading,
                      onPressed: _isFormValid ? _handleSignUp : null,
                    ),
                    const SizedBox(height: 32),

                    // Social login divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Or continue with',
                            style: AppTypography.caption(color: AppColors.textTertiary),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Social buttons
                    Row(
                      children: [
                        Expanded(
                          child: JarvisButton(
                            text: 'Google',
                            isOutline: true,
                            onPressed: () => _handleSocialLogin('google'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: JarvisButton(
                            text: 'Apple',
                            isOutline: true,
                            onPressed: () => _handleSocialLogin('apple'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Switch to Login Link
                    Center(
                      child: GestureDetector(
                        onTap: () => context.pushReplacement('/login'),
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                            children: const [
                              TextSpan(
                                text: 'Sign In',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
