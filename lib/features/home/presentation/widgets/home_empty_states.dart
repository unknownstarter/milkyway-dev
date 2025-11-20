import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'home_profile_section.dart';
import '../../../../core/router/app_routes.dart';

/// 순환 표시할 문구 리스트
const List<String> _readingPrompts = [
  '오늘은 어떤 책을 보고 계신가요?',
  '지금 읽고 있는 책이 있나요?',
  '오늘의 독서는 어떤가요?',
  '어떤 책을 읽고 계신가요?',
  '지금 읽는 책이 궁금해요',
  '오늘도 좋은 책과 함께하시나요?',
];

/// 빈 상태 (책이 없을 때)
class HomeEmptyState extends ConsumerWidget {
  const HomeEmptyState({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 날짜 기반으로 문구 선택 (매일 다른 문구)
    final dayOfYear = DateTime.now()
        .difference(
          DateTime(DateTime.now().year, 1, 1),
        )
        .inDays;
    final promptIndex = dayOfYear % _readingPrompts.length;

    return CustomScrollView(
      slivers: [
        // 앱바 (고정) - HomeScreen과 동일한 구조
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: Container(
            color: const Color(0xFF181818),
            child: _buildAppBar(),
          ),
        ),
        // 프로필 영역
        const SliverToBoxAdapter(
          child: HomeProfileSection(),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
        // 빈 상태 콘텐츠
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _readingPrompts[promptIndex],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () => context.goNamed(AppRoutes.bookSearchName),
                    child: Container(
                      width: 104,
                      height: 147,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade800,
                          width: 1,
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            color: Colors.grey,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '책 등록하기',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 100), // 하단 네비게이션 바 공간
        ),
      ],
    );
  }

  // 앱바 (상단 고정) - HomeScreen과 동일
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo_horizontal.png',
        height: 37,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

/// 로딩 상태
class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 앱바 (고정) - HomeScreen과 동일한 구조
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: Container(
            color: const Color(0xFF181818),
            child: _buildAppBar(),
          ),
        ),
        // 로딩 인디케이터
        const SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFECECEC),
            ),
          ),
        ),
      ],
    );
  }

  // 앱바 (상단 고정) - HomeScreen과 동일
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo_horizontal.png',
        height: 37,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

/// 에러 상태
class HomeErrorState extends StatelessWidget {
  final Object error;

  const HomeErrorState({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // 앱바 (고정) - HomeScreen과 동일한 구조
        SliverAppBar(
          pinned: true,
          floating: false,
          elevation: 0,
          backgroundColor: const Color(0xFF181818),
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          flexibleSpace: Container(
            color: const Color(0xFF181818),
            child: _buildAppBar(),
          ),
        ),
        // 에러 메시지
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SelectableText.rich(
                TextSpan(
                  text: '에러: $error',
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 앱바 (상단 고정) - HomeScreen과 동일
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      child: Image.asset(
        'assets/images/logo_horizontal.png',
        height: 37,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }
}

