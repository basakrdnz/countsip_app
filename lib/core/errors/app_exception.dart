/// Base exception class for app-specific errors
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, [this.code]);

  @override
  String toString() => code != null ? '[$code] $message' : message;
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

/// Validation-related exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, [super.code]);
}

/// Storage-related exceptions (Firebase Storage, local file ops)
class StorageException extends AppException {
  const StorageException(super.message, [super.code]);
}

/// Location/GPS-related exceptions
class LocationException extends AppException {
  const LocationException(super.message, [super.code]);
}

/// Permission-related exceptions
class PermissionException extends AppException {
  const PermissionException(super.message, [super.code]);
}

/// Thrown when a user profile is incomplete (missing required fields)
class ProfileIncompleteException extends AppException {
  const ProfileIncompleteException([String message = 'Profil bilgileri eksik'])
      : super(message, 'profile_incomplete');
}

/// Thrown when a requested resource does not exist
class NotFoundException extends AppException {
  const NotFoundException(super.message, [super.code]);
}
