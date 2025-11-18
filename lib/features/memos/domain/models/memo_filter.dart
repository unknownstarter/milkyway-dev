import 'memo.dart';
import 'memo_visibility.dart';

/// 메모 필터 enum
/// 
/// UI에서 메모 필터링에 사용
enum MemoFilter {
  /// 내가 쓴 메모만
  myMemos('내가 쓴'),
  
  /// 모든 메모 (책 상세 화면에서는 공개 메모만 표시)
  all('모든 메모');

  final String label;
  const MemoFilter(this.label);
}

/// MemoFilter 확장 메서드
/// 
/// 필터링 로직을 enum에 포함하여 확장성과 유지보수성 향상
extension MemoFilterExtension on MemoFilter {
  /// 메모 리스트를 필터에 따라 필터링
  /// 
  /// [memos] 필터링할 메모 리스트
  /// [currentUserId] 현재 사용자 ID (myMemos 필터 사용 시 필요, null 가능)
  /// 
  /// Returns 필터링된 메모 리스트
  /// 
  /// - [MemoFilter.myMemos]: 현재 사용자가 작성한 메모만 반환
  ///   - [currentUserId]가 null인 경우 빈 리스트 반환
  /// - [MemoFilter.all]: 공개 메모만 반환 (책 상세 화면에서 사용)
  List<Memo> filterMemos(List<Memo> memos, String? currentUserId) {
    switch (this) {
      case MemoFilter.myMemos:
        if (currentUserId == null) return [];
        return memos.where((memo) => memo.userId == currentUserId).toList();
      case MemoFilter.all:
        // 책 상세 화면의 "모든 메모" 필터에서는 공개 메모만 표시
        return memos
            .where((memo) => memo.visibility == MemoVisibility.public)
            .toList();
    }
  }
}

