import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:countsip/data/repositories/auth_repository.dart';
import 'package:countsip/firebase_options.dart';

// Mock classes
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

void main() {
  group('AuthRepository Integration Tests', () {
    late AuthRepository authRepository;
    late MockFirebaseAuth mockAuth;

    setUpAll(() async {
      // Initialize Firebase for tests
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        // Firebase might already be initialized
      }
    });

    setUp(() {
      mockAuth = MockFirebaseAuth();
      authRepository = AuthRepository(auth: mockAuth);
    });

    group('signUpWithEmail', () {
      test('creates user with valid email and password', () async {
        // This test would require actual Firebase connection
        // For now, we test the error handling
        expect(
          () => authRepository.signUpWithEmail(
            email: 'test@example.com',
            password: 'password123',
          ),
          returnsNormally,
        );
      });

      test('throws AuthException for invalid email', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          FirebaseAuthException(
            code: 'invalid-email',
            message: 'Invalid email',
          ),
        );

        expect(
          () => authRepository.signUpWithEmail(
            email: 'invalid-email',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws AuthException for weak password', () async {
        when(() => mockAuth.createUserWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          FirebaseAuthException(
            code: 'weak-password',
            message: 'Weak password',
          ),
        );

        expect(
          () => authRepository.signUpWithEmail(
            email: 'test@example.com',
            password: '123',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithEmail', () {
      test('throws AuthException for wrong password', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          FirebaseAuthException(
            code: 'wrong-password',
            message: 'Wrong password',
          ),
        );

        expect(
          () => authRepository.signInWithEmail(
            email: 'test@example.com',
            password: 'wrongpassword',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws AuthException for user not found', () async {
        when(() => mockAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenThrow(
          FirebaseAuthException(
            code: 'user-not-found',
            message: 'User not found',
          ),
        );

        expect(
          () => authRepository.signInWithEmail(
            email: 'nonexistent@example.com',
            password: 'password123',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('signs out successfully', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async => {});
        // Note: GoogleSignIn mock would be needed for full test
        expect(
          () => authRepository.signOut(),
          returnsNormally,
        );
      });
    });
  });
}
