import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/memo_form_provider.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../../core/providers/analytics_provider.dart';

class MemoCreateScreen extends ConsumerStatefulWidget {
  final String? bookId;
  final String? bookTitle;

  const MemoCreateScreen({
    super.key,
    this.bookId,
    this.bookTitle,
  });

  @override
  ConsumerState<MemoCreateScreen> createState() => _MemoCreateScreenState();
}

class _MemoCreateScreenState extends ConsumerState<MemoCreateScreen> {
  final _contentController = TextEditingController();
  final _pageController = TextEditingController();
  String? _selectedImagePath;
  bool _isLoading = false;
  String? _selectedBookId;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.bookId;
    ref.read(analyticsProvider).logScreenView('memo_create_screen');
  }

  @override
  void dispose() {
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF181818),
      appBar: AppBar(
        backgroundColor: const Color(0xFF181818),
        title: const Text(
          '메모 작성',
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
            onPressed: _isLoading ? null : _saveMemo,
            child: Text(
              '저장',
              style: TextStyle(
                color: _isLoading ? Colors.grey : const Color(0xFF48FF00),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 책 선택
            _buildBookSelector(),
            const SizedBox(height: 20),

            // 페이지 입력
            _buildPageInput(),
            const SizedBox(height: 20),

            // 메모 내용
            _buildContentInput(),
            const SizedBox(height: 20),

            // 이미지 선택
            _buildImageSelector(),
            const SizedBox(height: 20),

            // 선택된 이미지
            if (_selectedImagePath != null) _buildSelectedImage(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookSelector() {
    final booksAsync = ref.watch(userBooksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '책 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        booksAsync.when(
          data: (books) => _buildBookDropdown(books),
          loading: () =>
              const CircularProgressIndicator(color: Color(0xFFECECEC)),
          error: (error, stack) => Text(
            '책 목록을 불러올 수 없습니다: $error',
            style: const TextStyle(color: Colors.red, fontFamily: 'Pretendard'),
          ),
        ),
      ],
    );
  }

  Widget _buildBookDropdown(List<dynamic> books) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBookId,
          isExpanded: true,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
          dropdownColor: const Color(0xFF1A1A1A),
          items: books.map((book) {
            return DropdownMenuItem<String>(
              value: book.id,
              child: Text(book.title, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedBookId = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildPageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '페이지 (선택사항)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _pageController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
          decoration: InputDecoration(
            hintText: '예: 42',
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontFamily: 'Pretendard'),
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
              borderSide: const BorderSide(color: Color(0xFF48FF00)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '메모 내용',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contentController,
          maxLines: 8,
          style: const TextStyle(color: Colors.white, fontFamily: 'Pretendard'),
          decoration: InputDecoration(
            hintText: '읽은 내용이나 생각을 적어보세요...',
            hintStyle: TextStyle(
                color: Colors.grey.shade400, fontFamily: 'Pretendard'),
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
              borderSide: const BorderSide(color: Color(0xFF48FF00)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이미지 (선택사항)',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectImage,
                icon: const Icon(Icons.add_photo_alternate,
                    color: Color(0xFF48FF00)),
                label: const Text(
                  '이미지 추가',
                  style: TextStyle(
                    color: Color(0xFF48FF00),
                    fontFamily: 'Pretendard',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF48FF00)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            if (_selectedImagePath != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  '제거',
                  style: TextStyle(
                    color: Colors.red,
                    fontFamily: 'Pretendard',
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(_selectedImagePath!),
          fit: BoxFit.cover,
        ),
      ),
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
          }
        } on PlatformException catch (e) {
          if (mounted) {
            String errorMessage = '카메라 접근 중 오류가 발생했습니다';
            if (e.code == 'camera_access_denied') {
              errorMessage = '카메라 접근 권한이 거부되었습니다';
            } else if (e.code == 'camera_unavailable') {
              errorMessage = '카메라를 사용할 수 없습니다\n(시뮬레이터에서는 카메라를 사용할 수 없습니다)';
            } else if (e.message != null && e.message!.isNotEmpty) {
              errorMessage = '카메라 오류: ${e.message}';
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: const Color(0xFF242424),
                duration: const Duration(seconds: 4),
              ),
            );
          }
        } catch (e) {
          // PlatformException이 아닌 다른 예외 처리 (크래시 방지)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  '카메라를 사용할 수 없습니다\n(시뮬레이터에서는 카메라를 사용할 수 없습니다)',
                ),
                backgroundColor: Color(0xFF242424),
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '이미지 선택 중 오류가 발생했습니다: ${e.toString()}',
            ),
            backgroundColor: const Color(0xFF242424),
          ),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImagePath = null;
    });
  }

  Future<void> _saveMemo() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('메모 내용을 입력해주세요'),
          backgroundColor: Color(0xFF242424),
        ),
      );
      return;
    }

    if (_selectedBookId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('책을 선택해주세요'),
          backgroundColor: Color(0xFF242424),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedBookId == null) {
        throw Exception('책을 선택해주세요');
      }
      await ref.read(memoFormProvider(_selectedBookId!).notifier).createMemo(
            bookId: _selectedBookId!,
            content: _contentController.text.trim(),
            page: _pageController.text.isNotEmpty
                ? int.tryParse(_pageController.text)
                : null,
            imageUrl: _selectedImagePath,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 저장되었습니다'),
            backgroundColor: Color(0xFF242424),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메모 저장 중 오류가 발생했습니다: $e'),
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
