import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:whatif_milkyway_app/features/auth/presentation/screens/login_screen.dart';
import 'package:whatif_milkyway_app/features/home/presentation/screens/home_screen.dart';
import 'package:whatif_milkyway_app/features/splash/presentation/screens/splash_screen.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/screens/nickname_screen.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/screens/profile_image_screen.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/screens/book_intro_screen.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_search_screen.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_shelf_screen.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_list_screen.dart';
import 'package:whatif_milkyway_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_detail_screen.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_detail_screen.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_create_screen.dart';
import 'package:whatif_milkyway_app/features/memos/presentation/screens/memo_edit_screen.dart';
import 'main_shell.dart';
import 'app_routes.dart';

/// 앱의 메인 라우터
/// 
/// GoRouter 기반 네비게이션 시스템
/// - ShellRoute로 BottomNavigationBar 통합
/// - pathParameters 사용 (extra 대신)
/// - Named routes 지원
final router = GoRouter(
  initialLocation: AppRoutes.splash,
  routes: [
    // 스플래시 화면
    GoRoute(
      path: AppRoutes.splash,
      name: AppRoutes.splashName,
      builder: (context, state) => const SplashScreen(),
    ),
    
    // 로그인 화면
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.loginName,
      builder: (context, state) => const LoginScreen(),
    ),
    
    // 온보딩 화면들
    GoRoute(
      path: AppRoutes.onboardingNickname,
      name: AppRoutes.onboardingNicknameName,
      builder: (context, state) => const NicknameScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboardingProfileImage,
      name: AppRoutes.onboardingProfileImageName,
      builder: (context, state) => const ProfileImageScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboardingBookIntro,
      name: AppRoutes.onboardingBookIntroName,
      builder: (context, state) => const BookIntroScreen(),
    ),
    
    // 책 검색 화면 (별도 라우트)
    GoRoute(
      path: AppRoutes.bookSearch,
      name: AppRoutes.bookSearchName,
      builder: (context, state) => const BookSearchScreen(),
    ),
    
    // 메인 앱 Shell (BottomNavigationBar 포함)
    ShellRoute(
      builder: (context, state, child) => MainShell(
        location: state.uri.toString(),
        child: child,
      ),
      routes: [
        // 홈 화면
        GoRoute(
          path: AppRoutes.home,
          name: AppRoutes.homeName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        
        // 책 관련 화면들
        GoRoute(
          path: AppRoutes.books,
          name: AppRoutes.booksName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookShelfScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.bookShelf,
          name: AppRoutes.bookShelfName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: BookShelfScreen(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.bookDetail}/:id',
          name: AppRoutes.bookDetailName,
          builder: (context, state) => BookDetailScreen(
            bookId: state.pathParameters['id']!,
          ),
        ),
        
        // 메모 관련 화면들
        GoRoute(
          path: AppRoutes.memos,
          name: AppRoutes.memosName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MemoListScreen(),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.memoDetail}/:id',
          name: AppRoutes.memoDetailName,
          builder: (context, state) => MemoDetailScreen(
            memoId: state.pathParameters['id']!,
          ),
        ),
        GoRoute(
          path: AppRoutes.memoCreate,
          name: AppRoutes.memoCreateName,
          builder: (context, state) => const MemoCreateScreen(),
        ),
        GoRoute(
          path: '${AppRoutes.memoEdit}/:id',
          name: AppRoutes.memoEditName,
          builder: (context, state) => MemoEditScreen(
            memoId: state.pathParameters['id']!,
          ),
        ),
        
        // 프로필 화면
        GoRoute(
          path: AppRoutes.profile,
          name: AppRoutes.profileName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
  observers: [RouteObserver<ModalRoute<void>>()],
);
