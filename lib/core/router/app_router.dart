import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whatif_milkyway_app/features/auth/presentation/screens/login_screen.dart';
import 'package:whatif_milkyway_app/features/home/presentation/screens/home_screen.dart';
import 'package:whatif_milkyway_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/screens/nickname_screen.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/screens/profile_image_screen.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/screens/book_intro_screen.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_search_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/onboarding/nickname',
      builder: (context, state) => const NicknameScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile-image',
      builder: (context, state) => const ProfileImageScreen(),
    ),
    GoRoute(
      path: '/onboarding/book-intro',
      builder: (context, state) => const BookIntroScreen(),
    ),
    GoRoute(
      path: '/books/search',
      builder: (context, state) => const BookSearchScreen(),
    ),
  ],
  observers: [RouteObserver<ModalRoute<void>>()],
);
