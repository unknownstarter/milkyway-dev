/// 메모 신고 사유 enum
/// 
/// Supabase에는 enum 타입으로 저장되며, Flutter 앱에서도 enum으로 사용
enum ReportReason {
  spam('spam', '스팸/광고'),
  inappropriate('inappropriate', '부적절한 콘텐츠'),
  harassment('harassment', '혐오 발언/괴롭힘'),
  sexual('sexual', '성적 콘텐츠'),
  violence('violence', '폭력적 콘텐츠'),
  copyright('copyright', '저작권 침해'),
  other('other', '기타');

  final String value;
  final String displayName;

  const ReportReason(this.value, this.displayName);

  /// String 값을 ReportReason enum으로 변환
  static ReportReason fromString(String value) {
    return ReportReason.values.firstWhere(
      (reason) => reason.value == value,
      orElse: () => ReportReason.other,
    );
  }

  /// ReportReason enum을 String 값으로 변환
  String toValue() => value;
}

