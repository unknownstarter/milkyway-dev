/// 메모 공개 여부 enum
/// 
/// Supabase에는 enum 타입으로 저장되며, Flutter 앱에서도 enum으로 사용
enum MemoVisibility {
  /// 비공개
  private('private'),
  
  /// 공개
  public('public');

  final String value;
  const MemoVisibility(this.value);

  /// String 값을 MemoVisibility enum으로 변환
  /// 
  /// DB에서 읽을 때 사용
  /// 알 수 없는 값인 경우 기본값(private) 반환
  static MemoVisibility fromString(String? value) {
    if (value == null) return MemoVisibility.private;
    return MemoVisibility.values.firstWhere(
      (visibility) => visibility.value == value,
      orElse: () => MemoVisibility.private,
    );
  }

  /// MemoVisibility enum을 String 값으로 변환
  /// 
  /// DB에 저장할 때 사용
  String toJson() => value;
}

