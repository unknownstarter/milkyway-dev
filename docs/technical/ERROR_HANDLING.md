# 🚨 에러 처리 및 로깅 가이드

**최종 업데이트:** 2025-11-18  
**버전:** 1.0.0

## 📋 개요

이 문서는 Milkyway 앱의 에러 처리 및 로깅 체계를 설명합니다. 모든 등록, 수정, 삭제 작업에서 발생하는 에러는 일관된 방식으로 처리되고 로깅됩니다.

---

## 🔢 에러 코드 체계

### 에러 코드 넘버링 규칙

에러 코드는 `ERR_XXXX` 형식으로 구성되며, 카테고리별로 번호 범위가 할당됩니다:

| 카테고리 | 코드 범위 | 설명 |
|---------|----------|------|
| **네트워크** | `ERR_1000` ~ `ERR_1999` | 네트워크 연결 관련 오류 |
| **권한** | `ERR_1000` ~ `ERR_1999` | 접근 권한 관련 오류 |
| **업로드** | `ERR_2000` ~ `ERR_2999` | 파일 업로드 관련 오류 |
| **데이터 작업** | `ERR_3000` ~ `ERR_3999` | 저장, 등록, 수정, 삭제 관련 오류 |
| **인증** | `ERR_4000` ~ `ERR_4999` | 인증 및 권한 관련 오류 |
| **서버** | `ERR_5000` ~ `ERR_5999` | 서버 오류 |
| **알 수 없음** | `ERR_9999` | 분류되지 않은 오류 |

### 현재 정의된 에러 코드

| 에러 코드 | 에러 타입 | 설명 | 사용자 메시지 |
|----------|----------|------|--------------|
| `ERR_1001` | `ErrorType.network` | 네트워크 연결 오류 | "네트워크 연결을 확인해주세요" |
| `ERR_1002` | `ErrorType.permission` | 권한 오류 | "접근 권한이 필요합니다" |
| `ERR_2001` | `ErrorType.upload` | 업로드 오류 | "업로드에 실패했습니다" |
| `ERR_3001` | `ErrorType.save` | 저장 오류 | "저장에 실패했습니다" |
| `ERR_3002` | `ErrorType.create` | 등록 오류 | "등록에 실패했습니다" |
| `ERR_3003` | `ErrorType.update` | 수정 오류 | "수정에 실패했습니다" |
| `ERR_3004` | `ErrorType.delete` | 삭제 오류 | "삭제에 실패했습니다" |
| `ERR_4001` | `ErrorType.auth` | 인증 오류 | "인증이 필요합니다" |
| `ERR_5001` | `ErrorType.server` | 서버 오류 | "서버 오류가 발생했습니다" |
| `ERR_9999` | `ErrorType.unknown` | 알 수 없는 오류 | "작업 중 오류가 발생했습니다" |

---

## 📝 로깅 규칙

### 로그 형식

에러 발생 시 다음 형식으로 로그가 기록됩니다:

```
[ErrorHandler] [ERR_XXXX] 작업명 실패
[ErrorHandler] 에러 타입: ErrorType.xxx | 사용자 메시지: xxx
```

### 로그에 포함되는 정보

1. **에러 코드**: `ERR_XXXX` 형식의 고유 코드
2. **작업 이름**: 실패한 작업의 이름 (예: '메모 삭제', '프로필 수정')
3. **에러 객체**: 원본 에러 객체 (스택 트레이스 포함)
4. **에러 타입**: `ErrorType` enum 값
5. **사용자 메시지**: 사용자에게 표시된 친화적인 메시지

### 로그 예시

```dart
// 네트워크 오류 예시
[ErrorHandler] [ERR_1001] 메모 삭제 실패
[ErrorHandler] 에러 타입: ErrorType.network | 사용자 메시지: 네트워크 연결을 확인해주세요

// 삭제 오류 예시
[ErrorHandler] [ERR_3004] 메모 삭제 실패
[ErrorHandler] 에러 타입: ErrorType.delete | 사용자 메시지: 삭제에 실패했습니다

// 권한 오류 예시
[ErrorHandler] [ERR_1002] 프로필 이미지 업로드 실패
[ErrorHandler] 에러 타입: ErrorType.permission | 사용자 메시지: 접근 권한이 필요합니다
```

---

## 🛠️ 사용 방법

### 기본 사용법

```dart
try {
  await someOperation();
} catch (e) {
  if (mounted) {
    ErrorHandler.showError(context, e, operation: '작업명');
  }
}
```

### 커스텀 메시지 사용

