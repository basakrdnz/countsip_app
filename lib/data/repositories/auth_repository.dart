import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ============================================
  // PHONE VERIFICATION
  // ============================================

  /// Starts phone verification process
  /// Returns the verificationId through the callback
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(PhoneAuthCredential credential) onVerificationCompleted,
    required void Function(FirebaseAuthException error) onVerificationFailed,
    required void Function(String verificationId) onCodeAutoRetrievalTimeout,
    int? resendToken,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: resendToken,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
    );
  }

  /// Verifies SMS code and returns PhoneAuthCredential
  PhoneAuthCredential verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) {
    return PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
  }

  // ============================================
  // PHONE + PASSWORD AUTH
  // ============================================

  /// Creates a new user with phone number and password
  /// Uses a synthetic email: {phoneHash}@countsip.app
  Future<UserCredential> createUserWithPhone({
    required String phoneNumber,
    required String password,
    required PhoneAuthCredential phoneCredential,
  }) async {
    // First, sign in with phone to verify it
    final phoneUserCredential = await _auth.signInWithCredential(phoneCredential);
    
    // Generate synthetic email from phone number
    final syntheticEmail = _generateSyntheticEmail(phoneNumber);
    
    // Create email/password credential and link it
    final emailCredential = EmailAuthProvider.credential(
      email: syntheticEmail,
      password: password,
    );
    
    // Link email/password to the phone account
    final linkedCredential = await phoneUserCredential.user!.linkWithCredential(emailCredential);
    
    // Store phone number hash for uniqueness check
    await _storePhoneNumber(phoneNumber, linkedCredential.user!.uid);
    
    return linkedCredential;
  }

  /// [DEV ONLY] Creates a user without phone verification for testing.
  /// Throws [UnsupportedError] in release builds.
  Future<UserCredential> createUserWithPhoneDevBypass({
    required String phoneNumber,
    required String password,
  }) async {
    if (!kDebugMode) {
      throw UnsupportedError('Dev bypass is not available in release builds.');
    }
    final syntheticEmail = _generateSyntheticEmail(phoneNumber);
    
    // Create email account directly
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: syntheticEmail,
      password: password,
    );
    
    // Store phone number hash for uniqueness check
    await _storePhoneNumber(phoneNumber, userCredential.user!.uid);
    
    return userCredential;
  }

  /// Signs in with phone number and password
  Future<UserCredential> signInWithPhone({
    required String phoneNumber,
    required String password,
  }) async {
    final syntheticEmail = _generateSyntheticEmail(phoneNumber);
    return await _auth.signInWithEmailAndPassword(
      email: syntheticEmail,
      password: password,
    );
  }

  /// Resets password using phone verification
  Future<void> resetPasswordWithPhone({
    required String phoneNumber,
    required String newPassword,
    required PhoneAuthCredential phoneCredential,
  }) async {
    // Sign in with phone credential
    final userCredential = await _auth.signInWithCredential(phoneCredential);
    
    // Update password
    await userCredential.user!.updatePassword(newPassword);
  }

  // ============================================
  // PHONE NUMBER UNIQUENESS
  // ============================================

  /// Checks if phone number is already registered
  Future<bool> isPhoneNumberRegistered(String phoneNumber) async {
    final hash = _hashPhoneNumber(phoneNumber);
    final doc = await _firestore.collection('phoneNumbers').doc(hash).get();
    return doc.exists;
  }

  /// Stores phone number hash for uniqueness
  Future<void> _storePhoneNumber(String phoneNumber, String uid) async {
    final hash = _hashPhoneNumber(phoneNumber);
    await _firestore.collection('phoneNumbers').doc(hash).set({
      'uid': uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also store in user document (encrypted/hashed for privacy)
    // Use set with merge to avoid errors when user document doesn't exist yet
    await _firestore.collection('users').doc(uid).set({
      'phoneHash': hash,
      'phoneLastDigits': phoneNumber.substring(phoneNumber.length - 4),
    }, SetOptions(merge: true));
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Generates synthetic email from phone number
  /// Format: {hash}@countsip.app
  String _generateSyntheticEmail(String phoneNumber) {
    final hash = _hashPhoneNumber(phoneNumber);
    return '$hash@countsip.app';
  }

  /// Hashes phone number for storage/lookup
  String _hashPhoneNumber(String phoneNumber) {
    // Normalize phone number (remove spaces, dashes)
    final normalized = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final bytes = utf8.encode(normalized);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 32); // First 32 chars
  }

  // ============================================
  // LEGACY METHODS (kept for compatibility)
  // ============================================

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Deprecated - use signInWithPhone instead
  @Deprecated('Use signInWithPhone instead')
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Deprecated - use createUserWithPhone instead
  @Deprecated('Use createUserWithPhone instead')
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Deprecated - use resetPasswordWithPhone instead
  @Deprecated('Use resetPasswordWithPhone instead')
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Google Sign-In - Removed (not needed with phone auth)
  Future<UserCredential?> signInWithGoogle() async {
    throw UnimplementedError('Google Sign-In kaldırıldı. Telefon ile giriş yapın.');
  }
}
