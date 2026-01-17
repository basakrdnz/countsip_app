import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/auth_repository.dart';
import 'auth_provider.dart';

/// Phone verification state
class PhoneVerificationState {
  final String? verificationId;
  final int? resendToken;
  final bool isVerifying;
  final String? error;
  
  const PhoneVerificationState({
    this.verificationId,
    this.resendToken,
    this.isVerifying = false,
    this.error,
  });
  
  PhoneVerificationState copyWith({
    String? verificationId,
    int? resendToken,
    bool? isVerifying,
    String? error,
  }) {
    return PhoneVerificationState(
      verificationId: verificationId ?? this.verificationId,
      resendToken: resendToken ?? this.resendToken,
      isVerifying: isVerifying ?? this.isVerifying,
      error: error,
    );
  }
}

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

  // ============================================
  // PHONE VERIFICATION
  // ============================================

  /// Sends SMS verification code to phone number
  Future<PhoneVerificationState> sendVerificationCode(String phoneNumber) async {
    final completer = Completer<PhoneVerificationState>();
    
    await _repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId, resendToken) {
        completer.complete(PhoneVerificationState(
          verificationId: verificationId,
          resendToken: resendToken,
          isVerifying: false,
        ));
      },
      onVerificationCompleted: (credential) {
        // Auto-verification on some Android devices
        // We'll handle this in the UI
      },
      onVerificationFailed: (error) {
        completer.complete(PhoneVerificationState(
          isVerifying: false,
          error: _getErrorMessage(error),
        ));
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        // Timeout - user needs to enter code manually
      },
    );
    
    return completer.future;
  }

  /// Resend verification code
  Future<PhoneVerificationState> resendVerificationCode(
    String phoneNumber,
    int? resendToken,
  ) async {
    final completer = Completer<PhoneVerificationState>();
    
    await _repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      resendToken: resendToken,
      onCodeSent: (verificationId, newResendToken) {
        completer.complete(PhoneVerificationState(
          verificationId: verificationId,
          resendToken: newResendToken,
          isVerifying: false,
        ));
      },
      onVerificationCompleted: (credential) {},
      onVerificationFailed: (error) {
        completer.complete(PhoneVerificationState(
          isVerifying: false,
          error: _getErrorMessage(error),
        ));
      },
      onCodeAutoRetrievalTimeout: (verificationId) {},
    );
    
    return completer.future;
  }

  /// Verifies SMS code
  PhoneAuthCredential verifyCode(String verificationId, String smsCode) {
    return _repository.verifySmsCode(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  // ============================================
  // PHONE + PASSWORD AUTH
  // ============================================

  /// Check if phone number is already registered
  Future<bool> isPhoneRegistered(String phoneNumber) async {
    return await _repository.isPhoneNumberRegistered(phoneNumber);
  }

  /// Sign up with phone and password
  Future<void> signUpWithPhone({
    required String phoneNumber,
    required String password,
    required PhoneAuthCredential phoneCredential,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createUserWithPhone(
        phoneNumber: phoneNumber,
        password: password,
        phoneCredential: phoneCredential,
      );
      return _repository.currentUser;
    });
  }

  /// Sign in with phone and password
  Future<void> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.signInWithPhone(
        phoneNumber: phoneNumber,
        password: password,
      );
      return _repository.currentUser;
    });
  }

  /// Reset password with phone verification
  Future<void> resetPasswordWithPhone({
    required String phoneNumber,
    required String newPassword,
    required PhoneAuthCredential phoneCredential,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.resetPasswordWithPhone(
        phoneNumber: phoneNumber,
        newPassword: newPassword,
        phoneCredential: phoneCredential,
      );
      return _repository.currentUser;
    });
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    await _repository.signOut();
    state = const AsyncValue.data(null);
  }

  // ============================================
  // HELPERS
  // ============================================

  String _getErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Geçersiz telefon numarası';
      case 'too-many-requests':
        return 'Çok fazla deneme. Lütfen bekleyin.';
      case 'quota-exceeded':
        return 'SMS limiti aşıldı. Daha sonra tekrar deneyin.';
      case 'invalid-verification-code':
        return 'Geçersiz doğrulama kodu';
      case 'session-expired':
        return 'Oturum süresi doldu. Tekrar deneyin.';
      default:
        return error.message ?? 'Bir hata oluştu';
    }
  }

  // ============================================
  // DEPRECATED - Kept for compatibility
  // ============================================

  @Deprecated('Use signInWithPhone instead')
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // ignore: deprecated_member_use
      await _repository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _repository.currentUser;
    });
  }

  @Deprecated('Use signUpWithPhone instead')
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // ignore: deprecated_member_use
      await _repository.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _repository.currentUser;
    });
  }

  @Deprecated('Use resetPasswordWithPhone instead')
  Future<void> sendPasswordResetEmail(String email) async {
    // ignore: deprecated_member_use
    await _repository.sendPasswordResetEmail(email);
  }

  @Deprecated('Google Sign-In removed')
  Future<void> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In kaldırıldı');
  }
}

/// Completer for async operations
class Completer<T> {
  final _completer = _InternalCompleter<T>();
  
  Future<T> get future => _completer.future;
  
  void complete(T value) => _completer.complete(value);
}

class _InternalCompleter<T> {
  T? _value;
  bool _isCompleted = false;
  final List<void Function(T)> _callbacks = [];
  
  Future<T> get future {
    if (_isCompleted) {
      return Future.value(_value as T);
    }
    return Future(() async {
      while (!_isCompleted) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _value as T;
    });
  }
  
  void complete(T value) {
    _value = value;
    _isCompleted = true;
    for (final callback in _callbacks) {
      callback(value);
    }
  }
}

/// Provider for AuthController
final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  () => AuthController(),
);
