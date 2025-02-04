import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import '../../../../core/presentation/widgets/star_background_scaffold.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/onboarding_provider.dart';
import '../screens/book_intro_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';

class ProfileImageScreen extends ConsumerStatefulWidget {
  const ProfileImageScreen({super.key});

  @override
  ConsumerState<ProfileImageScreen> createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends ConsumerState<ProfileImageScreen>
    with WidgetsBindingObserver {
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdatePermissions();
    }
  }

  Future<void> _checkAndUpdatePermissions() async {
    final androidInfo =
        Platform.isAndroid ? await DeviceInfoPlugin().androidInfo : null;

    final galleryStatus = (androidInfo?.version.sdkInt ?? 0) >= 33
        ? await Permission.photos.status
        : await Permission.storage.status;

    if (mounted && galleryStatus.isGranted) {
      // 권한이 허용되었다면 이미지 선택 다이얼로그 표시
      _pickImage();
    }
  }

  Future<void> _pickImage() async {
    if (Platform.isIOS) {
      // iOS에서는 ImagePicker가 자동으로 권한 요청을 처리
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } else {
      // Android는 기존 코드 유지
      PermissionStatus status = await Permission.storage.request();

      if (status.isGranted) {
        final ImagePicker picker = ImagePicker();
        final XFile? image =
            await picker.pickImage(source: ImageSource.gallery);

        if (image != null) {
          setState(() {
            _selectedImagePath = image.path;
          });
        }
      } else if (status.isPermanentlyDenied) {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2A2A2A),
              title: const Text(
                '권한 필요',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                '갤러리 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                TextButton(
                  onPressed: () => openAppSettings(),
                  child: const Text('설정으로 이동'),
                ),
              ],
            ),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('갤러리 접근 권한이 거부되었습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSkip() async {
    try {
      ref.read(onboardingProvider.notifier).nextStep();
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BookIntroScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        width: 24,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFF48FF00),
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
                    ],
                  ),
                  TextButton(
                    onPressed: _handleSkip,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                '프로필 이미지를 등록해주세요.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // 프로필 이미지 영역
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF48FF00),
                      ),
                      child: _selectedImagePath != null
                          ? ClipOval(
                              child: Image.file(
                                File(_selectedImagePath!),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            )
                          : ClipOval(
                              child: Image.asset(
                                'assets/images/default_profile.png',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),
                    // 등록하기 버튼
                    SizedBox(
                      width: 160,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _pickImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C19E1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '등록하기',
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
              const Spacer(),
              Text(
                '나중에 프로필에서 변경할 수 있어요.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              // 하단 버튼 영역
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      ref.read(onboardingProvider.notifier).previousStep();
                      context.go('/onboarding/nickname');
                    },
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _selectedImagePath != null
                            ? () async {
                                try {
                                  if (_selectedImagePath != null) {
                                    await ref
                                        .read(authProvider.notifier)
                                        .updateProfile(
                                          imagePath: _selectedImagePath,
                                        );
                                  }
                                  ref
                                      .read(onboardingProvider.notifier)
                                      .nextStep();
                                  if (mounted) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const BookIntroScreen()),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(e.toString()),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3C19E1),
                          disabledBackgroundColor: const Color(0xFF969696),
                          foregroundColor: Colors.white,
                          disabledForegroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '저장할게요',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
