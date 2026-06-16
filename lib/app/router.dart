import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/providers/auth_provider.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/data/models/user_model.dart';

// Import Dashboard Screens
import '../features/employee/presentation/screens/employee_dashboard_screen.dart';
import '../features/employer/presentation/screens/employer_dashboard_screen.dart';
import '../features/admin/presentation/screens/admin_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/employee',
        builder: (context, state) => const EmployeeDashboardScreen(),
      ),
      GoRoute(
        path: '/employer',
        builder: (context, state) => const EmployerDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    redirect: (context, state) {
      final isInitialised = authState.isInitialised;
      final isAuthenticated = authState.isAuthenticated;

      // If not yet initialised, stay on splash screen
      if (!isInitialised) return null;

      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/';

      if (!isAuthenticated) {
        // Not authenticated, redirect to login if not already there
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // Authenticated, redirect based on user role
      if (isLoggingIn || isSplash) {
        final role = authState.userModel?.role;
        switch (role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.employer:
            return '/employer';
          case UserRole.employee:
          default:
            return '/employee';
        }
      }

      // No redirect needed if already in correct area
      return null;
    },
  );
});
