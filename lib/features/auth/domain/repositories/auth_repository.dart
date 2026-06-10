import 'package:jarvis/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Future<void> saveUser(UserModel user);
  Future<void> updateUser(UserModel user);
  Future<bool> hasUser();
  Future<String> signInAnonymously();
  Stream<String?> get authStateChanges;

  // Modern Authentication Operations
  Future<UserModel> signUpWithEmailAndPassword(String name, String email, String password);
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> confirmPasswordReset(String token, String newPassword);
  Future<void> verifyEmail(String email, String code);
  Future<UserModel> signInWithGoogle();
  Future<UserModel> signInWithApple();
  Future<void> enableBiometrics(bool enable);
  Future<bool> isBiometricsEnabled();
  Future<UserModel?> authenticateWithBiometrics();
  Future<void> signOut();
}
