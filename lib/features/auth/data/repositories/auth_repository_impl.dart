import 'package:jarvis/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';
import 'package:jarvis/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Stream<String?> get authStateChanges => _remoteDataSource.authStateChanges;

  @override
  Future<UserModel?> getCurrentUser() async {
    final uid = _remoteDataSource.currentUid;
    if (uid == null) return null;
    return await _remoteDataSource.getUserProfile(uid);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    await _remoteDataSource.saveUserProfile(user);
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _remoteDataSource.saveUserProfile(user);
  }

  @override
  Future<bool> hasUser() async {
    final uid = _remoteDataSource.currentUid;
    if (uid == null) return false;
    return await _remoteDataSource.hasUserProfile(uid);
  }

  @override
  Future<String> signInAnonymously() async {
    return await _remoteDataSource.signInAnonymously();
  }

  // Modern Auth operations stubs for Firebase path
  @override
  Future<UserModel> signUpWithEmailAndPassword(String name, String email, String password) async {
    throw UnimplementedError('Firebase Auth signUp not fully configured');
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(String email, String password) async {
    throw UnimplementedError('Firebase Auth signIn not fully configured');
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    throw UnimplementedError('Firebase Auth sendPasswordResetEmail not configured');
  }

  @override
  Future<void> confirmPasswordReset(String token, String newPassword) async {
    throw UnimplementedError('Firebase Auth confirmPasswordReset not configured');
  }

  @override
  Future<void> verifyEmail(String email, String code) async {
    throw UnimplementedError('Firebase Auth verifyEmail not configured');
  }

  @override
  Future<UserModel> signInWithGoogle() async {
    throw UnimplementedError('Firebase Auth signInWithGoogle not configured');
  }

  @override
  Future<UserModel> signInWithApple() async {
    throw UnimplementedError('Firebase Auth signInWithApple not configured');
  }

  @override
  Future<void> enableBiometrics(bool enable) async {
    // Local device feature, no-op in remote db
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    return false;
  }

  @override
  Future<UserModel?> authenticateWithBiometrics() async {
    return null;
  }

  @override
  Future<void> signOut() async {
    // Sign out from firebase if needed
  }
}
