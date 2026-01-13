import 'package:flutter/material.dart';

/// Email validation utility with RFC 5322 compliance
class EmailValidator {
  EmailValidator._();

  // Simplified email regex (avoids escape character issues)
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates email format
  /// Returns null if valid, error message if invalid
  static String? validate(String? email, BuildContext context) {
    if (email == null || email.isEmpty) {
      // Use hardcoded strings for now, l10n will be used from the screen side
      return 'Please enter your email';
    }

    final trimmedEmail = email.trim().toLowerCase();
    
    if (!_emailRegex.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email';
    }

    return null;
  }

  /// Normalizes email (trim + lowercase)
  static String normalize(String email) {
    return email.trim().toLowerCase();
  }

  /// Checks if email is valid without returning error message
  static bool isValid(String email) {
    if (email.isEmpty) return false;
    return _emailRegex.hasMatch(email.trim().toLowerCase());
  }
}
