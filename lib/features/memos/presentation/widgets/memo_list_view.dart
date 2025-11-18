import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memo_provider.dart';
import '../../domain/models/memo.dart';
import '../../domain/models/memo_filter.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'book_detail_memo_card.dart';
import '../../../../core/presentation/widgets/pill_filter_button.dart';

/// 책 상세 화면에서 사용하는 메모 리스트 뷰
/// 
/// - [bookId]가 제공되면: 특정 책의 메모만 표시 (book_detail_screen용)
/// - 필터링, 로딩, 에러, 빈 상태 처리 포함
/// - 필터링 결과 메모이제이션으로 성능 최적화
class MemoListView extends ConsumerStatefulWidget {
  final String bookId;
  final bool showFilterButtons;

  const MemoListView({
    super.key,
    required this.bookId,
    this.showFilterButtons = true,
  });

  @override
  ConsumerState<MemoListView> createState() => _MemoListViewState();
}

class _MemoListViewState extends ConsumerState<MemoListView> {
  MemoFilter _selectedFilter = MemoFilter.myMemos;
  
  // 필터링 결과 메모이제이션
  List<Memo>? _cachedFilteredMemos;
  MemoFilter? _cachedFilter;
  int? _cachedMemosLength;
  String? _cachedUserId;

  @override
  Widget build(BuildContext context) {
    // bookId가 필수이므로 bookMemosProvider 사용
    final memosAsyncValue = ref.watch(bookMemosProvider(widget.bookId));
    
    final currentUserId = ref.watch(authProvider).value?.id;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 반응형: 화면 너비에서 양쪽 20px씩 제외한 카드 너비
        final cardWidth = constraints.maxWidth - 40;
        
        return memosAsyncValue.when(
          data: (memos) {
            // 필터링된 메모 (메모이제이션 적용)
            final filteredMemos = _getFilteredMemos(memos, currentUserId);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 필터 버튼 (showFilterButtons가 true일 때만 표시, 항상 표시)
                if (widget.showFilterButtons) ...[
                  _buildMemoFilter(),
                  const SizedBox(height: 32),
                ],
                // 메모 리스트 또는 빈 상태
                if (filteredMemos.isEmpty)
                  _buildEmptyMemos()
                else
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      bottom: 8, // 메모하기 버튼과 겹치지 않도록 최소 여백만 유지
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: filteredMemos
                          .map((memo) => BookDetailMemoCard(
                                memo: memo,
                                cardWidth: cardWidth,
                              ))
                          .toList(),
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFECECEC),
              ),
            ),
          ),
          error: (error, stack) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '메모를 불러올 수 없습니다: $error',
              style: const TextStyle(
                color: Colors.red,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        );
      },
    );
  }

  /// 필터링된 메모 반환 (메모이제이션 적용)
  List<Memo> _getFilteredMemos(List<Memo> memos, String? currentUserId) {
    // 캐시가 유효한지 확인 (리스트 길이로 비교하여 참조 비교 문제 해결)
    if (_cachedFilteredMemos != null &&
        _cachedFilter == _selectedFilter &&
        _cachedMemosLength == memos.length &&
        _cachedUserId == currentUserId) {
      return _cachedFilteredMemos!;
    }

    // 필터링 실행
    final filtered = _selectedFilter.filterMemos(memos, currentUserId);

    // 캐시 업데이트
    _cachedFilteredMemos = filtered;
    _cachedFilter = _selectedFilter;
    _cachedMemosLength = memos.length;
    _cachedUserId = currentUserId;

    return filtered;
  }

  /// 필터 변경 및 캐시 무효화
  void _updateFilter(MemoFilter filter) {
    setState(() {
      _selectedFilter = filter;
      // 필터 변경 시 캐시 무효화
      _cachedFilteredMemos = null;
      _cachedFilter = null;
      _cachedMemosLength = null;
      _cachedUserId = null;
    });
  }

  Widget _buildMemoFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          PillFilterButton(
            label: MemoFilter.myMemos.label,
            isActive: _selectedFilter == MemoFilter.myMemos,
            onTap: () => _updateFilter(MemoFilter.myMemos),
            width: 90,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
          const SizedBox(width: 12),
          PillFilterButton(
            label: MemoFilter.all.label,
            isActive: _selectedFilter == MemoFilter.all,
            onTap: () => _updateFilter(MemoFilter.all),
            width: 104,
            fontSize: 16,
            activeFontWeight: FontWeight.w400,
            inactiveFontWeight: FontWeight.w400,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMemos() {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 120, // 메모하기 버튼(41px) + 상하 padding(40px) + 여유 공간(39px)
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.note_add,
              color: Colors.grey,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              '아직 메모가 없습니다',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '첫 번째 메모를 작성해보세요',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

