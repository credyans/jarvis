import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';
import 'package:jarvis/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:jarvis/features/auth/data/repositories/local_auth_repository.dart';
import 'package:jarvis/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:jarvis/features/auth/domain/repositories/auth_repository.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useFirebase) {
    return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
  } else if (AppConfig.useSupabase) {
    return SupabaseAuthRepository();
  } else {
    return LocalAuthRepository();
  }
});

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref.watch(authRepositoryProvider));
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadUser();
  }

  void _updateFormatter(UserModel? user) {
    CurrencyFormatter.currencySymbol = user?.currency ?? '₹';
  }

  Future<void> loadUser() async {
    try {
      final user = await _repository.getCurrentUser();
      _updateFormatter(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveUser(UserModel user) async {
    await _repository.saveUser(user);
    _updateFormatter(user);
    state = AsyncValue.data(user);
  }

  Future<void> updateUser(UserModel user) async {
    await _repository.updateUser(user);
    _updateFormatter(user);
    state = AsyncValue.data(user);
  }

  Future<bool> hasUser() async {
    return await _repository.hasUser();
  }

  Future<String> signInAnonymously() async {
    state = const AsyncValue.loading();
    try {
      final uid = await _repository.signInAnonymously();
      await loadUser();
      return uid;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signUpWithEmailAndPassword(name, email, password);
      _updateFormatter(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithEmailAndPassword(email, password);
      _updateFormatter(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithGoogle();
      _updateFormatter(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.signInWithApple();
      _updateFormatter(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> verifyEmail(String email, String code) async {
    state = const AsyncValue.loading();
    try {
      await _repository.verifyEmail(email, code);
      await loadUser();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repository.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> confirmPasswordReset(String token, String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _repository.confirmPasswordReset(token, newPassword);
      state = const AsyncValue<UserModel?>.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> enableBiometrics(bool enable) async {
    try {
      await _repository.enableBiometrics(enable);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isBiometricsEnabled() async {
    return await _repository.isBiometricsEnabled();
  }

  Future<void> signInWithBiometrics() async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.authenticateWithBiometrics();
      _updateFormatter(user);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      _updateFormatter(null);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
