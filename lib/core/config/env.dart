// 환경 변수를 관리할 클래스 생성
class Env {
  static const naverClientId = String.fromEnvironment('NAVER_CLIENT_ID');
  static const naverClientSecret =
      String.fromEnvironment('NAVER_CLIENT_SECRET');
}
