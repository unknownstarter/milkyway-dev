import 'dart:ui';
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
      backgroundColor: const Color(0xFF181818),
      body: child,
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final currentIndex = _getCurrentIndex(location);
    
    return Container(
      color: const Color(0xFF181818), // 배경은 181818
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 10),
          child: Container(
            constraints: const BoxConstraints(
              minHeight: 64,
              maxHeight: 70,
            ),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2C),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    _buildNavButton(
                      context: context,
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      isActive: currentIndex == 0,
                      onTap: () => _onTabTapped(context, 0),
                    ),
                    _buildNavButton(
                      context: context,
                      icon: Icons.book_outlined,
                      activeIcon: Icons.book,
                      label: 'Books',
                      isActive: currentIndex == 1,
                      onTap: () => _onTabTapped(context, 1),
                    ),
                    _buildNavButton(
                      context: context,
                      icon: Icons.note_outlined,
                      activeIcon: Icons.note,
                      label: 'Memos',
                      isActive: currentIndex == 2,
                      onTap: () => _onTabTapped(context, 2),
                    ),
                    _buildNavButton(
                      context: context,
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Profile',
                      isActive: currentIndex == 3,
                      onTap: () => _onTabTapped(context, 3),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        constraints: const BoxConstraints(
          minWidth: 60,
          maxWidth: 80,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              size: 20,
              color: isActive ? const Color(0xFFF3F3F3) : const Color(0xFF757575),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                fontSize: 10,
                color: isActive ? const Color(0xFFF3F3F3) : const Color(0xFF757575),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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

}
