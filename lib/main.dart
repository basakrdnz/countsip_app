import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/profile_setup_screen.dart';
import 'features/auth/screens/phone_login_screen.dart';
import 'features/auth/screens/phone_signup_screen.dart';
import 'features/auth/screens/phone_forgot_password_screen.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/screens/add_entry_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/profile_details_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/root_shell_page.dart';
import 'ui/screens/friends_screen.dart';
import 'ui/screens/add_friend_screen.dart';
import 'ui/screens/blocked_users_screen.dart';
import 'ui/screens/notifications_screen.dart';
import 'ui/screens/feed_screen.dart';
import 'ui/screens/badges_screen.dart';
import 'ui/screens/location_picker_screen.dart';
import 'ui/screens/bac_stats_screen.dart';
import 'core/services/preferences_service.dart';

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
  
  // Initialize date formatting for supported locales
  await initializeDateFormatting('tr', null);
  await initializeDateFormatting('en', null);
  await PreferencesService.init();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };

  // Handle async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
    }
    return true;
  };
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (_useEmulator) {
      await _configureFirebaseEmulator();
    }

    // Enable App Check to protect backend resources from abuse
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
    );
  } catch (e, stackTrace) {
    if (kDebugMode) {
      debugPrint('Firebase initialization error: $e');
      debugPrint('Stack trace: $stackTrace');
    }
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
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('tr'),
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (final supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return const Locale('en');
      },
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
    
    redirect: (context, state) async {
      final user = FirebaseAuth.instance.currentUser;
      final isLoggedIn = user != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isForgotPw = state.matchedLocation == '/forgot-password';
      final isSplash = state.matchedLocation == '/splash';
      final isProfileSetup = state.matchedLocation == '/profile-setup';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (isSplash) return null;

      if (!isLoggedIn) {
        if (isLoggingIn || isSigningUp || isForgotPw || isOnboarding) {
          return null;
        }
        return '/onboarding';
      }

      // User is logged in
      if (isLoggedIn) {
        // Always allow /profile-setup
        if (isProfileSetup) {
          return null;
        }
        
        // SAFETY CHECK: On every navigation from auth screens OR to home,
        // verify user has name and username - catch any incomplete profiles
        if (isLoggingIn || isSigningUp || state.matchedLocation == '/home' || state.matchedLocation == '/') {
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            // Check if essential fields are missing
            final data = doc.data();
            final hasName = data != null &&
                data['name'] != null &&
                (data['name'] as String).trim().isNotEmpty;
            final hasUsername = data != null &&
                data['username'] != null &&
                (data['username'] as String).trim().isNotEmpty;

            if (!doc.exists || !hasName || !hasUsername) {
              // Missing essential info - go to profile setup
              return '/profile-setup';
            }
          } catch (e) {
            debugPrint('Profile check error: $e');
            // Only redirect to profile-setup from auth screens.
            // If already on /home, allow through to avoid redirect loop
            // caused by Firestore permission errors.
            if (isLoggingIn || isSigningUp) {
              return '/profile-setup';
            }
            // For /home navigation with errors, allow through -
            // the screen itself will handle showing error states
            return null;
          }

          // Profile complete - allow to home
          if (isLoggingIn || isSigningUp) {
            return '/home';
          }
        }
      }

      return null;
    },
    
    routes: [
      // Root route - redirect to home
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        pageBuilder: (context, state) {
          final pageStr = state.uri.queryParameters['page'];
          final initialPage = int.tryParse(pageStr ?? '0') ?? 0;
          return CustomTransitionPage(
            key: state.pageKey,
            child: OnboardingScreen(initialPage: initialPage),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutExpo)),
                ),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneLoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutExpo)),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneSignupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutExpo)),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PhoneForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutExpo)),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/profile-details',
        name: 'profile-details',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ProfileDetailsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/friends',
        name: 'friends',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const FriendsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/add-friend',
        name: 'add-friend',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: AddFriendScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/blocked-users',
        name: 'blocked-users',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BlockedUsersScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/badges',
        name: 'badges',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const BadgesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(1, 0), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: FadeTransition(opacity: animation, child: child),
            );
          },
        ),
      ),
      GoRoute(
        path: '/location-picker',
        name: 'location-picker',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LocationPickerScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 1), end: Offset.zero).chain(CurveTween(curve: Curves.easeOutCubic)),
              ),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/bac-stats',
        name: 'bac-stats',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CustomTransitionPage(
            key: state.pageKey,
            child: BacStatsScreen(
              currentBac: extra?['currentBac'],
              weightKg: (extra?['weightKg'] as num?)?.toDouble(),
              heightCm: (extra?['heightCm'] as num?)?.toDouble(),
              age: extra?['age'] as int?,
              gender: extra?['gender'] as String?,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: animation.drive(
                  Tween(begin: const Offset(0, 1), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
          );
        },
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
                path: '/feed',
                name: 'feed',
                builder: (context, state) => const FeedScreen(),
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
