# Auth Provider 리팩토링 계획 (최종 검토 버전)

**작성일:** 2026-01-02  
**목적:** 클린 아키텍처 준수 및 의존성 분리  
**검토 완료:** ✅

## 🔍 재검토 결과

### 현재 문제점 재분석

#### 1. 순환 의존성 분석
- **실제 순환:** `auth_provider` → `home_loader_provider` (invalidate) ↔ `auth_provider` (read)
- **위험도:** 🟡 중간 (런타임에는 문제 없지만, import 레벨에서 순환)
- **해결 필요성:** ✅ 필요 (코드 구조 개선)

#### 2. Provider 무효화 패턴 분석
현재 코드베이스에서 사용되는 패턴:
- ✅ **같은 Feature 내**: Provider 간 직접 invalidate (예: `memo_provider` 내부)
- ❌ **다른 Feature 간**: `auth_provider`가 다른 feature provider를 직접 invalidate

**개발자 규칙 확인:**
- `DEVELOPER_RULES.md`에 "Provider에서 수정 후 관련 Provider 무효화" 패턴 명시
- 하지만 **같은 feature 내**에서만 권장
- **다른 feature 간** 무효화는 명시적 패턴 없음

#### 3. 실제 사용 패턴
- `authProvider`를 `watch`하는 곳: 8곳 (상태 감지)
- `authProvider.notifier`를 `read`하는 곳: 6곳 (액션 호출)
- `ref.listen(authProvider)` 사용: 1곳 (상태 변화 감지)

## 🎯 최적화된 리팩토링 계획

### 핵심 전략 변경

**기존 계획의 문제점:**
1. Phase 3의 방안들이 모두 복잡함 (Event Bus, Core Service 등)
2. 다른 feature provider 수정이 필요하여 영향도 높음
3. 새로운 패턴 도입으로 인한 학습 곡선

**최적화된 방안:**
- **Phase 3 간소화**: `ref.invalidateSelf()`만 하고, 각 feature provider가 `authProvider` 상태 변화를 감지하여 자체 무효화
- **장점**: 
  - 다른 feature 수정 최소화
  - 기존 패턴 유지 (`ref.listen` 활용)
  - 순환 의존성 제거
  - 구현 단순

---

## 📋 최종 리팩토링 계획

### Phase 1: Repository 확장 (낮은 영향도) ✅ 유지
**목표:** AuthRepository에 필요한 메서드 추가

**작업:**
1. `AuthRepository` 인터페이스에 메서드 추가:
   - `Future<Either<Failure, User?>> getCurrentUser()` (이미 있음, 세션 갱신 로직 포함)
   - `Future<Either<Failure, void>> updateProfile(String? nickname, String? pictureUrl)`
   - `Future<Either<Failure, bool>> checkNicknameAvailability(String nickname)`
   - `Future<Either<Failure, void>> updateOnboardingStatus(bool completed)`
   - `Future<Either<Failure, void>> deleteAccount()`
   - `Future<Either<Failure, void>> refreshSession()`
   - `Future<Either<Failure, void>> handleUserSignIn(User user)` (내부 로직)

2. `AuthRepositoryImpl` 구현
3. `AuthRemoteDataSource` 인터페이스 확장
4. `AuthRemoteDataSourceImpl` 구현

**영향도:** 🟢 낮음 (인터페이스만 추가, 기존 코드 영향 없음)  
**위험도:** 🟢 낮음 (롤백 쉬움)

---

### Phase 2: Provider에서 직접 DB 접근 제거 (중간 영향도) ✅ 유지
**목표:** 모든 Supabase 직접 접근을 Repository로 이동

**작업 순서 (안전한 순서):**
1. `refreshSession()` → Repository 사용 (가장 안전)
2. `getCurrentUser()` → Repository 사용 (핵심 메서드)
3. `_handleUserSignIn()` → Repository 사용
4. `updateProfile()` → Repository 사용
5. `checkNicknameAvailability()` → Repository 사용
6. `updateOnboardingStatus()` → Repository 사용
7. `deleteAccount()` → Repository 사용
8. `signOut()` → Repository 사용 (이미 부분적으로 사용 중)

**영향도:** 🟡 중간 (Provider 메서드 시그니처는 유지, 내부 구현만 변경)  
**위험도:** 🟡 중간 (단계별 테스트 필수)

**테스트 체크리스트:**
- [ ] 로그인/로그아웃 동작
- [ ] 프로필 수정 동작
- [ ] 계정 삭제 동작
- [ ] 온보딩 상태 업데이트
- [ ] 닉네임 중복 체크

---

### Phase 3: 다른 Feature Provider 의존성 제거 (간소화) ⚡ 변경
**목표:** `_clearAllDataProviders()` 의존성 제거

