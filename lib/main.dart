import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_controller.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'firebase_options.dart';
import 'ui/screens/add_entry_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/leaderboard_screen.dart';
import 'ui/screens/profile_screen.dart';
import 'ui/screens/root_shell_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const ProviderScope(child: CountSipApp()));
}

class CountSipApp extends ConsumerWidget {
  const CountSipApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'CountSip',
      theme: AppTheme.light,
      routerConfig: _router(ref),
    );
  }

  GoRouter _router(WidgetRef ref) {
    return GoRouter(
      initialLocation: '/login',
      redirect: (context, state) {
        final authState = ref.read(authControllerProvider);
        final isAuthenticated = authState.value != null;
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        // Debug print
        // ignore: avoid_print
        print('Redirect check: auth=${authState.value != null}, loc=${state.matchedLocation}');

        // If not authenticated and not on login/signup, redirect to login
        if (!isAuthenticated && !isLoggingIn) {
          // ignore: avoid_print
          print('Redirecting to /login');
          return '/login';
        }

        // If authenticated and on login/signup, redirect to home
        if (isAuthenticated && isLoggingIn) {
          // ignore: avoid_print
          print('Redirecting to /home');
          return '/home';
        }

        // No redirect needed
        return null;
      },
      refreshListenable: _GoRouterRefreshStream(
        ref.watch(authControllerProvider.future),
      ),
      routes: [
        // Auth routes
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        
        // App routes with bottom navigation
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
}

/// Helper class to refresh GoRouter when auth state changes
class _GoRouterRefreshStream extends ChangeNotifier {
  _GoRouterRefreshStream(Future<void> future) {
    future.then((_) => notifyListeners());
  }
}
