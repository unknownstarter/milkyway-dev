# 책 재등록 캐시 문제 해결 코드 리뷰

**날짜**: 2026-01-02  
**리뷰 대상**: 책 재등록 시 캐시 무효화 및 자동 재시도 로직

---

## 📋 현재 구현 요약

### 1. 캐시 무효화 추가 (`book_register_provider.dart`)
- 책 등록 후 `bookDetailProvider(book.id)` 무효화
- `registerBook`과 `connectExistingBook` 모두에 적용

### 2. 자동 재시도 로직 추가 (`book_detail_provider.dart`)
- PGRST116 에러 발생 시 최대 3회 재시도
- 고정 딜레이 500ms 사용
- 재시도 중에도 로딩 상태 유지

---

## ✅ 잘된 점

### 1. **문제 해결 접근 방식**
- 캐시 무효화와 재시도 로직을 함께 적용하여 이중 안전장치 구성
- 타이밍 이슈를 고려한 재시도 로직

### 2. **에러 타입 체크**
- PGRST116 에러만 재시도하여 불필요한 재시도 방지
- `PostgrestException` 타입 체크로 안전성 확보

### 3. **리소스 정리**
- `dispose()`에서 `Timer` 취소하여 메모리 누수 방지

---

## ⚠️ 개선이 필요한 점

### 1. **재시도 로직의 한계**

#### 문제점
- **고정 딜레이**: 500ms 고정 딜레이로 exponential backoff 미적용
- **재시도 중 UI 상태**: 재시도 중에도 계속 로딩 상태로 보여 사용자 경험 저하
- **기존 유틸리티 미사용**: 프로젝트에 `RetryHelper`가 있지만 활용하지 않음

#### 현재 코드
```dart
static const Duration _retryDelay = Duration(milliseconds: 500);
// ...
_retryTimer = Timer(_retryDelay, () {
  loadBook(isRetry: true);
});
```

#### 개선 방안
- `RetryHelper.retryWithBackoff` 활용 또는 exponential backoff 적용
- 재시도 중에는 에러 상태를 유지하되, 백그라운드에서 재시도

### 2. **에러 처리 범위**

#### 문제점
- PGRST116만 체크하여 다른 관련 에러는 재시도하지 않음
- 예: `user_books` 연결이 아직 완료되지 않은 경우 다른 에러 코드가 발생할 수 있음

#### 개선 방안
- 에러 메시지에 "0 rows" 또는 "not found"가 포함된 경우도 재시도
- 또는 `user_books` 연결 확인 후 재시도

### 3. **캐시 무효화 타이밍**

#### 문제점
- `createUserBookConnection` 직후 바로 invalidate
- DB 트랜잭션 완료 전에 invalidate할 수 있음

#### 현재 코드
```dart
await _repository.createUserBookConnection(existingBook.id, userId);
// ...
_ref.invalidate(bookDetailProvider(book.id)); // 바로 invalidate
```

#### 개선 방안
- `createUserBookConnection`이 완료된 후 invalidate (현재도 이렇게 되어 있음)
- 추가로 약간의 딜레이를 주거나, 재시도 로직으로 보완 (현재 재시도 로직으로 보완됨)

### 4. **재시도 카운트 리셋 로직**

#### 문제점
- `loadBook()` 호출 시 `isRetry == false`면 카운트 리셋
- 하지만 `updateStatus()`에서 `loadBook()` 호출 시에도 리셋됨

#### 현재 코드
```dart
Future<void> loadBook({bool isRetry = false}) async {
  if (!isRetry) {
    _retryCount = 0;
    _retryTimer?.cancel();
  }
  // ...
}
```

#### 개선 방안
- `updateStatus()`에서 호출할 때는 재시도 로직이 필요 없으므로 현재 로직 유지 가능
- 다만 명시적으로 `isRetry: false`를 전달하는 것이 더 명확할 수 있음

---

## 🔧 권장 개선 사항

### 1. Exponential Backoff 적용

