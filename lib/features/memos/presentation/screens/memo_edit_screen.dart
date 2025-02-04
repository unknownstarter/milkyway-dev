import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/memo.dart';
import '../providers/memo_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:whatif_milkyway_app/core/providers/analytics_provider.dart';
import 'package:whatif_milkyway_app/core/providers/supabase_client_provider.dart';

class MemoEditScreen extends ConsumerStatefulWidget {
  final Memo memo;

  const MemoEditScreen({
    super.key,
    required this.memo,
  });

  @override
  ConsumerState<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends ConsumerState<MemoEditScreen> {
  late final TextEditingController _contentController;
  late final TextEditingController _pageController;
  bool _isLoading = false;
  String? _selectedImagePath;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.memo.content);
    _pageController = TextEditingController(
      text: widget.memo.page?.toString() ?? '',
    );

    _contentController.addListener(_checkChanges);
    _pageController.addListener(_checkChanges);
    ref.read(analyticsProvider).logScreenView('memo_edit_screen');
  }

  @override
  void dispose() {
    _contentController.removeListener(_checkChanges);
    _pageController.removeListener(_checkChanges);
    _contentController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final contentChanged = _contentController.text != widget.memo.content;
    final pageChanged =
        _pageController.text != (widget.memo.page?.toString() ?? '');

    setState(() {
      _hasChanges = contentChanged || pageChanged || _selectedImagePath != null;
    });
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
                        'memo_edit_screen',
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
                        'memo_edit_screen',
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
            ? await Permission.camera.request()
            : (androidInfo?.version.sdkInt ?? 0) >= 33
                ? await Permission.photos.request()
                : await Permission.storage.request();

        if (!permission.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지를 선택하려면 권한이 필요합니다'),
                action: SnackBarAction(
                  label: '설정',
                  onPressed: () => openAppSettings(),
                ),
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
            _hasChanges = true;
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

  Future<void> _updateMemo() async {
    await ref.read(analyticsProvider).logButtonClick(
          'memo_update',
          'memo_edit_screen',
        );
    setState(() => _isLoading = true);
    try {
      String? imageUrl;
      if (_selectedImagePath != null) {
        // 이미지가 선택되었다면 업로드
        final file = File(_selectedImagePath!);
        final fileName =
            '${ref.read(supabaseClientProvider).auth.currentUser!.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

        // 기존 이미지가 있다면 삭제
        if (widget.memo.imageUrl != null) {
          try {
            final oldFileName = widget.memo.imageUrl!.split('/').last;
            await ref
                .read(supabaseClientProvider)
                .storage
                .from('memo_images')
                .remove([
              '${ref.read(supabaseClientProvider).auth.currentUser!.id}/$oldFileName'
            ]);
          } catch (e) {
            print('기존 이미지 삭제 실패: $e');
          }
        }

        // 새 이미지 업로드
        await ref
            .read(supabaseClientProvider)
            .storage
            .from('memo_images')
            .upload(fileName, file);

        // 이미지 URL 가져오기
        imageUrl = await ref
            .read(supabaseClientProvider)
            .storage
            .from('memo_images')
            .createSignedUrl(fileName, 60 * 60 * 24 * 365); // 1년 유효한 서명된 URL 생성
      }

      await ref.read(updateMemoProvider(
        (
          memoId: widget.memo.id,
          content: _contentController.text,
          page: int.tryParse(_pageController.text),
          bookId: widget.memo.bookId,
          imageUrl: _selectedImagePath == 'remove' ? null : imageUrl,
        ),
      ).future);

      // 메모 수정 완료 시 이벤트 발생
      ref.read(memoUpdateEventProvider.notifier).state = widget.memo.id;

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메모 수정 실패: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.memo.bookTitle} 메모 수정',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                      : widget.memo.imageUrl != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    widget.memo.imageUrl!,
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
                                    onPressed: () => setState(() {
                                      _selectedImagePath = 'remove';
                                      _hasChanges = true;
                                    }),
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
                  onPressed:
                      _isLoading ? null : (_hasChanges ? _updateMemo : null),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChanges
                        ? const Color(0xFF4117EB)
                        : const Color(0xFF1A1A1A),
                    foregroundColor:
                        _hasChanges ? Colors.white : const Color(0xFF666666),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: const Color(0xFF1A1A1A),
                    disabledForegroundColor: const Color(0xFF666666),
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
                          '수정하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _hasChanges
                                ? Colors.white
                                : const Color(0xFF666666),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
