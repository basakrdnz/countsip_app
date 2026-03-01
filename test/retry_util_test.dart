import 'package:flutter_test/flutter_test.dart';
import 'package:countsip_app/core/utils/retry_util.dart';
import 'package:countsip_app/core/errors/app_exception.dart';

void main() {
  group('RetryUtil.run', () {
    test('returns value on first success', () async {
      int calls = 0;
      final result = await RetryUtil.run(() async {
        calls++;
        return 42;
      });
      expect(result, 42);
      expect(calls, 1);
    });

    test('retries on failure and succeeds on third attempt', () async {
      int calls = 0;
      final result = await RetryUtil.run<int>(
        () async {
          calls++;
          if (calls < 3) throw const NetworkException('transient');
          return 99;
        },
        maxAttempts: 3,
        initialDelay: Duration.zero,
        retryIf: (e) => e is NetworkException,
      );
      expect(result, 99);
      expect(calls, 3);
    });

    test('rethrows after maxAttempts exhausted', () async {
      int calls = 0;
      await expectLater(
        RetryUtil.run<int>(
          () async {
            calls++;
            throw const NetworkException('always fails');
          },
          maxAttempts: 2,
          initialDelay: Duration.zero,
          retryIf: (e) => e is NetworkException,
        ),
        throwsA(isA<NetworkException>()),
      );
      expect(calls, 2);
    });

    test('does not retry when retryIf returns false', () async {
      int calls = 0;
      await expectLater(
        RetryUtil.run<int>(
          () async {
            calls++;
            throw const AuthException('non-retryable');
          },
          maxAttempts: 3,
          initialDelay: Duration.zero,
          retryIf: (e) => e is NetworkException,
        ),
        throwsA(isA<AuthException>()),
      );
      expect(calls, 1);
    });

    test('retries all exceptions when retryIf is null', () async {
      int calls = 0;
      final result = await RetryUtil.run<int>(
        () async {
          calls++;
          if (calls < 2) throw Exception('any error');
          return 7;
        },
        maxAttempts: 3,
        initialDelay: Duration.zero,
      );
      expect(result, 7);
      expect(calls, 2);
    });
  });

  group('RetryUtil.runOnNetwork', () {
    test('retries NetworkException and succeeds', () async {
      int calls = 0;
      final result = await RetryUtil.runOnNetwork(
        () async {
          calls++;
          if (calls < 2) throw const NetworkException('down');
          return 'ok';
        },
        maxAttempts: 3,
      );
      expect(result, 'ok');
      expect(calls, 2);
    });

    test('does not retry non-NetworkException', () async {
      await expectLater(
        RetryUtil.runOnNetwork<void>(
          () async => throw const FirestoreException('write failed'),
          maxAttempts: 3,
        ),
        throwsA(isA<FirestoreException>()),
      );
    });
  });
}
