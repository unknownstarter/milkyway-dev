import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/memo_provider.dart';
import '../providers/memo_form_provider.dart';
import '../../../../core/providers/analytics_provider.dart';
import '../../domain/models/memo_visibility.dart';
import '../widgets/memo_visibility_toggle.dart';
import '../widgets/memo_content_input.dart';
import '../widgets/memo_page_input.dart';
import '../widgets/memo_image_selector.dart';
import '../../utils/memo_image_uploader.dart';
import '../../utils/memo_error_handler.dart';

class MemoEditScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoEditScreen({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends ConsumerState<MemoEditScreen> {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  String? _selectedImagePath;
  bool _isLoading = false;
  bool _hasChanges = false;
  String? _bookId;
  bool _isPublic = false; // 공개/비공개 토글 상태
  String? _originalContent;
  String? _originalPage;
  String? _originalImageUrl;
  MemoVisibility? _originalVisibility;

  @override
  void initState() {
    super.initState();
    _loadMemoData();
    _contentController.addListener(() {
      setState(() {}); // 글자 수 카운터 업데이트
      _checkChanges();
    });
    _pageController.addListener(_checkChanges);
    ref.read(analyticsProvider).logScreenView('memo_edit_screen');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMemoData() async {
    try {
      final memo = await ref.read(memoProvider(widget.memoId).future);
      if (mounted) {
        // 메모가 삭제되었거나 존재하지 않는 경우 화면 닫기
        if (memo == null) {
          if (context.mounted) {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.homeName);
            }
          }
          return;
        }
        
        _bookId = memo.bookId;
        _contentController.text = memo.content;
        _pageController.text = memo.page?.toString() ?? '';
        _selectedImagePath = memo.imageUrl;
        _isPublic = memo.visibility == MemoVisibility.public;
        
        // 원본 데이터 저장 (변경사항 감지용)
        _originalContent = memo.content;
        _originalPage = memo.page?.toString();
        _originalImageUrl = memo.imageUrl;
        _originalVisibility = memo.visibility;
        
        // 초기 로드 후 변경사항 체크
        _checkChanges();
      }
    } catch (e) {
      if (mounted) {
        MemoErrorHandler.showError(context, e);
      }
    }
  }

  void _checkChanges() {
    if (_originalContent == null) {
      // 아직 원본 데이터가 로드되지 않았으면 변경사항 없음
      setState(() {
        _hasChanges = false;
      });
      return;
    }
    
    final currentContent = _contentController.text.trim();
    final currentPage = _pageController.text.trim();
    final currentImageUrl = _selectedImagePath;
    final currentVisibility = _isPublic ? MemoVisibility.public : MemoVisibility.private;
    
    // 원본과 비교하여 변경사항 확인
    final contentChanged = currentContent != _originalContent;
    final pageChanged = currentPage != (_originalPage ?? '');
    final imageChanged = currentImageUrl != _originalImageUrl;
    final visibilityChanged = currentVisibility != _originalVisibility;
    
    setState(() {
      _hasChanges = contentChanged || pageChanged || imageChanged || visibilityChanged;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _hasChanges
              ? _showExitDialog
              : () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.goNamed(AppRoutes.homeName);
                  }
                },
        ),
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text(
            '메모 편집',
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
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _deleteMemo,
            child: const Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                // 메모 공개 선택 (토글)
                MemoVisibilityToggle(
                  value: _isPublic,
                  onChanged: (value) {
                    setState(() {
                      _isPublic = value;
                    });
                    _checkChanges();
                  },
                ),
            const SizedBox(height: 20),
            
            // 메모 내용
                MemoContentInput(controller: _contentController),
                const SizedBox(height: 20),

                // 페이지 입력
                MemoPageInput(controller: _pageController),
            const SizedBox(height: 20),
            
            // 이미지 선택
                MemoImageSelector(
                  imagePath: _selectedImagePath,
                  onSelectImage: _selectImage,
                  onRemoveImage: _removeImage,
        ),
                SizedBox(
                  height: 50 + 20 + 20 + MediaQuery.of(context).padding.bottom + 20, // 버튼 높이 + 상하 패딩 + SafeArea + 여유 공간
                ),
              ],
            ),
            ),
          // 하단 고정 저장하기 버튼 (책 상세의 메모하기와 동일한 스타일)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              bottom: false, // SafeArea를 false로 하여 하단까지 확장
              child: Column(
                mainAxisSize: MainAxisSize.min,
      children: [
                  // 불투명 배경 (181818 색상으로 버튼 뒤와 아래 영역 모두 가리기)
                  Container(
                    color: const Color(0xFF181818),
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 20,
                      bottom: 20,
                    ),
                    child: _buildSaveButton(),
                  ),
                  // 하단 영역까지 181818로 가리기
                  Container(
                    color: const Color(0xFF181818),
                    height: MediaQuery.of(context).padding.bottom,
                  ),
                ],
                  ),
                ),
              ),
          ],
        ),
    );
  }

  Widget _buildSaveButton() {
    final isEnabled = _hasChanges && !_isLoading;
    
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFDEDEDE) : const Color(0xFF838383),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? _saveMemo : null,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              '저장하기',
              style: TextStyle(
                color: isEnabled ? Colors.black : Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                height: 24 / 16,
              ),
            ),
          ),
              ),
      ),
    );
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        barrierColor: Colors.black.withOpacity(0.5), // 어두운 딤 처리
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('이미지 선택', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                  title: const Text('카메라로 촬영',
                      style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        try {
          final image = await picker.pickImage(
            source: source,
            imageQuality: 85,
          );
        if (image != null) {
          setState(() {
            _selectedImagePath = image.path;
          });
            _checkChanges();
          }
        } on PlatformException catch (e) {
          if (mounted) {
            MemoErrorHandler.showError(context, e);
          }
        } catch (e) {
          if (mounted) {
            MemoErrorHandler.showError(context, e);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        MemoErrorHandler.showError(context, e);
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
    _checkChanges();
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      MemoErrorHandler.showErrorSnackBar(context, '메모 내용을 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_bookId == null) {
        throw Exception('책 정보를 불러올 수 없습니다');
      }
      
      final visibility = _isPublic ? MemoVisibility.public : MemoVisibility.private;
      
      // 이미지가 로컬 파일 경로인 경우 Supabase Storage에 업로드
      String? imageUrl = _selectedImagePath;
      if (MemoImageUploader.isLocalFile(_selectedImagePath)) {
        imageUrl = await MemoImageUploader.uploadImage(_selectedImagePath!);
        if (imageUrl == null) {
          if (mounted) {
            MemoErrorHandler.showErrorSnackBar(context, '이미지 업로드에 실패했습니다');
          }
          return;
        }
      }
      
      await ref.read(memoFormProvider(_bookId!).notifier).updateMemo(
        memoId: widget.memoId,
        content: _contentController.text.trim(),
        page: _pageController.text.isNotEmpty ? int.tryParse(_pageController.text) : null,
        imageUrl: imageUrl,
        visibility: visibility,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '메모가 수정되었습니다',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF242424),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        MemoErrorHandler.showError(context, e);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMemo() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5), // 어두운 딤 처리
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '메모 삭제',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '이 메모를 삭제하시겠습니까?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: const Text('삭제', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        if (_bookId == null) {
          throw Exception('책 정보를 불러올 수 없습니다');
        }
        
        await ref.read(deleteMemoProvider(
          (memoId: widget.memoId, bookId: _bookId!),
        ).future);
        
        if (!mounted) return;
        if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          MemoErrorHandler.showError(context, e);
        }
      }
    }
  }

  Future<void> _showExitDialog() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5), // 어두운 딤 처리
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          '변경사항이 있습니다',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '저장하지 않고 나가시겠습니까?',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('나가기', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldExit == true && mounted) {
      context.pop();
    }
  }
}
