import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app_settings/app_settings.dart';

class NotificationSettingsTile extends ConsumerStatefulWidget {
  const NotificationSettingsTile({super.key});

  @override
  ConsumerState<NotificationSettingsTile> createState() =>
      _NotificationSettingsTileState();
}

class _NotificationSettingsTileState
    extends ConsumerState<NotificationSettingsTile> {
  bool _notificationEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final response = await Supabase.instance.client
          .from('users')
          .select('notification_enabled')
          .eq('id', user.id)
          .single();

      if (mounted) {
        setState(() {
          _notificationEnabled = response['notification_enabled'] ?? true;
        });
      }
    } catch (e) {
      // 에러 무시
    }
  }

  Future<void> _toggleNotification(bool value) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('users')
          .update({'notification_enabled': value})
          .eq('id', user.id);

      if (mounted) {
        setState(() {
          _notificationEnabled = value;
          _isLoading = false;
        });
      }

      // 알림을 켤 때 권한 확인 및 요청
      if (value) {
        final notificationService = NotificationService();
        final settings = await notificationService.getNotificationSettings();

        if (settings.authorizationStatus ==
            AuthorizationStatus.notDetermined) {
          // 권한이 없으면 요청
          final granted = await notificationService.requestPermission();
          if (granted) {
            await notificationService.registerToken();
          } else if (mounted) {
            // 권한 거부 시 설정 화면으로 이동 안내
            _showPermissionDeniedDialog();
          }
        } else if (settings.authorizationStatus ==
                AuthorizationStatus.authorized ||
            settings.authorizationStatus ==
                AuthorizationStatus.provisional) {
          // 권한이 있으면 토큰 등록
          await notificationService.registerToken();
        } else if (mounted) {
          // 권한이 거부된 경우 설정 화면으로 이동 안내
          _showPermissionDeniedDialog();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정 저장에 실패했습니다.'),
            backgroundColor: Color(0xFF242424),
          ),
        );
      }
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '알림 권한 필요',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        content: const Text(
          '알림을 받으려면 시스템 설정에서 알림 권한을 허용해주세요.',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w300,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '취소',
              style: TextStyle(
                color: Color(0xFF838383),
                fontFamily: 'Pretendard',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              AppSettings.openAppSettings();
            },
            child: const Text(
              '설정 열기',
              style: TextStyle(
                color: Color(0xFF48FF00),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.notifications_outlined,
        color: Colors.white,
      ),
      title: const Text(
        '알림',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
      trailing: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF48FF00),
              ),
            )
          : Switch(
              value: _notificationEnabled,
              onChanged: _toggleNotification,
              activeColor: const Color(0xFF48FF00),
            ),
    );
  }
}

