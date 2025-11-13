/// 책 읽기 상태 enum
/// 
/// Supabase에는 String으로 저장되며, Flutter 앱에서만 enum으로 사용
enum BookStatus {
  /// 읽고 싶은
  wantToRead('읽고 싶은'),
  
  /// 읽는 중
  reading('읽는 중'),
  
  /// 완독
  completed('완독');

  final String value;
  const BookStatus(this.value);

  /// String 값을 BookStatus enum으로 변환
  /// 
  /// DB에서 읽을 때 사용
  /// 알 수 없는 값인 경우 기본값(wantToRead) 반환
  /// [value]가 null인 경우 기본값(wantToRead) 반환
  static BookStatus fromString(String? value) {
    if (value == null) return BookStatus.wantToRead;
    return BookStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BookStatus.wantToRead,
    );
  }

  /// BookStatus enum을 String 값으로 변환
  /// 
  /// DB에 저장할 때 사용
  String toJson() => value;
}

