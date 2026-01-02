# Auth Provider 리팩토링 계획

**작성일:** 2026-01-02  
**목적:** 클린 아키텍처 준수 및 의존성 분리

## 📊 현재 상태 분석

### 1. 의존성 구조

#### auth_provider.dart가 의존하는 것들
- ❌ **직접 Supabase 접근**: 13곳
  - `_supabase.from('users')` - 4곳
  - `_supabase.auth.signOut()` - 2곳
  - `_supabase.auth.currentSession` - 2곳
  - `_supabase.auth.refreshSession()` - 1곳
  - `_supabase.functions.invoke()` - 2곳
  - `_supabase.auth.currentUser` - 2곳

- ❌ **다른 Feature Provider 직접 의존**: 6개
  - `userBooksProvider` (books)
  - `recentBooksProvider` (home)
  - `recentMemosProvider` (memos)
  - `homeRecentMemosProvider` (memos)
  - `allMemosProvider` (memos)
  - `selectedBookIdProvider` (home)
  - `homeLoaderProvider` (home)
  - `memoListLoaderProvider` (memos)
  - `bookshelfLoaderProvider` (books)
  - `paginatedMemosProvider` (memos)

#### auth_provider를 사용하는 파일들: 14개
1. `login_screen.dart` - signInWithGoogle, signInWithApple, getCurrentUser, checkOnboardingStatus
2. `profile_screen.dart` - watch authProvider
3. `profile_edit_screen.dart` - updateProfile, signOut, deleteAccount, checkNicknameAvailability
4. `memo_detail_screen.dart` - watch authProvider (currentUser)
5. `feedback_modal.dart` - read authProvider (user)
6. `nickname_screen.dart` - updateProfile, checkNicknameAvailability
7. `profile_image_screen.dart` - updateProfile
8. `book_intro_screen.dart` - updateOnboardingStatus, getCurrentUser
9. `splash_screen.dart` - checkAppVersion, getCurrentUser
10. `home_empty_states.dart` - watch authProvider
11. `memo_list.dart` - watch authProvider (currentUserId)
12. `user_profile_section.dart` - watch authProvider
13. `home_profile_section.dart` - watch authProvider
14. `home_loader_provider.dart` - getCurrentUser

### 2. 사용되는 메서드 분석

| 메서드 | 사용 횟수 | 사용 위치 | 리팩토링 우선순위 |
|--------|----------|----------|------------------|
| `getCurrentUser()` | 8회 | 여러 화면 | 🔴 높음 |
| `updateProfile()` | 3회 | 프로필 관련 | 🔴 높음 |
| `checkNicknameAvailability()` | 2회 | 닉네임 설정 | 🟡 중간 |
| `signOut()` | 1회 | 프로필 편집 | 🟡 중간 |
| `deleteAccount()` | 1회 | 프로필 편집 | 🟡 중간 |
| `updateOnboardingStatus()` | 2회 | 온보딩 | 🟡 중간 |
| `checkOnboardingStatus()` | 1회 | 로그인 | 🟢 낮음 |
| `signInWithGoogle()` | 1회 | 로그인 | 🟢 낮음 |
| `signInWithApple()` | 1회 | 로그인 | 🟢 낮음 |
| `checkAppVersion()` | 1회 | 스플래시 | 🟢 낮음 |
| `isSignedIn` (getter) | 0회 | - | 🟢 낮음 |
| `currentUserId` (getter) | 1회 | 간접 사용 | 🟢 낮음 |

### 3. 충돌 가능성 분석

#### 🔴 높은 위험도
1. **순환 의존성 위험**
   - `auth_provider` → `home_loader_provider` → `auth_provider` (간접)
   - `auth_provider` → 다른 feature providers → `auth_provider` (간접 가능)

2. **Provider 무효화 의존성**
   - `_clearAllDataProviders()`가 다른 feature의 provider를 직접 invalidate
   - 다른 feature가 변경되면 auth_provider도 수정 필요

