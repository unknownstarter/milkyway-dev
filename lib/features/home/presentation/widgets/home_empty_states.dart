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

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeProfileSection(),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _readingPrompts[promptIndex],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
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
    );
  }
}

/// 로딩 상태
class HomeLoadingState extends StatelessWidget {
  const HomeLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFFECECEC),
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
    return Center(
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
    );
  }
}

