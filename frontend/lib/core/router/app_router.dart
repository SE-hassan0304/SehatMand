// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/auth/screens/splash_screen.dart';
import '../../../features/auth/screens/auth_screen.dart';
import '../../../features/home/screens/home_screen.dart';
import '../../../features/auth/providers/firebase_auth_stream_provider.dart';
import 'app_routes.dart';

export 'app_routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(firebaseAuthStreamProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isAuth = state.matchedLocation == AppRoutes.auth;

      if (authStream.isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      final isAuthenticated = authStream.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      if (isSplash) return null;
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
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );
});
