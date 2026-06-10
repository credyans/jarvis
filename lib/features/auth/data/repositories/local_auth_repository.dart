import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/features/auth/domain/repositories/auth_repository.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';
import 'package:jarvis/data/repositories/user_repository.dart' as local;
import 'package:jarvis/data/models/user_model.dart' as local_model;
import 'package:jarvis/core/utils/id_generator.dart';

class LocalAuthRepository implements AuthRepository {
  final local.UserRepository _localRepo = local.UserRepository();
  static const String _authBoxName = 'auth_mock_db';

  final StreamController<String?> _authStateController = StreamController<String?>.broadcast();

  LocalAuthRepository() {
    _init();
  }

  Future<void> _init() async {
    final user = await getCurrentUser();
    if (user != null) {
      _authStateController.add(user.id);
    } else {
      _authStateController.add(null);
    }
  }

  @override
  Stream<String?> get authStateChanges => _authStateController.stream;

  Future<Box> _getAuthBox() async {
    if (!Hive.isBoxOpen(_authBoxName)) {
      return await Hive.openBox(_authBoxName);
    }
    return Hive.box(_authBoxName);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final box = await _getAuthBox();
    final currentEmail = box.get('current_user_email') as String?;
    if (currentEmail == null) {
      final u = await _localRepo.getCurrentUser();
      if (u == null) return null;
      return UserModel(
        id: u.id,
        name: u.name,
        joinDate: u.joinDate,
        currency: u.currency,
        onboardingComplete: u.onboardingComplete,
        wakeTime: u.wakeTime,
        focusAreas: u.focusAreas,
      );
    }

    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    final userData = usersMap[currentEmail];
    if (userData == null) return null;
    
    return UserModel(
      id: userData['id'] as String,
      name: userData['name'] as String,
      joinDate: DateTime.parse(userData['joinDate'] as String),
      currency: userData['currency'] as String? ?? '₹',
      onboardingComplete: userData['onboardingComplete'] as bool? ?? false,
      wakeTime: userData['wakeTime'] as String?,
      focusAreas: List<String>.from(userData['focusAreas'] ?? []),
    );
  }