```dart
try {
  await uploadImage();
} catch (e) {
  if (mounted) {
    ErrorHandler.showErrorSnackBar(
      context,
      message: '이미지 업로드에 실패했습니다',
      error: e,
      operation: '이미지 업로드',
    );
  }
}
```

### 메시지만 표시 (에러 객체 없음)

```dart
ErrorHandler.showErrorSnackBar(
  context,
  message: '네트워크 연결을 확인해주세요',
);
```

---

## 📱 UI 표시

### 스낵바 스타일

- **배경색**: `Color(0xFF838383)` (회색)
- **텍스트 색상**: `Colors.white`
- **폰트**: `Pretendard`
- **폰트 크기**: `14px`
- **표시 시간**: `2초`
- **위치**: 하단 플로팅 (좌우 여백 20px)

### 사용자 메시지 규칙

- **짧고 명확**: 한 문장으로 요약
- **친화적**: 기술적 용어 지양
- **행동 지향**: 사용자가 할 수 있는 행동 제시
- **일관성**: 동일한 오류는 동일한 메시지

---

## 🔍 에러 타입 자동 감지

`ErrorHandler`는 에러 객체를 분석하여 자동으로 에러 타입을 감지합니다:

### 감지 규칙

1. **네트워크 오류**
   - `SocketException` 인스턴스
   - 에러 메시지에 'network', 'connection', 'internet', 'timeout' 포함

2. **권한 오류**
   - `PlatformException`의 code에 'permission', 'denied', 'access' 포함
   - 에러 메시지에 'permission', '권한', 'denied' 포함

3. **업로드 오류**
   - 에러 메시지에 'upload', '업로드', 'storage' 포함

4. **데이터 작업 오류**
   - 'create', '등록' → `ErrorType.create`
   - 'update', '수정' → `ErrorType.update`
   - 'delete', '삭제' → `ErrorType.delete`
   - 'save', '저장' → `ErrorType.save`

5. **인증 오류**
   - 에러 메시지에 'auth', '인증', 'unauthorized', 'forbidden' 포함

6. **서버 오류**
   - 에러 메시지에 'server', '500', '503' 포함

---

## 📋 적용된 작업 목록

다음 작업들에서 에러 처리가 적용되어 있습니다:

### 메모 관련
- ✅ 메모 삭제 (`memo_detail_screen.dart`)
- ✅ 메모 생성 (`memo_create_screen.dart`)
- ✅ 메모 수정 (`memo_edit_screen.dart`)

### 프로필 관련
- ✅ 프로필 수정 (`profile_edit_screen.dart`)
- ✅ 프로필 이미지 업로드 (`profile_edit_screen.dart`)

### 책 관련
- ✅ 책 등록 (`book_search_screen.dart`)
- ✅ 책 연결 (`book_search_screen.dart`)
- ✅ 책 상태 변경 (`book_detail_screen.dart`)

---

## 🎯 에러 코드 추가 가이드

새로운 에러 타입을 추가할 때:

1. **`ErrorType` enum에 추가**
   ```dart
   enum ErrorType {
     // ... 기존 타입들
     newErrorType, // 새 타입 추가
   }
   ```

2. **`_getErrorCode()` 메서드에 코드 추가**
   ```dart
   case ErrorType.newErrorType:
     return 'ERR_XXXX'; // 적절한 범위의 코드 할당
   ```

3. **`_getErrorType()` 메서드에 감지 로직 추가**
   ```dart
   if (errorString.contains('newError')) {
     return ErrorType.newErrorType;
   }
   ```

4. **`getErrorMessage()` 메서드에 사용자 메시지 추가**
   ```dart
   if (errorString.contains('newError')) {
     return '새로운 오류에 대한 친화적인 메시지';
   }
   ```

5. **이 문서 업데이트**

---

## ⚠️ 주의사항

1. **에러 로깅은 필수**: 모든 에러는 반드시 로그로 기록되어야 합니다.
2. **작업명 명시**: `operation` 파라미터를 명확하게 지정하세요.
3. **사용자 친화적 메시지**: 기술적 에러 메시지를 그대로 표시하지 마세요.
4. **일관성 유지**: 동일한 오류는 동일한 에러 코드와 메시지를 사용하세요.
5. **에러 코드 범위 준수**: 새로운 에러 코드는 정의된 범위 내에서 할당하세요.

---

## 📚 관련 파일

- `lib/core/utils/error_handler.dart`: 에러 핸들러 구현
- `lib/core/errors/failures.dart`: Failure 클래스 정의 (향후 통합 예정)

---

**문서 작성일:** 2025-11-18  
**작성자:** AI Assistant  
**검토자:** 개발팀  
**다음 검토 예정일:** 2025-12-18

