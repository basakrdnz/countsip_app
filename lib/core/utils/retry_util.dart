import 'dart:async';
import 'package:flutter/foundation.dart';
import '../errors/app_exception.dart';

/// Utility for retrying async operations with exponential backoff.
///
/// Usage:
/// ```dart
/// final result = await RetryUtil.run(
///   () => FirebaseFirestore.instance.collection('entries').get(),
///   maxAttempts: 3,
///   label: 'fetch entries',
/// );
/// ```
class RetryUtil {
  RetryUtil._();

  /// Runs [operation] up to [maxAttempts] times with exponential backoff.
  ///
  /// The delay between attempts starts at [initialDelay] and doubles each
  /// time (capped at [maxDelay]). Throws the last exception if all attempts fail.
  ///
  /// Set [retryIf] to limit retries to specific exception types.
  static Future<T> run<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 2),
    Duration maxDelay = const Duration(seconds: 16),
    bool Function(Object error)? retryIf,
    String? label,
  }) async {
    Duration delay = initialDelay;
    Object? lastError;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;

        final shouldRetry = retryIf == null || retryIf(e);
        if (!shouldRetry || attempt == maxAttempts) rethrow;

        if (kDebugMode) {
          debugPrint(
            '[RetryUtil] ${label ?? 'operation'} failed (attempt $attempt/$maxAttempts): $e — retrying in ${delay.inSeconds}s',
          );
        }

        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(0, maxDelay.inMilliseconds),
        );
      }
    }

    // Unreachable, but satisfies the type checker
    throw lastError ?? const NetworkException('Bağlantı hatası', 'max_retries');
  }

  /// Convenience wrapper that retries only on [NetworkException].
  static Future<T> runOnNetwork<T>(
    Future<T> Function() operation, {
    int maxAttempts = 4,
    String? label,
  }) {
    return run(
      operation,
      maxAttempts: maxAttempts,
      retryIf: (e) => e is NetworkException,
      label: label,
    );
  }
}
