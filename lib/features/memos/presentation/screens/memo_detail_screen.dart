import 'package:flutter/material.dart';
import '../../domain/models/memo.dart';
import '../../../../core/presentation/widgets/star_background_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/full_screen_image_viewer.dart';
import '../../../../core/utils/error_handler.dart';

class MemoDetailScreen extends ConsumerStatefulWidget {
  final String memoId;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
  });

  @override
  ConsumerState<MemoDetailScreen> createState() => _MemoDetailScreenState();
}

class _MemoDetailScreenState extends ConsumerState<MemoDetailScreen> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 처음 나타날 때만 초기화
    if (!_hasInitialized) {
      _hasInitialized = true;
      return;
    }
    // 화면이 다시 나타날 때 (예: 수정 화면에서 돌아올 때) provider 갱신
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(memoProvider(widget.memoId));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final memoAsync = ref.watch(memoProvider(widget.memoId));

    return memoAsync.when(
      data: (memo) {
        // 메모가 삭제되었거나 존재하지 않는 경우 이전 화면으로 이동
        if (memo == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.goNamed(AppRoutes.homeName);
              }
            }
          });
          return Scaffold(
            backgroundColor: const Color(0xFF181818),
            body: const Center(
              child: CircularProgressIndicator(color: Color(0xFFECECEC)),
            ),
          );
        }
        return _buildContent(context, memo);
      },
      loading: () => Scaffold(
        backgroundColor: const Color(0xFF181818),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFECECEC)),
        ),
      ),
      error: (error, stack) => Scaffold(
        backgroundColor: const Color(0xFF181818),
        body: Center(
          child: Text(
            '오류: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, Memo memo) {
    final currentUser = ref.watch(authProvider).value;
    final isOwner = currentUser?.id == memo.userId;

    return StarBackgroundScaffold(
      appBar: AppBar(
        title: MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
          child: const Text('메모'),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoutes.homeName);
            }
          },
        ),
        actions: isOwner
            ? [
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () => _showMemoOptionsBottomSheet(context, memo),
                ),
              ]
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 메모 이미지 (있는 경우) - 정사각형
            if (memo.imageUrl != null && memo.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 32),
              GestureDetector(
                onDoubleTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(
                        imageUrl: memo.imageUrl!,
                      ),
                    ),
                  );
                },
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        memo.imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey.shade900,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFECECEC),
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade900,
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 48,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              const SizedBox(height: 32),
            ],

            // 사용자 정보 (아바타 + 닉네임 + 시간)
            Row(
              children: [
                // 아바타
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade800,
                  ),
                  child: ClipOval(
                    child: memo.userAvatarUrl != null &&
                            memo.userAvatarUrl!.isNotEmpty
                        ? Image.network(
                            memo.userAvatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.person, color: Colors.grey),
                          )
                        : const Icon(Icons.person, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                // 닉네임 및 시간
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        memo.userNickname ?? 'User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        timeago.format(memo.createdAt, locale: 'ko'),
                        style: const TextStyle(
                          color: Color(0xFF838383),
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w300,
                          fontSize: 16,
                          height: 24 / 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // 메모 내용
            Text(
              memo.content,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                height: 24 / 16,
              ),
            ),
            const SizedBox(height: 20),

            // 책 정보 (책 제목 + 페이지)
            Row(
              children: [
                Expanded(
                  child: Text(
                    memo.bookTitle,
                    style: const TextStyle(
                      color: Color(0xFF838383),
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (memo.page != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    'p ${memo.page}',
                    style: const TextStyle(
                      color: Color(0xFF838383),
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w300,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showMemoOptionsBottomSheet(BuildContext context, Memo memo) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '메모 옵션',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final screenHeight = MediaQuery.of(context).size.height;

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          )),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {}, // 바텀시트 내부 탭은 무시
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: screenHeight * 0.3,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF313131),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 닫기 버튼 (X)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C9C9C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: Colors.black,
                            ),
                          ),
                          title: const Text(
                            '수정하기',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _editMemo(context, memo);
                          },
                        ),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9C9C9C),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.black,
                            ),
                          ),
                          title: const Text(
                            '삭제하기',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            _deleteMemo(context, memo);
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _editMemo(BuildContext context, Memo memo) {
    context.pushNamed(
      AppRoutes.memoEditName,
      pathParameters: {'id': memo.id},
    );
  }

  Future<void> _deleteMemo(BuildContext context, Memo memo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
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
        // 서버에 삭제 요청
        await ref.read(deleteMemoProvider(
          (memoId: memo.id, bookId: memo.bookId),
        ).future);
        
        // provider가 무효화되면 memo가 null이 되어 자동으로 화면이 닫힘
        // 추가로 확실하게 화면 닫기
        if (context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.goNamed(AppRoutes.homeName);
          }
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showError(context, e, operation: '메모 삭제');
        }
      }
    }
  }
}
