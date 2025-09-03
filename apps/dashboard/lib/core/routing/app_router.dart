import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_service.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/password_change_page.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/instructor/instructor_dashboard.dart';
import '../../features/invitations/presentation/pages/invitations_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final user = AuthService.getCurrentUser();
      final isLoggedIn = user != null;
      final currentLocation = state.uri.toString();
      final isLoggingIn = currentLocation == '/login';

      // If not logged in, redirect to login
      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      // If logged in and on login page, redirect to appropriate dashboard
      if (isLoggedIn && isLoggingIn) {
        final role = await AuthService.getCurrentUserRole();
        switch (role) {
          case UserRole.admin:
            return '/admin';
          case UserRole.instructor:
            return '/instructor';
          case UserRole.student:
            return '/student';
          default:
            return '/login';
        }
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/change-password',
        builder: (context, state) => const PasswordChangePage(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboard(),
        routes: [
          GoRoute(
            path: 'invitations',
            builder: (context, state) => const InvitationsPage(),
          ),
        ],
      ),

      // Instructor routes
      GoRoute(
        path: '/instructor',
        builder: (context, state) => const InstructorDashboard(),
        routes: [
          GoRoute(
            path: 'profile',
            builder: (context, state) => const PasswordChangePage(),
          ),
        ],
      ),

      // Student routes (future)
      GoRoute(
        path: '/student',
        builder:
            (context, state) => const Scaffold(
              body: Center(child: Text('Student Dashboard - Coming Soon')),
            ),
      ),

      // Legacy redirect for backward compatibility
      GoRoute(
        path: '/dashboard',
        redirect: (context, state) async {
          final role = await AuthService.getCurrentUserRole();
          switch (role) {
            case UserRole.admin:
              return '/admin';
            case UserRole.instructor:
              return '/instructor';
            case UserRole.student:
              return '/student';
            default:
              return '/login';
          }
        },
      ),
    ],
  );
}
