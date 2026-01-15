import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import 'auth_provider.dart';

/// Auth controller for managing authentication state and actions
class AuthController extends AsyncNotifier<User?> {
  late final AuthRepository _repository;

  @override
  Future<User?> build() async {
    _repository = ref.read(authRepositoryProvider);
    
    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue) {
        state = AsyncValue.data(next.value);
      }
    });
    
    // Return current user immediately
    return _repository.currentUser;
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _repository.currentUser;
    });
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _repository.currentUser;
    });
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final credential = await _repository.signInWithGoogle();
      return credential?.user;
    });
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _repository.sendPasswordResetEmail(email);
  }
}

/// Provider for AuthController
final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  () => AuthController(),
);