**최적화된 방안: Reactive Invalidation Pattern**

#### 핵심 아이디어
1. `auth_provider`는 `ref.invalidateSelf()`만 수행
2. 각 feature provider가 `authProvider` 상태 변화를 감지하여 자체 무효화
3. `ref.listen` 또는 `ref.watch`를 활용한 반응형 패턴

#### 구현 방법

**Step 1: auth_provider에서 다른 feature import 제거**
```dart
// ❌ 제거
import '../../../books/presentation/providers/user_books_provider.dart';
import '../../../home/presentation/providers/book_provider.dart';
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

예시: `recentMemosProvider`에 추가
```dart
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

**단점:**
- ⚠️ 각 provider에 `ref.watch(authProvider)` 추가 필요
- ⚠️ 약간의 성능 오버헤드 (하지만 무시 가능)

**영향도:** 🟡 중간 (각 feature provider에 한 줄 추가)  
**위험도:** 🟡 중간 (단계별 적용 가능)

**수정 필요한 Provider 목록:**
1. `recentMemosProvider` (memos)
2. `homeRecentMemosProvider` (memos)
3. `allMemosProvider` (memos)
4. `recentBooksProvider` (home)
5. `userBooksProvider` (books)
6. `selectedBookIdProvider` (home) - 특별 처리 필요 (notifier)
7. `homeLoaderProvider` (home) - 이미 authProvider 사용 중
8. `memoListLoaderProvider` (memos)
9. `bookshelfLoaderProvider` (books)

**특별 처리:**
- `selectedBookIdProvider`: `ref.listen(authProvider)` 사용하여 null로 초기화
- `homeLoaderProvider`: 이미 `authProvider` 사용 중이므로 추가 작업 불필요

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

---

## 📊 효율성 분석

### 기존 계획 vs 최적화된 계획

| 항목 | 기존 계획 | 최적화된 계획 | 개선 |
|------|----------|--------------|------|
| Phase 3 복잡도 | 높음 (Event Bus/Core Service) | 낮음 (ref.watch 추가) | ✅ |
| 다른 Feature 수정 | 대규모 | 최소화 (한 줄 추가) | ✅ |
| 학습 곡선 | 높음 (새 패턴) | 낮음 (기존 패턴) | ✅ |
| 구현 시간 | 길음 | 짧음 | ✅ |
| 유지보수성 | 중간 | 높음 | ✅ |

### 예상 작업 시간
- Phase 1: 30분 (인터페이스 확장)
- Phase 2: 2-3시간 (Repository 구현 + Provider 수정)
- Phase 3: 1-2시간 (각 provider에 한 줄 추가)
- **총 예상 시간:** 4-6시간

---

## ✅ 최종 권장 사항

### 진행 순서
1. ✅ **Phase 1** 먼저 진행 (가장 안전)
2. ✅ **Phase 2** 단계별 진행 (테스트 필수)
3. ✅ **Phase 3** 점진적 적용 (한 feature씩)
4. ⚠️ **Phase 4**는 선택적 (Phase 1-3 완료 후 재평가)

### 롤백 전략
- 각 Phase는 독립적으로 롤백 가능
- Git 커밋을 Phase별로 분리
- 문제 발생 시 즉시 이전 Phase로 롤백

### 테스트 전략
- **Phase 1:** 컴파일 확인만
- **Phase 2:** 주요 시나리오 수동 테스트
- **Phase 3:** 각 feature별 수동 테스트

---

## 📝 최종 체크리스트

### Phase 1 완료 후
- [ ] AuthRepository 인터페이스 확장 확인
- [ ] AuthRepositoryImpl 구현 확인
- [ ] AuthRemoteDataSource 인터페이스 확장 확인
- [ ] AuthRemoteDataSourceImpl 구현 확인
- [ ] 컴파일 에러 없음 확인

### Phase 2 완료 후
- [ ] 모든 Supabase 직접 접근 제거 확인
- [ ] 로그인/로그아웃 동작 확인
- [ ] 프로필 수정 동작 확인
- [ ] 계정 삭제 동작 확인
- [ ] 온보딩 상태 업데이트 확인
- [ ] 닉네임 중복 체크 확인

### Phase 3 완료 후
- [ ] 다른 Feature Provider import 제거 확인
- [ ] 로그아웃 시 각 feature provider 자동 무효화 확인
- [ ] 순환 의존성 없음 확인
- [ ] 각 feature별 동작 확인

---

## 🎯 결론

**최적화된 계획이 더 효율적이고 안전합니다:**
- ✅ 복잡도 감소
- ✅ 위험도 감소
- ✅ 구현 시간 단축
- ✅ 유지보수성 향상

**진행 권장:** ✅ Phase 1부터 시작