```dart
class BookDetailController extends StateNotifier<AsyncValue<Book>> {
  // ...
  static const Duration _initialRetryDelay = Duration(milliseconds: 300);
  static const Duration _maxRetryDelay = Duration(seconds: 2);
  
  Future<void> loadBook({bool isRetry = false}) async {
    if (!isRetry) {
      _retryCount = 0;
      _retryTimer?.cancel();
    }

    state = const AsyncValue.loading();
    try {
      final book = await _repository.getBookDetail(bookId);
      _retryCount = 0;
      state = AsyncValue.data(book);
    } catch (e, st) {
      if (_shouldRetry(e) && _retryCount < _maxRetries) {
        _retryCount++;
        final delay = Duration(
          milliseconds: (_initialRetryDelay.inMilliseconds * 
            (1 << (_retryCount - 1))).clamp(
            0,
            _maxRetryDelay.inMilliseconds,
          ),
        );
        log(
          '책 정보 조회 실패 (재시도 $_retryCount/$_maxRetries, ${delay.inMilliseconds}ms 후): $bookId',
          name: 'BookDetailController',
        );
        _retryTimer = Timer(delay, () {
          loadBook(isRetry: true);
        });
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }
  
  bool _shouldRetry(dynamic error) {
    if (error is PostgrestException) {
      // PGRST116: 0 rows
      // 또는 에러 메시지에 관련 키워드가 포함된 경우
      return error.code == 'PGRST116' ||
          error.message.toLowerCase().contains('0 rows') ||
          error.message.toLowerCase().contains('not found');
    }
    return false;
  }
}
```

### 2. 재시도 중 상태 관리 개선

재시도 중에는 에러 상태를 유지하되, 백그라운드에서 재시도:

```dart
Future<void> loadBook({bool isRetry = false}) async {
  if (!isRetry) {
    _retryCount = 0;
    _retryTimer?.cancel();
    state = const AsyncValue.loading();
  }

  try {
    final book = await _repository.getBookDetail(bookId);
    _retryCount = 0;
    state = AsyncValue.data(book);
  } catch (e, st) {
    if (_shouldRetry(e) && _retryCount < _maxRetries) {
      _retryCount++;
      // 재시도 중에는 에러 상태 유지 (사용자에게는 에러로 보임)
      // 하지만 백그라운드에서 재시도
      if (!isRetry) {
        state = AsyncValue.error(e, st);
      }
      // ... 재시도 로직
    } else {
      state = AsyncValue.error(e, st);
    }
  }
}
```

### 3. `RetryHelper` 활용 고려

프로젝트에 이미 `RetryHelper`가 있으므로, 이를 활용하는 것도 고려할 수 있습니다:

```dart
Future<void> loadBook() async {
  state = const AsyncValue.loading();
  try {
    final book = await RetryHelper.retryWithBackoff<Book>(
      operation: () => _repository.getBookDetail(bookId),
      maxRetries: 3,
      initialDelay: const Duration(milliseconds: 300),
      maxDelay: const Duration(seconds: 2),
      // 하지만 RetryHelper는 네트워크 에러만 재시도하므로
      // PGRST116은 커스텀 로직 필요
    );
    state = AsyncValue.data(book);
  } catch (e, st) {
    // PGRST116은 별도 처리
    if (e is PostgrestException && e.code == 'PGRST116') {
      // 재시도 로직
    } else {
      state = AsyncValue.error(e, st);
    }
  }
}
```

---

## 📊 성능 및 효율성 평가

### ✅ 효율적인 부분
1. **선택적 재시도**: PGRST116만 재시도하여 불필요한 재시도 방지
2. **최대 재시도 제한**: 3회로 제한하여 무한 재시도 방지
3. **리소스 정리**: `dispose()`에서 타이머 취소

### ⚠️ 개선 가능한 부분
1. **고정 딜레이**: Exponential backoff 적용 시 더 효율적
2. **재시도 중 UI**: 사용자 경험 개선 가능

---

## 🎯 최종 평가

### 적절성: ⭐⭐⭐⭐ (4/5)
- 문제 해결 접근 방식은 적절함
- 다만 exponential backoff 미적용으로 효율성 다소 저하

### 효율성: ⭐⭐⭐ (3/5)
- 고정 딜레이 사용으로 효율성 다소 저하
- 재시도 중 UI 상태 관리 개선 필요

### 유지보수성: ⭐⭐⭐⭐ (4/5)
- 코드 구조는 명확함
- 다만 기존 `RetryHelper` 활용 고려 필요

---

## 💡 결론

현재 구현은 **문제를 해결하지만**, 다음과 같은 개선을 권장합니다:

1. **Exponential backoff 적용**: 고정 딜레이 대신 exponential backoff 사용
2. **에러 처리 범위 확대**: PGRST116 외에도 관련 에러 재시도 고려
3. **재시도 중 상태 관리**: 사용자 경험 개선을 위한 상태 관리 개선

하지만 **현재 구현도 충분히 동작하며**, 긴급한 수정이 필요한 것은 아닙니다. 점진적으로 개선하는 것을 권장합니다.
