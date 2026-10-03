import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/features/auth/presentation/login_page.dart';
import 'package:hb_social/features/auth/presentation/signup_page.dart';
import 'package:hb_social/features/auth/presentation/welcome_page.dart';
import 'package:hb_social/features/home/presentation/home_feed_page.dart';
import 'package:hb_social/features/onboarding/presentation/onboarding_page.dart';
import 'package:hb_social/features/profile/presentation/profile_page.dart';
import 'package:hb_social/shell/app_shell.dart';

/// GoRouter configuration for HB Social.
///
/// Top-level routes (Welcome/Login/Signup/Onboarding) render without the
/// navigation shell. Home and Profile are nested inside a [ShellRoute] that
/// renders [AppShell], which owns the single Scaffold for the app.
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.welcome,
    routes: [
      GoRoute(path: AppRoutes.welcome, name: 'welcome', pageBuilder: (context, state) => NoTransitionPage(child: const WelcomePage())),
      GoRoute(path: AppRoutes.login, name: 'login', pageBuilder: (context, state) => NoTransitionPage(child: const LoginPage())),
      GoRoute(path: AppRoutes.signup, name: 'signup', pageBuilder: (context, state) => NoTransitionPage(child: const SignupPage())),
      GoRoute(path: AppRoutes.onboarding, name: 'onboarding', pageBuilder: (context, state) => NoTransitionPage(child: const OnboardingPage())),
      ShellRoute(
        builder: (context, state, child) => AppShell(currentPath: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AppRoutes.home, name: 'home', pageBuilder: (context, state) => NoTransitionPage(child: const HomeFeedPage())),
          GoRoute(path: AppRoutes.profile, name: 'profile', pageBuilder: (context, state) => NoTransitionPage(child: const ProfilePage())),
        ],
      ),
    ],
  );
}

/// Route path constants. Use these instead of hard-coding route strings.
class AppRoutes {
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String profile = '/profile';
}
