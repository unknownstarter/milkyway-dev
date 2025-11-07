<!-- d00321b4-dd0b-4574-90a9-eeb475841eaa 88c77e5a-ee0e-445e-a213-1abb3c96720c -->
# 코어 중심 복구 계획

## 근본 원인

1. **GoRouter와 Navigator.push 혼용** (14개 파일, 43곳)
2. **ShellRoute 오작동** (`state.location` → `state.uri.toString()`)
3. **신규 파일들이 기존 코드와 완전 분리**

## 핵심 원칙

- 단순명료한 코드
- 일관된 패턴
- 목적별 명확한 모듈화
- 복잡한 로직 없이 작동하는 앱

---

## Phase 1: 네비게이션 통일 (가장 중요)

### 목표

모든 화면 이동을 GoRouter로 통일하여 스택 관리 문제 해결

### 1-1. Navigator 사용처 전수조사

**파일**: 14개 파일

```bash
# 모든 Navigator.push/pop을 찾아서
lib/features/memos/presentation/screens/memo_edit_screen.dart (4곳)
lib/features/memos/presentation/screens/memo_detail_screen.dart (4곳)
lib/features/books/presentation/screens/book_search_screen.dart (3곳)
...등
```

### 1-2. 패턴 통일

**기존 (잘못됨)**:

```dart
Navigator.push(context, MaterialPageRoute(
  builder: (context) => MemoDetailScreen(memo: memo),
));
```

**수정 후 (올바름)**:

```dart
context.push('/memos/${memo.id}');
```

### 1-3. ShellRoute 수정

**파일**: `lib/core/router/app_router.dart`

```dart
ShellRoute(
  builder: (context, state, child) => MainShell(
    location: state.uri.toString(), // 수정
    child: child,
  ),
  routes: [...],
)
```

---

## Phase 2: 데이터 흐름 정리

### 목표

Provider와 Repository를 명확히 분리, 중복 제거

### 2-1. 현재 문제

- `recentBooksProvider` vs `home_loader_provider` (중복)
- `BookRepository` 2개 (books/, home/)
- `MemoRepository` 삭제되었지만 참조 남아있음

### 2-2. 해결

```
lib/features/
  books/
    data/
      repositories/
        book_repository.dart  (책 CRUD - 등록/수정/삭제)
  home/
    data/
      repositories/
        book_repository.dart  (홈 화면용 - 최근 책 조회만)
        (memo_repository 삭제됨 - memos/로 통합)
```

**원칙**:

- 각 Repository는 **하나의 명확한 책임**만
- Provider는 **UI 상태만 관리**
- 비즈니스 로직은 Repository에

---

## Phase 3: 화면별 최소 복구

### 목표

각 화면이 **최소한의 기능**으로 작동하게

### 3-1. MemoDetailScreen

**문제**: `memoId` 받지만 데이터 로딩 안함

**해결**:

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final memoAsync = ref.watch(memoProvider(memoId));
  return memoAsync.when(
    data: (memo) => StarBackgroundScaffold(...),
    loading: () => Scaffold(body: Center(child: CircularProgressIndicator())),
    error: (e, st) => Scaffold(body: Center(child: Text('오류'))),
  );
}
```

### 3-2. HomeScreen

**문제**: 인증/데이터 로딩 로직 삭제됨

**해결**: git diff로 삭제된 코드 확인 후 **필수 로직만** 복원

- 인증 체크
- 데이터 리프레시
- 자동 네비게이션 (있었다면)

### 3-3. 다른 화면들

BookShelf, MemoList, Profile → 동일 패턴

---

## Phase 4: 불필요한 파일 정리

### 삭제 대상

```
lib/core/presentation/widgets/
  animations/ (현재 미사용)
  buttons/ (현재 미사용)
  dialogs/ (현재 미사용)
  images/ (현재 미사용)
  inputs/ (현재 미사용)
  layout/ (현재 미사용)
  states/ (현재 미사용)
  
