import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/error_handler.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _selectedImagePath;
  bool _isImageRemoved = false;

  @override
  void initState() {
    super.initState();
    // initState에서는 ref를 사용할 수 없으므로 didChangeDependencies에서 처리
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면 재진입 시 최신 사용자 정보 로드 (예: 프로필 수정 후 돌아올 때)
    _loadUserData();
    // Analytics는 빌드 후에 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(analyticsProvider).logScreenView('profile_edit_screen');
      }
    });
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    // didChangeDependencies에서 호출되므로 ref 사용 가능
    final user = ref.read(authProvider).value;
    if (user != null) {
      // 닉네임이 변경된 경우에만 컨트롤러 업데이트 (무한 루프 방지)
      if (_nicknameController.text != user.nickname) {
        _nicknameController.text = user.nickname;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;

    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: const Text(
          '프로필 수정',
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '저장',
              style: TextStyle(
                color: _isLoading ? Colors.grey : Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 프로필 이미지
            _buildProfileImage(user?.pictureUrl),
            const SizedBox(height: 32),
            
            // 닉네임 입력
            _buildNicknameInput(),
            const SizedBox(height: 32),
            
            // 이메일 (읽기 전용)
            _buildEmailField(user?.email),
            const SizedBox(height: 40),
            
            // 로그아웃 버튼
            _buildLogoutButton(),
            const SizedBox(height: 16),
            
            // 계정 삭제 버튼
            _buildDeleteAccountButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? currentImageUrl) {
    return Column(
      children: [
        GestureDetector(
          onTap: _selectImage,
          child: Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: _getProfileImage(currentImageUrl),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: _selectImage,
          icon: const Icon(Icons.camera_alt, color: Colors.white),
          label: const Text(
            '프로필 사진 변경',
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        if (_selectedImagePath != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _removeImage,
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              '사진 제거',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _getProfileImage(String? imageUrl) {
    if (_selectedImagePath != null) {
      return Image.file(
        File(_selectedImagePath!),
        fit: BoxFit.cover,
        width: 120,
        height: 120,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 120,
      height: 120,
      color: const Color(0xFF1A1A1A),
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 60,
      ),
    );
  }

  Widget _buildNicknameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '닉네임',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
          decoration: InputDecoration(
            hintText: '닉네임을 입력하세요',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontFamily: 'Pretendard'),
            filled: true,
            fillColor: const Color(0xFF1A1A1A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade800),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(String? email) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이메일',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800),
          ),
          child: Text(
            email ?? '이메일 없음',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '이메일은 변경할 수 없습니다',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 12,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('이미지 선택', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('갤러리에서 선택', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('카메라로 촬영', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final image = await picker.pickImage(source: source);
        if (image != null && mounted) {
          setState(() {
            _selectedImagePath = image.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
      _isImageRemoved = true;
    });
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _logout,
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.shade900.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.red.shade700, width: 1),
          ),
        ),
        child: const Text(
          '로그아웃',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '로그아웃',
          style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        content: const Text(
          '정말 로그아웃 하시겠습니까?',
          style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    try {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) {
        context.goNamed(AppRoutes.loginName);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '로그아웃');
      }
    }
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _deleteAccount,
        style: TextButton.styleFrom(
          backgroundColor: Colors.grey.shade800,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade700, width: 1),
          ),
        ),
        child: const Text(
          '계정 삭제',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // 계정 삭제 확인 다이얼로그
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '계정 삭제',
          style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        content: const Text(
          '계정을 삭제하면 모든 책과 메모들이 영구적으로 삭제되며 복구할 수 없습니다.\n\n정말 계정을 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              '취소',
              style: TextStyle(color: Colors.grey, fontFamily: 'Pretendard'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '확인',
              style: TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) {
        context.goNamed(AppRoutes.loginName);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '계정 삭제');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('닉네임을 입력해주세요'),
          backgroundColor: Color(0xFF242424),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 프로필 이미지 처리
      String? uploadedImageUrl;
      if (_isImageRemoved) {
        // 이미지 제거 요청
        uploadedImageUrl = '';
      } else if (_selectedImagePath != null) {
        // 새 이미지 업로드
        uploadedImageUrl = await _uploadProfileImage(_selectedImagePath!);
        if (uploadedImageUrl == null) {
          if (mounted) {
            ErrorHandler.showErrorSnackBar(
              context,
              message: '프로필 이미지 업로드에 실패했습니다',
            );
          }
          return;
        }
      }
      // _selectedImagePath가 null이고 _isImageRemoved가 false면 기존 이미지 유지 (uploadedImageUrl = null)

      await ref.read(authProvider.notifier).updateProfile(
        nickname: _nicknameController.text.trim(),
        pictureUrl: uploadedImageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('프로필이 수정되었습니다'),
            backgroundColor: Color(0xFF242424),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e, operation: '프로필 수정');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 프로필 이미지를 Supabase Storage에 업로드하고 signed URL을 반환
  Future<String?> _uploadProfileImage(String filePath) async {
    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      
      if (userId == null) {
        return null;
      }

      final fileName = '$userId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(filePath);

      // 파일 존재 여부 확인
      if (!await file.exists()) {
        return null;
      }

      // Supabase Storage에 업로드
      await supabase.storage.from('profile_images').upload(fileName, file);

      // Signed URL 생성 (1년 유효)
      final imageUrl = await supabase.storage
          .from('profile_images')
          .createSignedUrl(fileName, 60 * 60 * 24 * 365);

      return imageUrl;
    } catch (e) {
      return null;
    }
  }
}