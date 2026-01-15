/// Base exception class for app-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => message;
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(super.message, [super.code]);
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException(super.message, [super.code]);
}

/// Firestore-related exceptions
class FirestoreException extends AppException {
  const FirestoreException(super.message, [super.code]);
}
