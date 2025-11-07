import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/splash_layout.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _validateSession();
  }

  Future<void> _validateSession() async {
    try {
      // 네트워크 연결 체크 추가
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('인터넷 연결 없음'),
              content: const Text('인터넷 연결을 확인하고 다시 시도해주세요.'),
              actions: [
                TextButton(
                  onPressed: () {
                    _validateSession(); // 재시도
                    Navigator.pop(context);
                  },
                  child: const Text('재시도'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // 앱 버전 체크 추가
      await ref.read(authProvider.notifier).checkAppVersion();

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null || session.isExpired) {
        if (mounted) context.go('/login');
        return;
      }

      final user = await ref.read(authProvider.notifier).getCurrentUser();
      if (user == null) {
        if (mounted) context.go('/login');
        return;
      }

      if (!user.onboardingCompleted) {
        if (mounted) context.go('/onboarding/nickname');
        return;
      }

      if (mounted) context.go('/home');
    } catch (e) {
      if (e.toString().contains('업데이트가 필요합니다')) {
        _showForceUpdateDialog();
      } else {
        if (mounted) context.go('/login');
      }
    }
  }

  void _showForceUpdateDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('업데이트 필요'),
        content: const Text('새로운 버전이 있습니다.\n원활한 사용을 위해 업데이트를 진행해주세요.'),
        actions: [
          TextButton(
            onPressed: () {
              final url = Platform.isIOS
                  ? 'your_ios_app_store_url'
                  : 'your_android_play_store_url';
              launchUrl(Uri.parse(url));
            },
            child: const Text('업데이트'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SplashLayout();
  }
}
