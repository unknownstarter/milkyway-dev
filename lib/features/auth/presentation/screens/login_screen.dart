import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import 'dart:io' show Platform;
import '../widgets/auth_background_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    // 애니메이션 시작
    _animationController.forward();

    // 앱 라이프사이클 옵저버 등록
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // 옵저버 제거
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 앱이 포그라운드로 돌아올 때 인증 상태 체크
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        ref.read(authProvider.notifier).getCurrentUser();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          // 기술적인 에러 메시지 대신 사용자 친화적인 메시지 표시
          if (error.toString().contains('Not logged in')) {
            // 에러 메시지를 표시하지 않음 (정상적인 로그아웃/탈퇴 상황)
            return;
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '로그인에 실패했습니다. 다시 시도해 주세요.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xFF242424),
            ),
          );
        },
      );
    });

    ref.listen(authProvider, (previous, next) async {
      if (next.hasValue && next.value != null) {
        final onboardingCompleted =
            await ref.read(authProvider.notifier).checkOnboardingStatus();
        if (context.mounted) {
          if (onboardingCompleted) {
            context.goNamed(AppRoutes.homeName);
          } else {
            context.goNamed(AppRoutes.onboardingNicknameName);
          }
        }
      }
    });

    return AuthBackgroundLayout(
      children: [
        const Spacer(),
        // Login buttons with animation
        SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                if (Platform.isIOS)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () =>
                          ref.read(authProvider.notifier).signInWithApple(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: const BorderSide(color: Colors.white),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/apple_logo.png',
                            color: Colors.white,
                            width: 24,
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Apple로 시작하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Container(
                  margin: EdgeInsets.only(bottom: screenSize.height * 0.05),
                  width: double.infinity,
                  height: 56,
                  child: authState.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFECECEC),
                          ))
                      : ElevatedButton(
                          onPressed: () => ref
                              .read(authProvider.notifier)
                              .signInWithGoogle(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Image.asset(
                                  'assets/images/google_logo.png',
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                              const Text(
                                'Google로 시작하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
