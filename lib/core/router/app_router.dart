import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'router_extensions.dart';
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
import 'package:whatif_milkyway_app/features/profile/presentation/screens/profile_edit_screen.dart';
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
      builder: (context, state) {
        final isFromOnboarding = state.getBoolQuery('isFromOnboarding');
        return BookSearchScreen(isFromOnboarding: isFromOnboarding);
      },
    ),
    
    // 책 상세 화면 (하단 네비게이션바 없음)
    GoRoute(
      path: '${AppRoutes.bookDetail}/:id',
      name: AppRoutes.bookDetailName,
      builder: (context, state) {
        final bookId = state.requirePathParam('id');
        final isFromRegistration = state.getBoolQuery('isFromRegistration');
        final isFromOnboarding = state.getBoolQuery('isFromOnboarding');
        return BookDetailScreen(
          bookId: bookId,
          isFromRegistration: isFromRegistration,
          isFromOnboarding: isFromOnboarding,
        );
      },
    ),
    
    // 메모 작성 화면 (ShellRoute 밖 - 책 상세에서 접근용)
    // 주의: ShellRoute 안에도 동일한 경로가 있지만, 
    // ShellRoute 밖에서는 하단 네비게이션바 없이 표시됨
    GoRoute(
      path: AppRoutes.memoCreate,
      name: AppRoutes.memoCreateName,
      builder: (context, state) {
        final bookId = state.uri.queryParameters['bookId'];
        return MemoCreateScreen(
          bookId: bookId,
        );
      },
    ),
    
    // 프로필 수정 화면 (ShellRoute 밖 - 하단 네비게이션바 없음)
    GoRoute(
      path: AppRoutes.profileEdit,
      name: AppRoutes.profileEditName,
      builder: (context, state) => const ProfileEditScreen(),
    ),
    
    // 메모 상세 화면 (ShellRoute 밖 - 하단 네비게이션바 없음)
    GoRoute(
      path: '${AppRoutes.memoDetail}/:id',
      name: AppRoutes.memoDetailName,
      builder: (context, state) => MemoDetailScreen(
        memoId: state.requirePathParam('id'),
      ),
    ),
    
    // 메모 편집 화면 (ShellRoute 밖 - 하단 네비게이션바 없음)
    GoRoute(
      path: '${AppRoutes.memoEdit}/:id',
      name: AppRoutes.memoEditName,
      builder: (context, state) => MemoEditScreen(
        memoId: state.requirePathParam('id'),
      ),
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
          pageBuilder: (context, state) {
            final autoBookSearch = state.getBoolQuery('autoBookSearch');
            return NoTransitionPage(
              child: HomeScreen(autoBookSearch: autoBookSearch),
            );
          },
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
        
        // 메모 관련 화면들
        GoRoute(
          path: AppRoutes.memos,
          name: AppRoutes.memosName,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MemoListScreen(),
          ),
        ),
        // 메모 작성 화면 (ShellRoute 안 - 하단 네비게이션바 있음)
        // 주의: ShellRoute 밖에도 동일한 경로가 있지만,
        // ShellRoute 안에서는 하단 네비게이션바와 함께 표시됨
        // GoRouter는 첫 번째 매칭되는 라우트를 사용하므로,
        // ShellRoute 밖의 라우트가 우선순위가 높음
        // 따라서 ShellRoute 안의 이 라우트는 실제로 사용되지 않을 수 있음
        
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
