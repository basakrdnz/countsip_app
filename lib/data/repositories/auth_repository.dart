import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/errors/app_exception.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn? _googleSignIn;

  AuthRepository({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code), e.code);
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign up alias for compatibility
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) => signUpWithEmail(email: email, password: password);

  /// Sign in with email and password
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code), e.code);
    } catch (e) {
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign in alias for compatibility
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => signInWithEmail(email: email, password: password);

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    if (_googleSignIn == null) {
      throw const AuthException('Google Sign-In is not configured');
    }
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign in was cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code), e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      if (e.toString().contains('canceled') || 
          e.toString().contains('cancelled')) {
        throw const AuthException('Google sign in was cancelled');
      }
      throw AuthException('An unexpected error occurred: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        if (_googleSignIn != null) _googleSignIn.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Failed to sign out: ${e.toString()}');
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_getAuthErrorMessage(e.code), e.code);
    } catch (e) {
      throw AuthException('Failed to send password reset email: ${e.toString()}');
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'email-already-in-use':
        return 'Bu e-posta adresiyle zaten bir hesap mevcut.';
      case 'invalid-email':
        return 'E-posta adresi geçersiz.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı devre dışı bırakılmış.';
      case 'user-not-found':
        return 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda devre dışı.';
      case 'network-request-failed':
        return 'Ağ hatası. Lütfen internet bağlantınızı kontrol edin.';
      default:
        return 'Kimlik doğrulama hatası: $code';
    }
  }
}
