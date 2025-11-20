import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackModal extends ConsumerWidget {
  const FeedbackModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    final user = ref.read(authProvider).value;

    return Container(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20,
      ),
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
              cursorColor: Colors.white,
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
                        // 사용자 정보에서 referral_code 가져오기
                        final referralCode = await _getUserReferralCode(ref, user?.id);
                        await _sendFeedbackEmail(
                          context,
                          textController.text,
                          user?.id,
                          user?.email,
                          referralCode,
                        );
                        Navigator.pop(context);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '이메일을 보내는 중 오류가 발생했습니다.',
                              style: TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Color(0xFF242424),
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
    );
  }

  /// 사용자의 referral_code를 가져오는 헬퍼 함수
  Future<String?> _getUserReferralCode(WidgetRef ref, String? userId) async {
    if (userId == null) return null;
    
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('users')
          .select('referral_code')
          .eq('id', userId)
          .maybeSingle();
      
      return response?['referral_code'] as String?;
    } catch (e) {
      // 에러 발생 시 null 반환 (referral_code 없이 진행)
      return null;
    }
  }

  Future<void> _sendFeedbackEmail(BuildContext context, String feedback,
      String? userId, String? userEmail, String? referralCode) async {
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
Referral Code: ${referralCode ?? 'Unknown'}
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