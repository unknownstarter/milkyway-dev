import 'book.dart';
import 'book_status.dart';

/// BookStatus 확장 메서드
/// 
/// 필터링 로직을 enum에 포함하여 확장성과 유지보수성 향상
extension BookStatusExtension on BookStatus? {
  /// 책 리스트를 상태에 따라 필터링
  /// 
  /// [books] 필터링할 책 리스트
  /// 
  /// Returns 필터링된 책 리스트
  /// 
  /// - null: 모든 책 반환 (필터링 없음)
  /// - [BookStatus]: 해당 상태의 책만 반환
  List<Book> filterBooks(List<Book> books) {
    if (this == null) return books;
    return books.where((book) => book.status == this).toList();
  }
}

