import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatif_milkyway_app/features/books/presentation/screens/book_search_screen.dart';
import 'package:whatif_milkyway_app/core/presentation/widgets/star_background_scaffold.dart';
import 'package:whatif_milkyway_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:whatif_milkyway_app/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';

class BookIntroScreen extends ConsumerWidget {
  const BookIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PV 이벤트 추가
    ref.read(analyticsProvider).logScreenView('book_intro_screen');

    return StarBackgroundScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상단 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset('assets/images/logo.png', width: 40, height: 40),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF48FF00),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).previousStep();
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ],
              ),
              const Spacer(),
              // 중앙 이미지와 텍스트
              Center(
                child: Column(
                  children: [
                    ShaderMask(
                      shaderCallback: (Rect bounds) {
                        return RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Colors.white,
                            Colors.white.withOpacity(0),
                          ],
                          stops: const [0.7, 1.0],
                        ).createShader(bounds);
                      },
                      child: Image.asset(
                        'assets/images/stars_bg.png',
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.width * 0.8,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      '이제 책을 읽으며\n떠오른 반짝이는 생각을\n메모하고 저장해요 ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 하단 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    await ref.read(analyticsProvider).logButtonClick(
                          'start_onboarding',
                          'book_intro_screen',
                        );
                    // 온보딩 완료 처리
                    await ref
                        .read(authProvider.notifier)
                        .updateOnboardingStatus(completed: true);

                    // 온보딩 완료 시
                    await ref.read(analyticsProvider).logOnboardingComplete();

                    // 책 검색 화면으로 이동
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const BookSearchScreen()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3C19E1),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    '책 검색하고 시작!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
