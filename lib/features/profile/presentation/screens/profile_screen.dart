import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../books/presentation/screens/book_shelf_screen.dart';
import '../../../memos/presentation/screens/memo_list_screen.dart';
import './profile_edit_screen.dart';
import '../../../../core/presentation/widgets/star_background_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // PV 이벤트 추가
    ref.read(analyticsProvider).logScreenView('profile_screen');

    final user = ref.watch(authProvider).value;

    return StarBackgroundScaffold(
      appBar: AppBar(
        title: const Text(
          '프로필',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
      ),
      body: Padding(
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
                  // 프로필 이미지와 이름 행
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
                  // 수정 버튼을 가로 전체 버튼으로 변경
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        await ref.read(analyticsProvider).logButtonClick(
                              'edit_profile',
                              'profile_screen',
                            );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        );
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
                    onTap: () => _showFeedbackBottomSheet(context, ref),
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
                    onTap: () => _launchTermsOfService(ref),
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
                        return Text('v${snapshot.data ?? ''}');
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(
            top: BorderSide(
              color: Colors.grey,
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.black,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.grey[600],
          currentIndex: 3, // 프로필 탭이 선택된 상태
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
                break;
              case 1:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BookShelfScreen()),
                );
                break;
              case 2:
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const MemoListScreen()),
                );
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: '책장',
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
        ),
      ),
    );
  }

  Future<void> _launchTermsOfService(WidgetRef ref) async {
    await ref.read(analyticsProvider).logButtonClick(
          'terms_of_service',
          'profile_screen',
        );
    final Uri url = Uri.parse(
        'https://whatisgoingon.notion.site/1838cdd370538097b80bfa3b9a6fe2b7?pvs=4');
    if (!await launchUrl(
      url,
      mode: LaunchMode.inAppWebView,
      webViewConfiguration: const WebViewConfiguration(
        enableJavaScript: true,
      ),
    )) {
      throw Exception('Could not launch $url');
    }
  }

  void _showFeedbackBottomSheet(BuildContext context, WidgetRef ref) async {
    await ref.read(analyticsProvider).logButtonClick(
          'feedback',
          'profile_screen',
        );
    final textController = TextEditingController();
    final user = ref.read(authProvider).value;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.5,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '의견 남기기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: TextField(
                    controller: textController,
                    maxLength: 500,
                    maxLines: null,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '의견을 입력해주세요',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      counterStyle: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '취소하기',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          if (textController.text.isNotEmpty) {
                            try {
                              await _sendFeedbackEmail(
                                context,
                                textController.text,
                                user?.id,
                                user?.email,
                              );
                              Navigator.pop(context);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('이메일을 보내는 중 오류가 발생했습니다.'),
                                ),
                              );
                            }
                          }
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '보내기',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<String> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  Future<void> _sendFeedbackEmail(BuildContext context, String feedback,
      String? userId, String? userEmail) async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    String deviceId = '';
    String os = '';

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? 'Unknown';
      os = '${iosInfo.systemName} ${iosInfo.systemVersion}';
    } else {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
      os = 'Android ${androidInfo.version.release}';
    }

    final now = DateTime.now();
    final koreanTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now.toLocal());

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'whatif.milkyway.dev@gmail.com',
      queryParameters: {
        'subject': '[WhatiF] 사용자 피드백',
        'body': '''
피드백: $feedback




-------------------
ID: ${userId ?? 'Unknown'}
Email: ${userEmail ?? 'Unknown'}
Device ID: $deviceId
OS: $os
App Version: v${packageInfo.version}
Sent Time: $koreanTime
'''
      },
    );

    if (!await launchUrl(emailLaunchUri)) {
      throw Exception('Could not launch email');
    }
  }
}
