import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/features/onboarding/screens/splash_screen.dart';
import 'package:jarvis/features/onboarding/screens/onboarding_screen.dart';
import 'package:jarvis/features/onboarding/screens/setup_screen.dart';
import 'package:jarvis/shared/widgets/app_scaffold.dart';

// Authentication Screens
import 'package:jarvis/features/auth/screens/welcome_screen.dart';
import 'package:jarvis/features/auth/screens/signup_screen.dart';
import 'package:jarvis/features/auth/screens/login_screen.dart';
import 'package:jarvis/features/auth/screens/forgot_password_screen.dart';
import 'package:jarvis/features/auth/screens/reset_password_screen.dart';
import 'package:jarvis/features/auth/screens/email_verification_screen.dart';
import 'package:jarvis/features/auth/screens/account_created_screen.dart';
import 'package:jarvis/features/auth/screens/biometric_setup_screen.dart';
import 'package:jarvis/features/auth/screens/account_locked_screen.dart';
import 'package:jarvis/features/auth/screens/session_expired_screen.dart';
import 'package:jarvis/features/auth/screens/network_error_screen.dart';
import 'package:flutter/material.dart';
import 'package:jarvis/features/auth/screens/generic_error_screen.dart';
import 'package:jarvis/features/auth/screens/profile_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    onException: (context, state, router) {
      final uriStr = state.uri.toString();
      if (uriStr.contains('access_token=')) {
        if (uriStr.contains('type=recovery')) {
          final reg = RegExp(r'access_token=([^&]+)');
          final match = reg.firstMatch(uriStr);
          if (match != null) {
            final token = match.group(1);
            router.go('/reset-password', extra: token);
            return;
          }
        } else if (uriStr.contains('type=signup') || uriStr.contains('type=invite')) {
          router.go('/auth-success');
          return;
        }
      }
      router.go('/welcome');
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.extra as String? ?? 'mock_token_default';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final email = state.extra as String? ?? 'user@example.com';
          return EmailVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/auth-success',
        builder: (context, state) => const AccountCreatedScreen(),
      ),
      GoRoute(
        path: '/biometrics-setup',
        builder: (context, state) => const BiometricSetupScreen(),
      ),
      GoRoute(
        path: '/locked',
        builder: (context, state) => const AccountLockedScreen(),
      ),
      GoRoute(
        path: '/session-expired',
        builder: (context, state) => const SessionExpiredScreen(),
      ),
      GoRoute(
        path: '/network-error',
        builder: (context, state) => const NetworkErrorScreen(),
      ),
      GoRoute(
        path: '/generic-error',
        builder: (context, state) => const GenericErrorScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const AppScaffold(),
      ),
    ],
  );
});
