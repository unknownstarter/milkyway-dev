import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  // 로그인 이벤트
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  // 회원가입 완료 이벤트
  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  // 온보딩 완료 이벤트
  Future<void> logOnboardingComplete() async {
    await _analytics.logEvent(
      name: 'onboarding_complete',
    );
  }

  // 책 등록 이벤트
  Future<void> logBookRegistered(String bookId, String title) async {
    await _analytics.logEvent(
      name: 'book_registered',
      parameters: {
        'book_id': bookId,
        'book_title': title,
      },
    );
  }

  // 메모 작성 이벤트
  Future<void> logMemoCreated(String bookId) async {
    await _analytics.logEvent(
      name: 'memo_created',
      parameters: {
        'book_id': bookId,
      },
    );
  }

  // 프로필 업데이트 이벤트
  Future<void> logProfileUpdated() async {
    await _analytics.logEvent(
      name: 'profile_updated',
    );
  }

  // 책 상태 변경 이벤트
  Future<void> logBookStatusChanged(String bookId, String status) async {
    await _analytics.logEvent(
      name: 'book_status_changed',
      parameters: {
        'book_id': bookId,
        'status': status,
      },
    );
  }

  // 페이지 뷰 이벤트
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // 클릭 이벤트
  Future<void> logButtonClick(String buttonName, String screenName) async {
    await _analytics.logEvent(
      name: 'button_click',
      parameters: {
        'button_name': buttonName,
        'screen_name': screenName,
      },
    );
  }
}
