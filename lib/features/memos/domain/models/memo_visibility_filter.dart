import 'memo.dart';
import 'memo_visibility.dart';

/// MemoVisibility 필터 타입
/// 
/// memo_list_screen에서 사용하는 필터 옵션
enum MemoVisibilityFilter {
  /// 모든 메모
  all('모든 메모'),
  
  /// 공개 메모만
  public('공개'),
  
  /// 비공개 메모만
  private('비공개');

  final String label;
  const MemoVisibilityFilter(this.label);
}

/// MemoVisibilityFilter 확장 메서드
extension MemoVisibilityFilterExtension on MemoVisibilityFilter {
  /// 메모 리스트를 필터에 따라 필터링
  /// 
  /// [memos] 필터링할 메모 리스트
  /// [currentUserId] 현재 사용자 ID (null 가능)
  /// 
  /// Returns 필터링된 메모 리스트
  /// 
  /// - [MemoVisibilityFilter.all]: 현재 사용자의 모든 메모 반환
  ///   - [currentUserId]가 null인 경우 빈 리스트 반환
  /// - [MemoVisibilityFilter.public]: 현재 사용자의 공개 메모만 반환
  ///   - [currentUserId]가 null인 경우 빈 리스트 반환
  /// - [MemoVisibilityFilter.private]: 현재 사용자의 비공개 메모만 반환
  ///   - [currentUserId]가 null인 경우 빈 리스트 반환
  List<Memo> filterMemos(List<Memo> memos, String? currentUserId) {
    // paginatedMemosProvider가 이미 현재 사용자의 메모만 반환하므로
    // currentUserId 필터링은 불필요하지만, 안전성을 위해 유지
    if (currentUserId == null) return [];
    
    // 먼저 현재 사용자의 메모만 필터링 (안전성 체크)
    final userMemos = memos.where((memo) => memo.userId == currentUserId).toList();
    
    switch (this) {
      case MemoVisibilityFilter.all:
        return userMemos;
      case MemoVisibilityFilter.public:
        return userMemos
            .where((memo) => memo.visibility == MemoVisibility.public)
            .toList();
      case MemoVisibilityFilter.private:
        return userMemos
            .where((memo) => memo.visibility == MemoVisibility.private)
            .toList();
    }
  }
}