  @override
  Future<void> saveUser(UserModel user) async {
    final lm = local_model.UserModel(
      id: user.id,
      name: user.name,
      joinDate: user.joinDate,
      currency: user.currency,
      onboardingComplete: user.onboardingComplete,
      wakeTime: user.wakeTime,
      focusAreas: user.focusAreas,
    );
    await _localRepo.saveUser(lm);

    final box = await _getAuthBox();
    final currentEmail = box.get('current_user_email') as String?;
    if (currentEmail != null) {
      final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
      final userData = usersMap[currentEmail];
      if (userData != null) {
        userData['name'] = user.name;
        userData['currency'] = user.currency;
        userData['onboardingComplete'] = user.onboardingComplete;
        userData['wakeTime'] = user.wakeTime;
        userData['focusAreas'] = user.focusAreas;
        usersMap[currentEmail] = userData;
        await box.put('users', usersMap);
      }
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await saveUser(user);
  }

  @override
  Future<bool> hasUser() async {
    final u = await getCurrentUser();
    return u != null;
  }

  @override
  Future<String> signInAnonymously() async {
    final box = await _getAuthBox();
    final uid = IdGenerator.generate();
    final email = 'anonymous@jarvis.local';
    
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    usersMap[email] = {
      'id': uid,
      'name': 'Jarvis Explorer',
      'joinDate': DateTime.now().toIso8601String(),
      'currency': '₹',
      'onboardingComplete': false,
      'focusAreas': <String>[],
      'wakeTime': '07:00'
    };
    
    await box.put('users', usersMap);
    await box.put('current_user_email', email);
    
    _authStateController.add(uid);
    return uid;
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final box = await _getAuthBox();
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    final normalizedEmail = email.trim().toLowerCase();
    
    if (usersMap.containsKey(normalizedEmail)) {
      throw Exception('Email already exists. Please login.');
    }
    
    final uid = IdGenerator.generate();
    final newUser = {
      'id': uid,
      'name': name,
      'password': password,
      'joinDate': DateTime.now().toIso8601String(),
      'currency': '₹',
      'onboardingComplete': false,
      'focusAreas': <String>[],
      'wakeTime': '07:00'
    };
    
    usersMap[normalizedEmail] = newUser;
    await box.put('users', usersMap);
    await box.put('current_user_email', normalizedEmail);
    await box.put('is_verified', false);
    
    final userModel = UserModel(
      id: uid,
      name: name,
      joinDate: DateTime.now(),
      currency: '₹',
      onboardingComplete: false,
      focusAreas: const [],
    );
    await _localRepo.saveUser(local_model.UserModel(
      id: uid,
      name: name,
      joinDate: DateTime.now(),
      currency: '₹',
      onboardingComplete: false,
      focusAreas: const [],
    ));

    _authStateController.add(uid);
    return userModel;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final box = await _getAuthBox();
    final cleanedEmail = email.trim().toLowerCase();
    
    final lockoutUntil = box.get('lockout_until') as int?;
    if (lockoutUntil != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now < lockoutUntil) {
        throw Exception('Account locked. Try again later.');
      } else {
        await box.delete('lockout_until');
        await box.put('failed_attempts', 0);
      }
    }
    
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    
    if (usersMap.isEmpty && cleanedEmail == 'test@example.com') {
      usersMap[cleanedEmail] = {
        'id': 'test_user_id',
        'name': 'Jarvis User',
        'password': 'Password123!',
        'joinDate': DateTime.now().toIso8601String(),
        'currency': '₹',
        'onboardingComplete': true,
        'focusAreas': ['tasks', 'habits', 'money', 'journaling'],
        'wakeTime': '07:00'
      };
      await box.put('users', usersMap);
    }
    
    if (!usersMap.containsKey(cleanedEmail)) {
      throw Exception('User not found.');
    }
    
    final userData = usersMap[cleanedEmail];
    final correctPassword = userData['password'] as String?;
    
    if (correctPassword != password) {
      final currentAttempts = (box.get('failed_attempts') as int? ?? 0) + 1;
      await box.put('failed_attempts', currentAttempts);
      
      if (currentAttempts >= 5) {
        final lockDuration = 15 * 60 * 1000;
        final lockUntil = DateTime.now().millisecondsSinceEpoch + lockDuration;
        await box.put('lockout_until', lockUntil);
        throw Exception('Too many attempts. Account locked for 15 minutes.');
      }
      
      throw Exception('Wrong password. Attempts left: ${5 - currentAttempts}');
    }
    
    await box.put('failed_attempts', 0);
    await box.put('current_user_email', cleanedEmail);
    await box.put('is_verified', true);
    
    final userModel = UserModel(
      id: userData['id'] as String,
      name: userData['name'] as String,
      joinDate: DateTime.parse(userData['joinDate'] as String),
      currency: userData['currency'] as String? ?? '₹',
      onboardingComplete: userData['onboardingComplete'] as bool? ?? false,
      wakeTime: userData['wakeTime'] as String?,
      focusAreas: List<String>.from(userData['focusAreas'] ?? []),
    );
    
    await _localRepo.saveUser(local_model.UserModel(
      id: userModel.id,
      name: userModel.name,
      joinDate: userModel.joinDate,
      currency: userModel.currency,
      onboardingComplete: userModel.onboardingComplete,
      wakeTime: userModel.wakeTime,
      focusAreas: userModel.focusAreas,
    ));
    
    _authStateController.add(userModel.id);
    return userModel;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final box = await _getAuthBox();
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    if (!usersMap.containsKey(email.trim().toLowerCase())) {
      throw Exception('Account not found.');
    }
    await box.put('reset_token', 'mock_token_123456');
    await box.put('reset_email', email.trim().toLowerCase());
  }

  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final box = await _getAuthBox();
    final savedToken = box.get('reset_token') as String?;
    final resetEmail = box.get('reset_email') as String?;
    
