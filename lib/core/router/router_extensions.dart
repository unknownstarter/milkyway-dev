import 'package:go_router/go_router.dart';

/// GoRouter 확장 메서드
/// 
/// 타입 안전하고 편리한 네비게이션을 위한 헬퍼 메서드
extension GoRouterStateExtension on GoRouterState {
  /// Query parameter를 boolean으로 안전하게 파싱
  /// 
  /// [key] 쿼리 파라미터 키
  /// [defaultValue] 기본값 (기본: false)
  /// 
  /// Returns: 'true' 문자열이면 true, 그 외는 defaultValue
  bool getBoolQuery(String key, {bool defaultValue = false}) {
    final value = uri.queryParameters[key];
    return value == 'true' ? true : defaultValue;
  }
  
  /// Path parameter를 안전하게 가져오기
  /// 
  /// [key] 경로 파라미터 키
  /// 
  /// Returns: 파라미터 값 또는 null
  String? getPathParam(String key) {
    return pathParameters[key];
  }
  
  /// Path parameter를 필수로 가져오기
  /// 
  /// [key] 경로 파라미터 키
  /// 
  /// Throws: [ArgumentError] if parameter is null
  /// 
  /// Returns: 파라미터 값 (null이 아님)
  String requirePathParam(String key) {
    final value = pathParameters[key];
    if (value == null) {
      throw ArgumentError('Required path parameter "$key" is missing');
    }
    return value;
  }
}

