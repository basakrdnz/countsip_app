import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
        debugPrint('FirebaseAuth verifyPhoneNumber: code sent');
        completer.complete(PhoneVerificationState(
          verificationId: verificationId,
          resendToken: resendToken,
          isVerifying: false,
        ));
      },
      onVerificationCompleted: (credential) {
        debugPrint('FirebaseAuth verifyPhoneNumber: auto-verification completed');
        // Auto-verification on some Android devices
        // We'll handle this in the UI
      },
      onVerificationFailed: (error) {
        debugPrint('FirebaseAuth verifyPhoneNumber failed: [${error.code}]');
        completer.complete(PhoneVerificationState(
          isVerifying: false,
          error: _getErrorMessage(error),
        ));
      },
      onCodeAutoRetrievalTimeout: (verificationId) {
        debugPrint('FirebaseAuth verifyPhoneNumber: auto-retrieval timeout');
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

    if (state.hasError) {
      throw state.error!;
    }
  }

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

    if (state.hasError) {
      throw state.error!;
    }
  }

  /// [DEV ONLY] Sign up bypass code
  Future<void> signUpWithPhoneDevBypass({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _repository.createUserWithPhoneDevBypass(
        phoneNumber: phoneNumber,
        password: password,
      );
      return _repository.currentUser;
    });

    if (state.hasError) {
      throw state.error!;
    }
  }

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

    if (state.hasError) {
      throw state.error!;
    }
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
}

/// Provider for AuthController
final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  () => AuthController(),
);