    if (savedToken == null || resetEmail == null) {
      throw Exception('Invalid reset link or expired token.');
    }
    
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    final userData = usersMap[resetEmail];
    if (userData != null) {
      userData['password'] = newPassword;
      usersMap[resetEmail] = userData;
      await box.put('users', usersMap);
      await box.delete('reset_token');
      await box.delete('reset_email');
    } else {
      throw Exception('User not found.');
    }
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (code != '123456' && code != '1234') {
      throw Exception('Invalid verification code.');
    }
    final box = await _getAuthBox();
    await box.put('is_verified', true);
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final box = await _getAuthBox();
    final email = 'google.user@gmail.com';
    final uid = 'google_user_id';
    
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    if (!usersMap.containsKey(email)) {
      usersMap[email] = {
        'id': uid,
        'name': 'Google User',
        'joinDate': DateTime.now().toIso8601String(),
        'currency': '₹',
        'onboardingComplete': false,
        'focusAreas': <String>[],
        'wakeTime': '07:00'
      };
      await box.put('users', usersMap);
    }
    
    final userData = usersMap[email];
    await box.put('current_user_email', email);
    await box.put('is_verified', true);
    
    final user = UserModel(
      id: userData['id'] as String,
      name: userData['name'] as String,
      joinDate: DateTime.parse(userData['joinDate'] as String),
      currency: userData['currency'] as String? ?? '₹',
      onboardingComplete: userData['onboardingComplete'] as bool? ?? false,
      wakeTime: userData['wakeTime'] as String?,
      focusAreas: List<String>.from(userData['focusAreas'] ?? []),
    );
    
    _authStateController.add(user.id);
    return user;
  }

  @override
  Future<UserModel> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final box = await _getAuthBox();
    final email = 'apple.user@icloud.com';
    final uid = 'apple_user_id';
    
    final usersMap = Map<String, dynamic>.from(box.get('users', defaultValue: {}));
    if (!usersMap.containsKey(email)) {
      usersMap[email] = {
        'id': uid,
        'name': 'Apple User',
        'joinDate': DateTime.now().toIso8601String(),
        'currency': '₹',
        'onboardingComplete': false,
        'focusAreas': <String>[],
        'wakeTime': '07:00'
      };
      await box.put('users', usersMap);
    }
    
    final userData = usersMap[email];
    await box.put('current_user_email', email);
    await box.put('is_verified', true);
    
    final user = UserModel(
      id: userData['id'] as String,
      name: userData['name'] as String,
      joinDate: DateTime.parse(userData['joinDate'] as String),
      currency: userData['currency'] as String? ?? '₹',
      onboardingComplete: userData['onboardingComplete'] as bool? ?? false,
      wakeTime: userData['wakeTime'] as String?,
      focusAreas: List<String>.from(userData['focusAreas'] ?? []),
    );
    
    _authStateController.add(user.id);
    return user;
  }

  @override
  Future<void> enableBiometrics(bool enable) async {
    final box = await _getAuthBox();
    await box.put('biometric_enabled', enable);
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    final box = await _getAuthBox();
    return box.get('biometric_enabled', defaultValue: false) as bool;
  }

  @override
  Future<UserModel?> authenticateWithBiometrics() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final isEnabled = await isBiometricsEnabled();
    if (!isEnabled) {
      throw Exception('Biometrics not enabled on this device.');
    }
    
    final user = await getCurrentUser();
    if (user != null) {
      _authStateController.add(user.id);
      return user;
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    final box = await _getAuthBox();
    await box.delete('current_user_email');
    await box.delete('is_verified');
    await _localRepo.deleteUser();
    _authStateController.add(null);
  }
}
