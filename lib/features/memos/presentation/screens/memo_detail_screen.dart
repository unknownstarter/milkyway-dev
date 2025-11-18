import 'package:flutter/material.dart';
import '../../domain/models/memo.dart';
import '../../../../core/presentation/widgets/star_background_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_routes.dart';

class MemoDetailScreen extends ConsumerWidget {
  final String memoId;

  const MemoDetailScreen({
    super.key,
    required this.memoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(memoProvider(memoId));

    return memoAsync.when(
      data: (memo) => _buildContent(context, ref, memo),
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

  Widget _buildContent(BuildContext context, WidgetRef ref, Memo memo) {
    return StarBackgroundScaffold(
      appBar: AppBar(
        title: const Text('메모'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 메모 이미지 (있는 경우)
            if (memo.imageUrl != null && memo.imageUrl!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                height: 200,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
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
            ],
            
            // 메모 내용
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                memo.content,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 메모 정보
            Row(
              children: [
                Icon(
                  Icons.book,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  memo.bookTitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(memo.createdAt),
                    style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // 액션 버튼들
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editMemo(context, memo),
                    icon: const Icon(Icons.edit),
                    label: const Text('수정'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _deleteMemo(context, ref, memo),
                    icon: const Icon(Icons.delete),
                    label: const Text('삭제'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.2),
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
              ),
            ],
          ),
        ),
    );
  }

  void _editMemo(BuildContext context, Memo memo) {
    context.pushNamed(
      AppRoutes.memoEditName,
      pathParameters: {'id': memo.id},
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _deleteMemo(BuildContext context, WidgetRef ref, Memo memo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
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
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      try {
        await ref.read(deleteMemoProvider(
          (memoId: memo.id, bookId: memo.bookId),
        ).future);
        
        if (context.mounted) {
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('메모 삭제 실패: $e'),
              backgroundColor: const Color(0xFF242424),
            ),
          );
        }
      }
    }
  }
}