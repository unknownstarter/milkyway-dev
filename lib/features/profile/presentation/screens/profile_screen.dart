import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/feedback_modal.dart';
import '../widgets/notification_settings_tile.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent, // Material 3에서 스크롤 시 색상 변경 방지
        elevation: 0,
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 20,
              height: 28 / 20,
            ),
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      // MainShell에서 이미 bottomNavigationBar를 제공하므로 제거
      body: userAsync.when(
        data: (user) => user == null
            ? const Center(child: Text('로그인이 필요합니다.'))
            : _ProfileContent(user: user),
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFFECECEC)),
        ),
        error: (e, st) => Center(
          child: SelectableText.rich(
            TextSpan(
              text: '에러: $e',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  final dynamic user;
  const _ProfileContent({required this.user});

  void _showFeedbackModal(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '피드백 모달',
      barrierColor: Colors.black.withOpacity(0.5), // 어두운 딤 처리
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final screenHeight = MediaQuery.of(context).size.height;
        
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // 바텀시트 내부 탭은 무시
                child: Container(
                  width: double.infinity,
                  height: screenHeight * 0.5,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: const FeedbackModal(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 사용자 정보 섹션
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: Colors.grey.shade800,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: NetworkImage(user?.pictureUrl ??
                          'https://hyjgfgzexvxhgfmqgiqu.supabase.co/storage/v1/object/public/profile_images/default_profile.png'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.nickname ?? '',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.pushNamed(AppRoutes.profileEditName);
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey.shade900,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '수정',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 메뉴 리스트
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const NotificationSettingsTile(),
                Divider(color: Colors.grey.shade800, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.feedback_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    '의견 남기기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onTap: () => _showFeedbackModal(context),
                ),
                Divider(color: Colors.grey.shade800, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.description_outlined,
                    color: Colors.white,
                  ),
                  title: const Text(
                    '서비스 이용 약관',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onTap: () => _launchTermsOfService(context),
                ),
                Divider(color: Colors.grey.shade800, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                  ),
                  title: const Text(
                    '앱 버전',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  trailing: FutureBuilder<String>(
                    future: _getAppVersion(),
                    builder: (context, snapshot) {
                      return Text('v${snapshot.data ?? ''}', style: const TextStyle(color: Colors.white));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchTermsOfService(BuildContext context) async {
    final Uri url = Uri.parse(
        'https://whatisgoingon.notion.site/1838cdd370538097b80bfa3b9a6fe2b7?pvs=4');
    if (!await canLaunchUrl(url)) return;
    await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
      ),
    );
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
