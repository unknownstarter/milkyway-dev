import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../books/presentation/screens/book_search_screen.dart';
import '../../../books/presentation/screens/book_shelf_screen.dart';
import '../../../memos/presentation/screens/memo_list_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../providers/book_provider.dart';
import '../providers/selected_book_provider.dart';
import '../widgets/recent_books_section.dart';
import '../widgets/recent_memos_section.dart';
import '../widgets/user_profile_section.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import '../widgets/star_background_painter.dart';
import '../../../memos/presentation/screens/memo_create_screen.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../memos/presentation/providers/memo_provider.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final bool autoNavigateToBookSearch;

  const HomeScreen({
    super.key,
    this.autoNavigateToBookSearch = false,
  });

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _initializeHome();
    ref.read(analyticsProvider).logScreenView('home_screen');
  }

  Future<void> _initializeHome() async {
    // 먼저 인증과 데이터 로드를 완료
    await _checkAuthAndLoadData();

    // 인증이 완료된 후에만 자동 이동 실행
    if (widget.autoNavigateToBookSearch && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const BookSearchScreen(),
        ),
      );
    }
  }

  Future<void> _checkAuthAndLoadData() async {
    try {
      final user = await ref.read(authProvider.notifier).getCurrentUser();
      if (user == null || !mounted) {
        // 인증 실패시 모든 캐시 초기화
        ref.invalidate(userBooksProvider);
        ref.invalidate(recentBooksProvider);
        ref.invalidate(recentMemosProvider);

        _redirectToLogin();
        return;
      }

      // 데이터 리프레시
      ref.invalidate(recentBooksProvider);
      ref.invalidate(recentMemosProvider);

      // 인증된 유저만 데이터 로드
      final books = await ref.read(recentBooksProvider.future);
      if (mounted && books.isNotEmpty) {
        ref.read(selectedBookIdProvider.notifier).state = books.first.id;
      }
    } catch (e) {
      if (mounted) {
        _redirectToLogin();
      }
    }
  }

  void _redirectToLogin() {
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 빌드 시에도 유저 상태 확인
    ref.listen(authProvider, (previous, next) {
      if (!next.isLoading && (next.hasError || next.value == null)) {
        context.go('/login');
      }
    });

    final authState = ref.watch(authProvider);
    if (!authState.isLoading &&
        (authState.hasError || authState.value == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 별이 있는 배경
          Positioned.fill(
            child: CustomPaint(
              painter: StarBackgroundPainter(numberOfStars: 150),
            ),
          ),
          // 기존 content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final authState = ref.watch(authProvider);
                      if (authState.isLoading) {
                        return const SizedBox(
                            height: 80); // UserProfileSection의 대략적인 높이
                      }
                      return const UserProfileSection();
                    },
                  ),
                  const SizedBox(height: 50),
                  const SizedBox(
                    height: 540,
                    child: RecentBooksSection(),
                  ),
                  const SizedBox(height: 10),
                  Consumer(
                    builder: (context, ref, child) {
                      final selectedBook = ref.watch(selectedBookProvider);

                      if (selectedBook == null) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text(
                              '${selectedBook.title.length > 8 ? '${selectedBook.title.substring(0, 8)}...' : selectedBook.title}의 반짝임 ✨',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(
                            height: 300,
                            child: RecentMemosSection(),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Image.asset(
          'assets/images/logo_horizontal.png',
          height: 32, // 로고 이미지 높이 조정
          fit: BoxFit.contain,
        ),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await ref.read(analyticsProvider).logButtonClick(
                'fab_create_memo',
                'home_screen',
              );
          if (!mounted) return;
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.white,
            constraints: BoxConstraints(
              maxHeight:
                  MediaQuery.of(context).size.height * 0.3, // 화면 높이의 30%로 설정
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16), // 상단 여백 추가
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4117EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color: Color(0xFF4117EB),
                    ),
                  ),
                  title: const Text(
                    '책 등록하기',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context); // 모달 닫기
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BookSearchScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4117EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF4117EB),
                    ),
                  ),
                  title: const Text(
                    '메모 작성하기',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MemoCreateScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16), // 하단 여백 추가
              ],
            ),
          );
        },
        backgroundColor: const Color(0xFF4117EB),
        shape: const CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade800,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey.shade600,
          currentIndex: 0,
          onTap: (index) {
            switch (index) {
              case 0:
                ref.read(analyticsProvider).logButtonClick(
                      'nav_home',
                      'home_screen',
                    );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeScreen(),
                  ),
                  (route) => false,
                );
                break;
              case 1:
                ref.read(analyticsProvider).logButtonClick(
                      'nav_bookshelf',
                      'home_screen',
                    );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BookShelfScreen()),
                );
                break;
              case 2:
                ref.read(analyticsProvider).logButtonClick(
                      'nav_memolist',
                      'home_screen',
                    );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MemoListScreen()),
                );
                break;
              case 3:
                ref.read(analyticsProvider).logButtonClick(
                      'nav_profile',
                      'home_screen',
                    );
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProfileScreen()),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book),
              label: '책 목록',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.note),
              label: '메모',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}
