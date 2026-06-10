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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    final enabled = await ref.read(userProvider.notifier).isBiometricsEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = enabled;
      });
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ToastNotification.show(context, 'Please fill in all fields', type: 'error');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(userProvider.notifier).signIn(email, password);
      if (mounted) {
        ToastNotification.show(context, 'Login successful!', type: 'success');
        context.go('/'); // Go to dashboard
      }
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      if (mounted) {
        if (errorMsg.contains('locked')) {
          context.push('/locked');
        } else {
          ToastNotification.show(context, errorMsg, type: 'error');
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await ref.read(userProvider.notifier).signInWithBiometrics();
      if (mounted) {
        ToastNotification.show(context, 'Signed in via biometrics', type: 'success');
        context.go('/');
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
        ToastNotification.show(context, 'Signed in via $type', type: 'success');
        context.go('/'); // Social redirects to main dashboard
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Back option
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // App Icon / Logo
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.2),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                        gradient: AppColors.jarvisButtonGradient,
                      ),
                      child: const Icon(
                        Icons.blur_on,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Title
                  Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: AppTypography.display(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to sync your personal life data.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // Email Input
                  JarvisInput(
                    label: 'Email Address',
                    hintText: 'hello@example.com',
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Password Input
                  JarvisInput(
                    label: 'Password',
                    hintText: '••••••••',
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    isPassword: true,
                  ),
                  const SizedBox(height: 12),

                  // Remember Me & Forgot Password Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primary,
                            checkColor: AppColors.background,
                            onChanged: (val) {
                              setState(() {
                                _rememberMe = val ?? false;
                              });
                            },
                          ),
                          Text(
                            'Remember Me',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => context.push('/forgot-password'),
                        child: Text(
                          'Forgot Password?',
                          style: AppTypography.caption(color: AppColors.primary).copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Sign In Buttons (Regular & Biometric)
                  Row(
                    children: [
                      Expanded(
                        child: JarvisButton(
                          text: 'Sign In',
                          isLoading: _isLoading,
                          onPressed: _handleLogin,
                        ),
                      ),
                      if (_isBiometricAvailable) ...[
                        const SizedBox(width: 16),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: AppSpacing.buttonRadius,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                              width: 1.5,
                            ),
                            color: AppColors.surface,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.fingerprint,
                              color: AppColors.primary,
                              size: 28,
                            ),
                            onPressed: _handleBiometricLogin,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Social login divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Or sign in with',
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

                  // Switch to Sign Up Link
                  Center(
                    child: GestureDetector(
                      onTap: () => context.pushReplacement('/signup'),
                      child: RichText(
                        text: TextSpan(
                          text: 'New to Jarvis? ',
                          style: AppTypography.caption(color: AppColors.textSecondary),
                          children: const [
                            TextSpan(
                              text: 'Create Account',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
