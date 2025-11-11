import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import '../../firebase_options.dart';

class FirebaseService {
  static FirebaseAnalytics? _analytics;
  static FirebaseAnalyticsObserver? _observer;
  static bool _isInitialized = false;

  static FirebaseAnalytics? get analytics => _analytics;
  static FirebaseAnalyticsObserver? get observer => _observer;
  static bool get isInitialized => _isInitialized;

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics!);
      _isInitialized = true;
      print('✅ Firebase 초기화 완료');
      
      // 개발 모드에서 Analytics 자동 수집 설정 (선택적)
      // 시뮬레이터나 네트워크 불안정 환경에서 에러 로그 감소
      if (_analytics != null) {
        await _analytics!.setAnalyticsCollectionEnabled(true);
      }
    } catch (e) {
      print('⚠️ Firebase 초기화 실패 (계속 진행): $e');
      _isInitialized = false;
      // Firebase가 없어도 앱은 계속 실행되도록 함
    }
  }
}
