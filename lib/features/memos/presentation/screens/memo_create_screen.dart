import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../books/presentation/screens/book_detail_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';

class MemoCreateScreen extends ConsumerStatefulWidget {
  final String? bookId;
  final String? bookTitle;
  final VoidCallback? onComplete;

  const MemoCreateScreen({
    super.key,
    this.bookId,
    this.bookTitle,
    this.onComplete,
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
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _selectedBookId = widget.bookId;
    _contentController.addListener(() {
      setState(() {
        _hasContent = _contentController.text.isNotEmpty;
      });
    });
    ref.read(analyticsProvider).logScreenView('memo_create_screen');
  }

  Future<void> _selectImage() async {
    try {
      final picker = ImagePicker();
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('이미지 선택', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.white),
                title: const Text('갤러리에서 선택',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await ref.read(analyticsProvider).logButtonClick(
                        'select_image_gallery',
                        'memo_create_screen',
                      );
                  Navigator.pop(context, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text('카메라로 촬영',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  await ref.read(analyticsProvider).logButtonClick(
                        'select_image_camera',
                        'memo_create_screen',
                      );
                  Navigator.pop(context, ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        // 권한 체크
        final androidInfo =
            Platform.isAndroid ? await DeviceInfoPlugin().androidInfo : null;
        final permission = source == ImageSource.camera
            ? Platform.isAndroid
                ? await Permission.camera.request()
                : PermissionStatus.granted // iOS는 ImagePicker가 자동으로 처리
            : (androidInfo?.version.sdkInt ?? 0) >= 33
                ? await Permission.photos.request()
                : await Permission.storage.request();

        if (!permission.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('이미지를 선택하려면 권한이 필요합니다'),
                action: Platform.isAndroid
                    ? const SnackBarAction(
                        label: '설정',
                        onPressed: openAppSettings,
                      )
                    : null,
              ),
            );
          }
          return;
        }

        final pickedFile = await picker.pickImage(
          source: source,
          maxWidth: 800,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _selectedImagePath = pickedFile.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _contentController.removeListener(() {});
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 사용자의 책 목록을 가져오는 provider 구독
    final booksAsync = ref.watch(userBooksProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '메모 작성',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: booksAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (books) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '책을 선택해주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    onPressed: () => _showBookPicker(books),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedBookId != null
                                ? books
                                    .firstWhere(
                                        (book) => book.id == _selectedBookId)
                                    .title
                                : '선택해주세요',
                            style: TextStyle(
                              color: _selectedBookId != null
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '페이지 숫자를 입력해주세요 (선택사항)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _pageController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: '페이지 숫자 입력',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '이미지를 추가할 수 있어요 (선택사항)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _selectImage,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: _selectedImagePath != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImagePath!),
                                  width: double.infinity,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: () =>
                                      setState(() => _selectedImagePath = null),
                                ),
                              ),
                            ],
                          )
                        : const Center(
                            child: Icon(
                              Icons.add_photo_alternate_outlined,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  '반짝이는 메모 내용을 작성해주세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _contentController,
                  style: const TextStyle(color: Colors.white),
                  maxLength: 200,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: '최대 200자까지 작성 가능해요',
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade800),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade600),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isValid ? _saveMemo : _showValidationError),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isValid
                          ? const Color(0xFF4117EB)
                          : Colors.grey.shade800,
                      foregroundColor:
                          _isValid ? Colors.white : Colors.grey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            '저장하기',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isValid
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveMemo() async {
    await ref.read(analyticsProvider).logButtonClick(
          'memo_save',
          'memo_create_screen',
        );
    setState(() => _isLoading = true);
    try {
      if (_selectedImagePath != null) {
        await ref.read(createMemoWithImageProvider.notifier).createMemo(
              bookId: _selectedBookId!,
              content: _contentController.text,
              imagePath: _selectedImagePath,
              page: int.tryParse(_pageController.text),
            );
      } else {
        await ref.read(createMemoProvider(
          (
            bookId: _selectedBookId!,
            content: _contentController.text,
            page: int.tryParse(_pageController.text),
          ),
        ).future);
      }

      if (mounted) {
        // 메모 저장 후 관련 상태들 갱신
        ref.invalidate(recentMemosProvider);
        ref.invalidate(bookMemosProvider(_selectedBookId!));
        ref.invalidate(homeRecentMemosProvider);
        ref.invalidate(paginatedMemosProvider(_selectedBookId!));
        ref.invalidate(paginatedMemosProvider(null));
        ref.invalidate(recentBooksProvider);

        // 선택된 책의 상세 페이지로 이동
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetailScreen(
              bookId: _selectedBookId!,
            ),
          ),
          (route) => route.isFirst, // 첫 번째 스크린(홈)만 남기고 나머지는 제거
        );

        if (widget.onComplete != null) {
          widget.onComplete!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 저장 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showValidationError() {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _selectedBookId == null ? '책을 선택해주세요' : '메모 내용을 입력해주세요',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFF002912),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
    scaffoldMessenger.showSnackBar(snackBar);
  }

  void _showBookPicker(List<dynamic> books) {
    final FixedExtentScrollController scrollController =
        FixedExtentScrollController(
      initialItem: books.indexWhere((book) => book.id == _selectedBookId),
    );

    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 250,
        color: CupertinoColors.black,
        child: Column(
          children: [
            Container(
              height: 50,
              color: Colors.grey.shade900,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    child: const Text('취소'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.all(8),
                    child: const Text('선택'),
                    onPressed: () async {
                      await ref.read(analyticsProvider).logButtonClick(
                            'select_book',
                            'memo_create_screen',
                          );
                      setState(() {
                        _selectedBookId =
                            books[scrollController.selectedItem].id;
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: scrollController,
                backgroundColor: Colors.black,
                itemExtent: 40,
                children: books
                    .map((book) => Text(
                          book.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ))
                    .toList(),
                onSelectedItemChanged: (_) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isValid => _selectedBookId != null && _hasContent;
}