3. **직접 DB 접근**
   - Repository 패턴 우회
   - 테스트 어려움
   - 비즈니스 로직 분산

#### 🟡 중간 위험도
1. **세션 관리 로직**
   - `_refreshSessionIfNeeded()`가 Provider 내부에 있음
   - 별도 서비스로 분리 필요

2. **사용자 DB 조작**
   - `_handleUserSignIn()`이 Provider 내부에 있음
   - Repository로 이동 필요

#### 🟢 낮은 위험도
1. **Getter 메서드들**
   - `isSignedIn`, `currentUserId`는 단순 조회
   - 영향도 낮음

## 🎯 리팩토링 목표

1. ✅ Repository 패턴 준수 (모든 DB 접근을 Repository로)
2. ✅ 다른 Feature Provider 의존성 제거
3. ✅ 단일 책임 원칙 준수
4. ✅ 테스트 가능한 구조

## 📋 단계별 리팩토링 계획

### Phase 1: Repository 확장 (낮은 영향도)
**목표:** AuthRepository에 필요한 메서드 추가

**작업:**
1. `AuthRepository` 인터페이스에 메서드 추가:
   - `updateProfile(String? nickname, String? pictureUrl)`
   - `checkNicknameAvailability(String nickname)`
   - `updateOnboardingStatus(bool completed)`
   - `deleteAccount()`
   - `refreshSession()`

2. `AuthRepositoryImpl` 구현
3. `AuthRemoteDataSource` 인터페이스 확장
4. `AuthRemoteDataSourceImpl` 구현

**영향도:** 🟢 낮음 (인터페이스만 추가, 기존 코드 영향 없음)

---

### Phase 2: Provider에서 직접 DB 접근 제거 (중간 영향도)
**목표:** 모든 Supabase 직접 접근을 Repository로 이동

**작업:**
1. `getCurrentUser()` → Repository 사용
2. `_refreshSessionIfNeeded()` → Repository 사용
3. `_handleUserSignIn()` → Repository 사용
4. `updateProfile()` → Repository 사용
5. `checkNicknameAvailability()` → Repository 사용
6. `updateOnboardingStatus()` → Repository 사용
7. `deleteAccount()` → Repository 사용
8. `signOut()` → Repository 사용 (이미 부분적으로 사용 중)

**영향도:** 🟡 중간 (Provider 메서드 시그니처는 유지, 내부 구현만 변경)

---

### Phase 3: 다른 Feature Provider 의존성 제거 (간소화) ⚡ 최적화
**목표:** `_clearAllDataProviders()` 의존성 제거

**최적화된 방안: Reactive Invalidation Pattern**

#### 핵심 아이디어
1. `auth_provider`는 `ref.invalidateSelf()`만 수행
2. 각 feature provider가 `authProvider` 상태 변화를 감지하여 자체 무효화
3. `ref.watch(authProvider)`를 활용한 반응형 패턴

#### 구현 방법
**Step 1: auth_provider에서 다른 feature import 제거**
```dart
// ❌ 제거
import '../../../books/presentation/providers/user_books_provider.dart';
// ... 등등

// ✅ _clearAllDataProviders() 제거
Future<void> signOut() async {
  try {
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidateSelf(); // 자기 자신만 무효화
  } catch (e, st) {
    state = AsyncValue.error(e, st);
  }
}
```

**Step 2: 각 Feature Provider에 auth 상태 감지 추가**
```dart
// 예시: recentMemosProvider
final recentMemosProvider = FutureProvider<List<Memo>>((ref) async {
  // authProvider 상태 감지 (로그아웃 시 자동 무효화)
  ref.watch(authProvider);
  
  final repository = ref.watch(memoRepositoryProvider);
  return repository.getRecentMemos();
});
```

**장점:**
- ✅ 순환 의존성 완전 제거
- ✅ 각 feature가 자체 책임 관리
- ✅ 기존 패턴 활용 (`ref.watch`)
- ✅ 다른 feature 수정 최소화 (각 provider에 한 줄 추가)

