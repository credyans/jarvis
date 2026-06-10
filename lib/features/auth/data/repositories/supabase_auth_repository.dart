import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jarvis/features/auth/domain/repositories/auth_repository.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';

class SupabaseAuthRepository implements AuthRepository {
  static const String _biometricBox = 'supabase_auth_prefs';

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Stream<String?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      return data.session?.user.id;
    });
  }

  // ── Profile helpers ──────────────────────────────────────────────────────────

  Future<UserModel?> _fetchProfile(String userId) async {
    try {
      final data = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return _profileToUserModel(data, userId);
    } catch (_) {
      return null;
    }
  }

  UserModel _profileToUserModel(Map<String, dynamic> data, String userId) {
    DateTime joinDate;
    final rawJoinDate = data['join_date'];
    if (rawJoinDate is String) {
      joinDate = DateTime.tryParse(rawJoinDate) ?? DateTime.now();
    } else {
      joinDate = DateTime.now();
    }

    return UserModel(
      id: userId,
      name: data['name'] as String? ?? 'Jarvis User',
      joinDate: joinDate,
      currency: data['currency'] as String? ?? '₹',
      onboardingComplete: data['onboarding_complete'] as bool? ?? false,
      wakeTime: data['wake_time'] as String?,
      focusAreas: List<String>.from(data['focus_areas'] ?? []),
    );
  }

  // ── AuthRepository interface ─────────────────────────────────────────────────

  @override
  Future<UserModel?> getCurrentUser() async {
    final session = _client.auth.currentSession;
    if (session == null) return null;
    return await _fetchProfile(session.user.id);
  }

  @override
  Future<bool> hasUser() async {
    return _client.auth.currentSession != null;
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await _client.from('profiles').insert({
        'id': user.id,
        'name': user.name,
        'currency': user.currency,
        'onboarding_complete': user.onboardingComplete,
        'wake_time': user.wakeTime,
        'focus_areas': user.focusAreas,
      });
    } catch (_) {
      await updateUser(user);
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _client.from('profiles').update({
      'name': user.name,
      'currency': user.currency,
      'onboarding_complete': user.onboardingComplete,
      'wake_time': user.wakeTime,
      'focus_areas': user.focusAreas,
    }).eq('id', user.id);
  }

  // ── Sign Up ──────────────────────────────────────────────────────────────────

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    final response = await _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {'full_name': name},
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Sign up failed. Please try again.');
    }

    // Wait briefly for the trigger to create the profile row
    await Future.delayed(const Duration(milliseconds: 500));

    // Ensure the profile exists (trigger may not have run if email not verified)
    try {
      await _client.from('profiles').insert({
        'id': authUser.id,
        'name': name,
        'onboarding_complete': false,
        'focus_areas': <String>[],
      });
    } catch (_) {
      // Profile already created by trigger — ignore
    }

    return UserModel(
      id: authUser.id,
      name: name,
      joinDate: DateTime.now(),
      currency: '₹',
      onboardingComplete: false,
      focusAreas: const [],
    );
  }

  // ── Sign In ──────────────────────────────────────────────────────────────────

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );

    final authUser = response.user;
    if (authUser == null) {
      throw Exception('Sign in failed. Please check your credentials.');
    }

    final profile = await _fetchProfile(authUser.id);
    if (profile != null) return profile;

    // Create the missing profile row in the database automatically
    final newProfile = UserModel(
      id: authUser.id,
      name: authUser.userMetadata?['full_name'] as String? ?? 'Jarvis User',
      joinDate: DateTime.now(),
      currency: '₹',
      onboardingComplete: false,
      focusAreas: const [],
    );

    try {
      await saveUser(newProfile);
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }

    return newProfile;
  }

  // ── Anonymous Sign-In ────────────────────────────────────────────────────────

  @override
  Future<String> signInAnonymously() async {
    final response = await _client.auth.signInAnonymously();
    final authUser = response.user;
    if (authUser == null) throw Exception('Anonymous sign-in failed.');
    try {
      await _client.from('profiles').upsert({
        'id': authUser.id,
        'name': 'Jarvis Explorer',
        'onboarding_complete': false,
        'focus_areas': <String>[],
      });
    } catch (_) {}
    return authUser.id;
  }

  // ── Password Reset ───────────────────────────────────────────────────────────

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email.trim().toLowerCase());
  }

  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {
    // token is the access_token obtained from the deep-link (OTP flow)
    // Supabase web uses verifyOtp for recovery type, then updateUser
    try {
      await _client.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
      );
    } catch (_) {
      // If token is already exchanged (session active), just proceed
    }
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  // ── Email Verification ───────────────────────────────────────────────────────

  @override
  Future<void> verifyEmail(String email, String code) async {
    await _client.auth.verifyOTP(
      email: email.trim().toLowerCase(),
      token: code,
      type: OtpType.signup,
    );
  }

  // ── Social Sign-In (Stubs for web) ──────────────────────────────────────────

  @override
  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError(
        'Google Sign-In is not configured for this platform.');
  }

  @override
  Future<UserModel> signInWithApple() async {
    throw UnimplementedError(
        'Apple Sign-In is not configured for this platform.');
  }

  // ── Biometrics (local device feature) ────────────────────────────────────────

  Future<Box> _getBioBox() async {
    if (!Hive.isBoxOpen(_biometricBox)) {
      return await Hive.openBox(_biometricBox);
    }
    return Hive.box(_biometricBox);
  }

  @override
  Future<void> enableBiometrics(bool enable) async {
    final box = await _getBioBox();
    await box.put('biometric_enabled', enable);
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    final box = await _getBioBox();
    return box.get('biometric_enabled', defaultValue: false) as bool;
  }

  @override
  Future<UserModel?> authenticateWithBiometrics() async {
    final enabled = await isBiometricsEnabled();
    if (!enabled) throw Exception('Biometrics not enabled on this device.');
    return await getCurrentUser();
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
