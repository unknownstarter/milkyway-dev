import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// 메인 앱 Shell
/// 
/// BottomNavigationBar와 FAB를 포함한 메인 레이아웃
class MainShell extends StatelessWidget {
  final Widget child;
  final String location;

  const MainShell({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: _buildFloatingActionButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(location),
      onTap: (index) => _onTabTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: '홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_outlined),
          activeIcon: Icon(Icons.book),
          label: '책',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.note_outlined),
          activeIcon: Icon(Icons.note),
          label: '메모',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: '프로필',
        ),
      ],
    );
  }

  Widget? _buildFloatingActionButton(BuildContext context) {
    // FAB가 표시되는 화면들
    if (_shouldShowFAB(location)) {
      return FloatingActionButton(
        onPressed: () => _onFABPressed(context),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  int _getCurrentIndex(String location) {
    if (location.startsWith(AppRoutes.home)) return 0;
    if (location.startsWith(AppRoutes.books)) return 1;
    if (location.startsWith(AppRoutes.memos)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.bookShelf);
        break;
      case 2:
        context.go(AppRoutes.memos);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  bool _shouldShowFAB(String location) {
    return location.startsWith(AppRoutes.home) ||
           location.startsWith(AppRoutes.books) ||
           location.startsWith(AppRoutes.memos);
  }

  void _onFABPressed(BuildContext context) {
    if (location.startsWith(AppRoutes.home)) {
      // 홈에서 FAB: 책 검색
      context.push(AppRoutes.bookSearch);
    } else if (location.startsWith(AppRoutes.books)) {
      // 책 목록에서 FAB: 책 검색
      context.push(AppRoutes.bookSearch);
    } else if (location.startsWith(AppRoutes.memos)) {
      // 메모 목록에서 FAB: 메모 작성
      context.push(AppRoutes.memoCreate);
    }
  }
}
