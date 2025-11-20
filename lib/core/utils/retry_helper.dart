import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;

/// 네트워크 에러 시 자동 재시도를 위한 헬퍼 클래스
class RetryHelper {
  /// 네트워크 에러인지 확인 (외부에서도 사용 가능하도록 public)
  static bool isNetworkError(dynamic error) {
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('failed host lookup');
  }

  /// Exponential backoff를 사용한 재시도 로직
  /// 
  /// [operation] 재시도할 비동기 작업
  /// [maxRetries] 최대 재시도 횟수 (기본값: 3)
  /// [initialDelay] 초기 지연 시간 (기본값: 1초)
  /// [maxDelay] 최대 지연 시간 (기본값: 10초)
  /// 
  /// Returns: 작업 결과 또는 마지막 에러
  static Future<T> retryWithBackoff<T>({
    required Future<T> Function() operation,
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
    Duration maxDelay = const Duration(seconds: 10),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    // 첫 번째 시도 (attempt = 0)
    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (e) {
        // 네트워크 에러가 아니면 재시도하지 않음
        if (!isNetworkError(e)) {
          developer.log(
            '재시도하지 않는 에러: $e',
            name: 'RetryHelper',
          );
          rethrow;
        }

        // 마지막 시도면 에러 throw
        if (attempt >= maxRetries) {
          developer.log(
            '최대 재시도 횟수($maxRetries) 초과: $e',
            name: 'RetryHelper',
          );
          rethrow;
        }

        // Exponential backoff: delay를 2배씩 증가 (최대 maxDelay)
        attempt++;
        developer.log(
          '재시도 $attempt/$maxRetries (${delay.inMilliseconds}ms 후): $e',
          name: 'RetryHelper',
        );
        
        await Future.delayed(delay);
        delay = Duration(
          milliseconds: (delay.inMilliseconds * 2).clamp(
            0,
            maxDelay.inMilliseconds,
          ),
        );
      }
    }

    // 이 코드는 도달하지 않아야 하지만 타입 안전성을 위해 필요
    throw Exception('재시도 로직 오류');
  }
}

