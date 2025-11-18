# 코드 리뷰 결과

## 🔴 심각한 문제

### 1. 네비게이션 패턴 불일치
**문제**: 문자열 경로를 직접 사용하는 코드가 40+ 곳에 존재
```dart
// ❌ 나쁜 예
context.push('/memos/detail/${memo.id}');
context.push('/books/detail/${book.id}');
context.go('/home');
```

**영향**: 
- 타입 안전성 부족
- 경로 변경 시 런타임 오류 가능
- 리팩토링 어려움

**권장**:
```dart
// ✅ 좋은 예
context.pushNamed(
  AppRoutes.memoDetailName,
  pathParameters: {'id': memo.id},
);
```

### 2. 중복 라우트 정의
**문제**: `memoCreate`가 ShellRoute 안과 밖에 중복 정의
```dart
// ShellRoute 밖 (line 87-96)
GoRoute(
  path: AppRoutes.memoCreate,
  name: '${AppRoutes.memoCreateName}-standalone',  // ❌ 다른 이름
  ...
)

// ShellRoute 안 (line 166-175)
GoRoute(
  path: AppRoutes.memoCreate,
  name: AppRoutes.memoCreateName,  // ❌ 같은 경로, 다른 이름
  ...
)
```

**영향**: 라우트 충돌 가능성, 혼란

## 🟡 개선 필요

### 3. QueryParameters 파싱 반복
**문제**: `== 'true'` 비교가 반복됨
```dart
// 반복되는 패턴
final isFromOnboarding = state.uri.queryParameters['isFromOnboarding'] == 'true';
final isFromRegistration = state.uri.queryParameters['isFromRegistration'] == 'true';
```

**개선안**: 헬퍼 메서드 추가
```dart
extension GoRouterStateExtension on GoRouterState {
  bool getBoolQuery(String key, {bool defaultValue = false}) {
    return uri.queryParameters[key] == 'true' ? true : defaultValue;
  }
}
```

### 4. Null Assertion 남용
**문제**: `pathParameters['id']!` 같은 강제 언래핑
```dart
bookId: state.pathParameters['id']!,  // ❌ 런타임 오류 가능
```

**개선안**: 안전한 파싱
```dart
final bookId = state.pathParameters['id'];
if (bookId == null) {
  // 에러 처리 또는 기본값
  return ErrorScreen();
}
```

### 5. 라우트 이름 일관성 부족
**문제**: 
- `memo-create-standalone` vs `memo-create`
- 일부는 named routes, 일부는 문자열 경로

## 🟢 잘된 점

1. ✅ `AppRoutes` 클래스로 경로 중앙 관리
2. ✅ Named routes 지원 구조
3. ✅ ShellRoute로 BottomNavigationBar 통합
4. ✅ Deprecated 표시로 마이그레이션 가이드 제공

## ✅ 적용된 개선 사항

### 1. 타입 안전성 강화
- ✅ `router_extensions.dart` 추가: `getBoolQuery()`, `requirePathParam()` 헬퍼 메서드
- ✅ Null assertion 제거: `pathParameters['id']!` → `requirePathParam('id')`
- ✅ QueryParameters 파싱 개선: `== 'true'` → `getBoolQuery()`

### 2. 중복 라우트 정리
- ✅ `memoCreate` 라우트 이름 통일
- ✅ 주석으로 ShellRoute 안/밖 구분 명확화

## 📋 남은 개선 사항

### 우선순위 1: 네비게이션 패턴 통일 (40+ 파일)
- 모든 `context.push('/path')` → `context.pushNamed()`로 변경
- 모든 `context.go('/path')` → `context.goNamed()`로 변경
- 예시:
  ```dart
  // ❌ 변경 전
  context.push('/memos/detail/${memo.id}');
  
  // ✅ 변경 후
  context.pushNamed(
    AppRoutes.memoDetailName,
    pathParameters: {'id': memo.id},
  );
  ```

### 우선순위 2: 코드 일관성
- 라우트 이름 규칙 통일
- 네비게이션 메서드 선택 기준 명확화 (`push` vs `go`)

## 📊 개선 효과

### Before
- ❌ 런타임 오류 가능성 (null assertion)
- ❌ 반복적인 코드 (query parameter 파싱)
- ❌ 타입 안전성 부족

### After
- ✅ 컴파일 타임 안전성 (requirePathParam)
- ✅ 코드 재사용성 향상 (헬퍼 메서드)
- ✅ 유지보수성 개선 (중앙화된 라우트 관리)

