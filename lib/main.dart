import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'ui/screens/add_entry_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/root_shell_page.dart';

/// Toggle emulator with a compile-time define:
/// flutter run --dart-define=USE_FIREBASE_EMULATOR=true
const bool _useEmulator =
    bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
const String _emulatorHost =
    String.fromEnvironment('FIREBASE_EMULATOR_HOST', defaultValue: 'localhost');
const int _firestoreEmulatorPort =
    int.fromEnvironment('FIREBASE_FIRESTORE_EMULATOR_PORT', defaultValue: 8080);
const int _authEmulatorPort =
    int.fromEnvironment('FIREBASE_AUTH_EMULATOR_PORT', defaultValue: 9099);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (_useEmulator) {
      await _configureFirebaseEmulator();
    }
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stackTrace');
    // Continue anyway - app might work without Firebase in some cases
  }
  
  runApp(ProviderScope(child: CountSipApp()));
}

class CountSipApp extends StatelessWidget {
  CountSipApp({super.key}) : _router = _createRouter();

  final GoRouter _router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CountSip',
      theme: AppTheme.light,
      routerConfig: _router,
    );
  }
}

Future<void> _configureFirebaseEmulator() async {
  await FirebaseAuth.instance.useAuthEmulator(
    _emulatorHost,
    _authEmulatorPort,
  );
  FirebaseFirestore.instance.useFirestoreEmulator(
    _emulatorHost,
    _firestoreEmulatorPort,
  );
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RootShellPage(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/add',
                name: 'add',
                builder: (context, state) => const AddEntryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                name: 'leaderboard',
                builder: (context, state) => const LeaderboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
