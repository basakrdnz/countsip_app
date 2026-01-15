import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart' hide ProfileScreen;
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/auth/screens/profile_setup_screen.dart';
import 'ui/screens/splash_screen.dart';
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
  }
  
  // Configure Firebase UI Auth providers
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
  ]);
  
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
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        FirebaseUILocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      locale: const Locale('tr', 'TR'),
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
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
    
    redirect: (context, state) {
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isWelcome = state.matchedLocation == '/welcome';
      final isForgotPw = state.matchedLocation == '/forgot-password';
      final isSplash = state.matchedLocation == '/splash';

      if (isSplash) return null;

      if (!isLoggedIn) {
        if (isLoggingIn || isSigningUp || isWelcome || isForgotPw) {
          return null;
        }
        return '/welcome';
      }

      if (isLoggedIn) {
        if (isLoggingIn || isSigningUp || isWelcome) {
          return '/home';
        }
      }

      return null;
    },
    
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => Stack(
          children: [
            // Background layer
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bgwglass.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),
            // Auth content with transparent background
            Theme(
              data: Theme.of(context).copyWith(
                scaffoldBackgroundColor: Colors.transparent,
              ),
              child: SignInScreen(
                providers: FirebaseUIAuth.providersFor(FirebaseAuth.instance.app),
                headerBuilder: (context, constraints, shrinkOffset) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_bar_rounded, size: 40, color: AppColors.primary),
                        const SizedBox(height: 4),
                        Text(
                          'CountSip',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Rosaline',
                            letterSpacing: -1,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                actions: [
                  AuthStateChangeAction<SignedIn>((context, state) {
                    context.go('/home');
                  }),
                  ForgotPasswordAction((context, email) {
                    final uri = Uri(
                      path: '/forgot-password',
                      queryParameters: {'email': email},
                    );
                    context.push(uri.toString());
                  }),
                ],
                footerBuilder: (context, action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () => context.go('/welcome'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Geri Dön'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => Stack(
          children: [
            // Background layer
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/bgwglass.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
            ),
            // Auth content with transparent background
            Theme(
              data: Theme.of(context).copyWith(
                scaffoldBackgroundColor: Colors.transparent,
              ),
              child: RegisterScreen(
                providers: FirebaseUIAuth.providersFor(FirebaseAuth.instance.app),
                headerBuilder: (context, constraints, shrinkOffset) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person_add_rounded, size: 40, color: AppColors.primary),
                        const SizedBox(height: 4),
                        Text(
                          'CountSip',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Rosaline',
                            letterSpacing: -1,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                actions: [
                  AuthStateChangeAction<UserCreated>((context, state) {
                    context.go('/profile-setup');
                  }),
                ],
                footerBuilder: (context, action) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextButton.icon(
                      onPressed: () => context.go('/welcome'),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Geri Dön'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return Stack(
            children: [
              // Background layer
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/bgwglass.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ),
              // Auth content with transparent background
              Theme(
                data: Theme.of(context).copyWith(
                  scaffoldBackgroundColor: Colors.transparent,
                ),
                child: ForgotPasswordScreen(
                  email: email,
                  headerBuilder: (context, constraints, shrinkOffset) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_reset_rounded, size: 40, color: AppColors.primary),
                          const SizedBox(height: 4),
                          Text(
                            'CountSip',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Rosaline',
                              letterSpacing: -1,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      
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

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