**영향도:** 🟡 중간 (각 feature provider에 한 줄 추가, 기존: 🔴 높음 → 개선됨)

**수정 필요한 Provider 목록:**
1. `recentMemosProvider`, `homeRecentMemosProvider`, `allMemosProvider` (memos)
2. `recentBooksProvider`, `userBooksProvider` (books/home)
3. `selectedBookIdProvider` (home) - 특별 처리: `ref.listen` 사용
4. `memoListLoaderProvider`, `bookshelfLoaderProvider` (loaders)

---

### Phase 4: 책임 분리 (선택적) ⚠️ 재검토
**목표:** 세션 관리, 프로필 관리를 별도로 분리

**재검토 결과:**
- ❌ **불필요한 복잡도 증가**
- ✅ **현재 구조 유지 권장**
- 이유:
  - Repository로 이동하면 이미 책임이 분리됨
  - 별도 Service 추가는 오버엔지니어링
  - Provider는 얇은 레이어로 유지 가능

**결론:** Phase 4는 **선택적**이며, Phase 1-3 완료 후 필요성 재평가

**영향도:** 🟢 낮음 (선택적이므로)

---

## ⚠️ 위험성 재평가

### Phase 1 위험도: 🟢 낮음
- 인터페이스만 추가
- 기존 코드 영향 없음
- 롤백 쉬움

### Phase 2 위험도: 🟡 중간
- **주요 위험:** `getCurrentUser()` 변경 시 영향도 높음 (8곳 사용)
- **완화 방안:** 
  - 메서드 시그니처 유지
  - 단계별 테스트
  - Repository 구현 완료 후 Provider 수정

### Phase 3 위험도: 🟡 중간 (기존: 🔴 높음 → 개선됨)
- **기존 계획:** 다른 feature 대규모 수정 필요
- **개선된 계획:** 각 provider에 한 줄 추가
- **완화 방안:**
  - 한 번에 하나씩 적용
  - 각 feature별로 테스트
  - 문제 발생 시 즉시 롤백

### Phase 4 위험도: 🟢 낮음 (선택적)
- 선택적이므로 위험도 낮음

## ⚠️ 주의사항

### 1. 하위 호환성 유지
- Provider의 public 메서드 시그니처는 변경하지 않음
- 기존 사용처(14개 파일)는 수정 불필요

### 2. 점진적 리팩토링
- 한 번에 하나씩 진행
- 각 Phase 완료 후 테스트
- 문제 발생 시 즉시 롤백 가능하도록

### 3. 테스트 전략
- **Phase 1:** 컴파일 확인만
- **Phase 2:** 주요 시나리오 수동 테스트 (로그인, 로그아웃, 프로필 수정, 계정 삭제)
- **Phase 3:** 각 feature별 수동 테스트

### 4. 롤백 전략
- 각 Phase는 독립적으로 롤백 가능
- Git 커밋을 Phase별로 분리
- 문제 발생 시 즉시 이전 Phase로 롤백

## 📝 체크리스트

### Phase 1 완료 후
- [ ] AuthRepository 인터페이스 확장 확인
- [ ] AuthRepositoryImpl 구현 확인
- [ ] 기존 코드 동작 확인 (변경 없음)

### Phase 2 완료 후
- [ ] 모든 Supabase 직접 접근 제거 확인
- [ ] 로그인/로그아웃 동작 확인
- [ ] 프로필 수정 동작 확인
- [ ] 계정 삭제 동작 확인

### Phase 3 완료 후
- [ ] 다른 Feature Provider import 제거 확인
- [ ] 로그아웃 시 캐시 초기화 동작 확인
- [ ] 순환 의존성 없음 확인

### Phase 4 완료 후
- [ ] 세션 관리 서비스 분리 확인
- [ ] 프로필 관리 서비스 분리 확인
- [ ] Provider 책임 명확화 확인

