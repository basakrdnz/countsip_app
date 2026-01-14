import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:countsip/features/auth/screens/login_screen.dart';
import 'package:countsip/features/auth/screens/signup_screen.dart';

void main() {
  group('Login Screen Form Validation', () {
    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Find and tap the login button
      final loginButton = find.text('Log In');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your email'), findsOneWidget);
    });

    testWidgets('shows error when email is invalid', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter invalid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');
      await tester.pump();

      // Tap login button
      final loginButton = find.text('Log In');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter a valid email'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Tap login button
      final loginButton = find.text('Log In');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('shows error when password is too short', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Enter short password
      final passwordField = find.byType(TextFormField).last;
      await tester.enterText(passwordField, '12345');
      await tester.pump();

      // Tap login button
      final loginButton = find.text('Log In');
      await tester.tap(loginButton);
      await tester.pump();

      // Should show validation error
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });

  group('Sign Up Screen Form Validation', () {
    testWidgets('shows error when passwords do not match', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SignUpScreen(),
          ),
        ),
      );

      // Enter valid email
      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'test@example.com');
      await tester.pump();

      // Enter password
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(1), 'password123');
      await tester.pump();

      // Enter different confirm password
      await tester.enterText(passwordFields.at(2), 'different123');
      await tester.pump();

      // Tap sign up button
      final signUpButton = find.text('Sign Up');
      await tester.tap(signUpButton);
      await tester.pump();

      // Should show validation error
      expect(find.text('Passwords do not match'), findsOneWidget);
    });
  });
}