lib/core/services/
  image_picker_service.dart (기존 코드와 미연결)
  permission_service.dart (기존 코드와 미연결)
  storage_service.dart (기존 코드와 미연결)
```

**원칙**:

- **사용하지 않는 코드는 모두 삭제**
- **필요할 때 하나씩 추가**

---

## Phase 5: 디자인 시스템 (나중에)

### 현재는 보류

- app_colors.dart
- app_typography.dart
- app_spacing.dart

**이유**:

- 먼저 **앱이 작동**해야 함
- 디자인은 **작동 확인 후** 점진적으로 적용

---

## 실행 순서

1. **Navigator → GoRouter 전환** (30분)

   - 14개 파일, 43곳 수정
   - 패턴 통일

2. **ShellRoute 수정** (5분)

   - state.location → state.uri.toString()

3. **MemoDetailScreen/EditScreen 복구** (20분)

   - memoId로 데이터 로딩 추가

4. **HomeScreen 복구** (30분)

   - git diff 확인
   - 삭제된 핵심 로직만 복원

5. **앱 실행 테스트** (10분)

   - 기본 흐름 확인: 로그인 → 홈 → 책 검색 → 메모

6. **다른 화면 복구** (각 20분)

   - BookShelf, MemoList, Profile

7. **불필요한 파일 삭제** (10분)

   - 미사용 컴포넌트/서비스 정리

---

## 성공 기준

1. ✅ 모든 화면이 GoRouter로만 이동
2. ✅ BottomNav 클릭 시 화면 전환 정상 작동
3. ✅ 뒤로가기 버튼 정상 작동
4. ✅ 로그인 → 책 등록 → 메모 작성 플로우 정상
5. ✅ 불필요한 파일 없음

---

## 이 계획의 장점

- **단순명료**: Navigator → GoRouter로 통일
- **일관성**: 모든 화면 이동이 같은 패턴
- **명확한 책임**: 각 모듈이 하나의 역할만
- **점진적**: 작동 → 개선 → 최적화 순서
- **불필요한 것 제거**: 사용 안 하는 코드 삭제

### To-dos

- [ ] 색상 팔레트 정의 (검정/그레이 + 형광초록)
- [ ] Pretendard 타이포그래피 시스템
- [ ] Spacing & Layout (20px 패딩, 12px radius)
- [ ] AppStrings, AppDurations, AppLimits 정의
- [ ] Material Theme 3 재작성
- [ ] 버튼 컴포넌트 라이브러리
- [ ] 레이아웃 컴포넌트 (Scaffold, Card, Section)
- [ ] 상태 위젯 (Loading, Error, Empty)
- [ ] 입력 컴포넌트 + Validators
- [ ] 이미지 컴포넌트 (CachedImage, BookCover, Avatar)
- [ ] 다이얼로그 & 모달 & SnackBar
- [ ] 애니메이션 위젯
- [ ] Validators 유틸리티
- [ ] Formatters (날짜, timeAgo)
- [ ] ImageUtils (업로드, picker)
- [ ] AppLogger 구현
- [ ] GoRouter 라우트 재설계
- [ ] MainShell 구현 (BottomNav 통합)
- [ ] AppRoutes helper
- [ ] Repository 통합 및 인터페이스 분리
- [ ] Provider 패턴 통일 (@riverpod)
- [ ] 에러 처리 강화 (AppException)
- [ ] HomeScreen 리팩토링
- [ ] BookShelfScreen 리팩토링
- [ ] MemoListScreen 리팩토링
- [ ] BookDetailScreen 리팩토링
- [ ] MemoDetailScreen 리팩토링
- [ ] ProfileScreen 리팩토링
- [ ] Login & Onboarding 화면 리팩토링
- [ ] Provider 최적화 (select, keepAlive)
- [ ] 이미지 최적화 통합
- [ ] 리스트 최적화
- [ ] PaytoneOne 폰트 및 미사용 asset 정리
- [ ] 전체 플로우 테스트 및 버그 수정