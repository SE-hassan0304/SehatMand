import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/screens/splash_screen.dart';
import '../../../features/auth/screens/auth_screen.dart';
import '../../../features/home/screens/home_screen.dart';
import '../../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isAuth = state.matchedLocation == AppRoutes.auth;
      final isAuthenticated = authState.isAuthenticated;

      if (isSplash) return null; // Let splash handle its own navigation

      if (!isAuthenticated && !isAuth) return AppRoutes.auth;
      if (isAuthenticated && isAuth) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

class AppRoutes {
  AppRoutes._();
  static const String splash = '/';
  static const String auth = '/auth';
  static const String home = '/home';
}
