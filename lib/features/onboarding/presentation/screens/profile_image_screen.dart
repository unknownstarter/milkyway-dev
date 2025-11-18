import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/onboarding_provider.dart';
import '../../../../core/providers/analytics_provider.dart';

class ProfileImageScreen extends ConsumerStatefulWidget {
  const ProfileImageScreen({super.key});

  @override
  ConsumerState<ProfileImageScreen> createState() => _ProfileImageScreenState();
}

class _ProfileImageScreenState extends ConsumerState<ProfileImageScreen> {
  String? _selectedImagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    ref.read(analyticsProvider).logScreenView('profile_image_screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: const Text(
          '프로필 사진',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // 제목
            _buildTitle(),
            const SizedBox(height: 40),
            
            // 프로필 이미지
            _buildProfileImage(),
            const SizedBox(height: 40),
            
            // 이미지 선택 버튼들
            _buildImageButtons(),
            const SizedBox(height: 40),
            
            // 건너뛰기 버튼
            _buildSkipButton(),
            const SizedBox(height: 20),
            
            // 다음 버튼
            _buildNextButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        const Text(
          '프로필 사진을 설정해주세요',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Pretendard',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          '나중에 언제든지 변경할 수 있습니다',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontFamily: 'Pretendard',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _selectImage,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF48FF00),
            width: 4,
          ),
        ),
        child: ClipOval(
          child: _getProfileImage(),
        ),
      ),
    );
  }

  Widget _getProfileImage() {
    if (_selectedImagePath != null) {
      return Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.cover,
        width: 200,
        height: 200,
      );
    } else {
      return Container(
        width: 200,
        height: 200,
        color: const Color(0xFF1A1A1A),
        child: const Icon(
          Icons.person,
          color: Colors.grey,
          size: 80,
        ),
      );
    }
  }

  Widget _buildImageButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectImage,
            icon: const Icon(Icons.photo_library, color: Colors.black),
            label: const Text(
              '갤러리에서 선택',
              style: TextStyle(
                color: Colors.black,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF48FF00),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _takePhoto,
            icon: const Icon(Icons.camera_alt, color: Color(0xFF48FF00)),
            label: const Text(
              '카메라로 촬영',
              style: TextStyle(
                color: Color(0xFF48FF00),
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF48FF00)),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        if (_selectedImagePath != null) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text(
                '사진 제거',
                style: TextStyle(
                  color: Colors.red,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _isLoading ? null : _skipImage,
      child: Text(
        '건너뛰기',
        style: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 16,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF48FF00),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                color: Color(0xFFECECEC),
                strokeWidth: 2,
              )
            : const Text(
                '다음',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Pretendard',
                ),
              ),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFF242424),
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('사진 촬영 중 오류가 발생했습니다: $e'),
          backgroundColor: const Color(0xFF242424),
        ),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _skipImage() async {
    await _next();
  }

  Future<void> _next() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 프로필 이미지 저장
      if (_selectedImagePath != null) {
        await ref.read(onboardingProvider.notifier).setProfileImage(_selectedImagePath!);
      }

      // 다음 화면으로 이동
      if (mounted) {
        context.goNamed(AppRoutes.onboardingBookIntroName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 이미지 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}