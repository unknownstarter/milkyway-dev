# 🚨 Milkyway 리팩토링 절대 규칙

> **이 문서는 리팩토링 과정에서 반드시 준수해야 할 규칙입니다.**
> **위반 시 앱의 핵심 기능이 손상될 수 있습니다.**

---

## ❌ 절대 건드리지 말 것 (DO NOT TOUCH)

### 1. 데이터베이스 관련
- ✋ **테이블 구조 변경 금지**
  - users, books, user_books, memos, statistics, app_versions
- ✋ **컬럼 타입/이름 변경 금지**
  - 특히: `status` (읽고 싶은/읽는 중/완독), `visibility` (private/public)
- ✋ **Foreign Key 제약조건 변경 금지**
- ✋ **RLS (Row Level Security) 정책 변경 금지**
- ✋ **Check Constraint 변경 금지**
  - `user_books.status` check constraint
  - enum 타입들

### 2. 인증 & 회원 관리
- ✋ **OAuth 플로우 변경 금지**
  - Google/Apple 로그인 토큰 처리
  - clientId, nonce 생성 로직
- ✋ **onboarding_completed 체크 로직 변경 금지**
- ✋ **auth_provider 구분 로직 변경 금지**
- ✋ **회원 탈퇴 Edge Function 호출 변경 금지**
- ✋ **세션 검증 로직 변경 금지**

### 3. 책 관련 비즈니스 로직
- ✋ **Naver Book API 통신 로직 변경 금지**
  - 검색 파라미터, 응답 파싱
- ✋ **ISBN 중복 체크 로직 변경 금지**
- ✋ **책 상태 변경 로직 변경 금지**
  - '읽고 싶은' → '읽는 중' → '완독' 순서
- ✋ **책-유저 관계 (user_books) 생성 로직 변경 금지**

### 4. 메모 관련 비즈니스 로직
- ✋ **페이지 번호 저장/표시 로직 변경 금지**
- ✋ **visibility (private/public) 정책 변경 금지**
- ✋ **메모 pagination 로직 변경 금지** (limit: 10)
- ✋ **이미지 첨부 로직 변경 금지**

### 5. Supabase 쿼리
- ✋ **SELECT join 구문 변경 금지**
  - books, user_books, memos, users 조인
- ✋ **INSERT/UPDATE/DELETE 로직 변경 금지**
- ✋ **order by, limit, offset 변경 금지**
- ✋ **필터링 조건 (eq, maybeSingle 등) 변경 금지**

### 6. 이미지 & 파일 처리
- ✋ **Supabase Storage 업로드 로직 변경 금지**
  - bucket 이름, 파일명 생성 규칙
  - signed URL 생성
- ✋ **이미지 압축 설정 변경 금지**
  - maxWidth: 800, imageQuality: 80
- ✋ **권한 처리 로직 변경 금지**
  - Camera/Gallery/Photos permission
  - Android SDK 분기 처리

### 7. Validation 규칙
- ✋ **닉네임 검증 규칙 변경 금지**
  - 2-20자, 특수문자 제외
  - 정규식: `RegExp(r'[!@#$%^&*(),.?":{}|<>]')`
- ✋ **기타 폼 검증 로직 변경 금지**

### 8. 앱 정책
- ✋ **app_versions 버전 체크 로직 변경 금지**
- ✋ **force_update 정책 변경 금지**
- ✋ **Firebase Analytics 이벤트 로그 변경 금지**

---

## ✅ 변경 가능한 것 (SAFE TO CHANGE)

### 1. UI & 스타일링
- ✅ **컴포넌트 구조** - 위젯 분리, 재사용
- ✅ **색상, 폰트, 간격** - 디자인 시스템 적용
- ✅ **레이아웃** - padding, margin, radius
- ✅ **애니메이션** - 전환 효과, fade/slide

### 2. 네비게이션
- ✅ **GoRouter 구조** - ShellRoute, named routes
- ✅ **네비게이션 방식** - context.go/pop (로직은 동일)
- ✅ **라우트 파라미터 전달** - extra → pathParameters

### 3. 코드 구조
- ✅ **Provider 파일 위치** - 분리 및 정리
- ✅ **중복 코드 제거** - 서비스 레이어로 추출
- ✅ **에러 타입** - Exception 표준화 (처리 로직 동일)
- ✅ **로깅 방식** - print → AppLogger (출력 내용 동일)

### 4. 파일 구조
- ✅ **폴더 정리** - providers, services 분리
- ✅ **import 정리** - 불필요한 import 제거
- ✅ **asset 정리** - 미사용 파일 삭제

---

## 🔍 변경 전 체크리스트

변경하기 전에 다음을 확인하세요:

1. [ ] DB 쿼리를 수정하고 있나요? → **❌ 금지**
2. [ ] 인증 플로우를 변경하고 있나요? → **❌ 금지**
3. [ ] Validation 규칙을 바꾸고 있나요? → **❌ 금지**
4. [ ] API 통신 로직을 수정하고 있나요? → **❌ 금지**
5. [ ] 이미지 업로드 로직을 변경하고 있나요? → **❌ 금지**
6. [ ] 단순히 UI나 스타일만 바꾸고 있나요? → **✅ 허용**
7. [ ] 중복 코드를 제거하고 있나요? (로직은 동일) → **✅ 허용**
8. [ ] Provider 파일 위치만 변경하고 있나요? → **✅ 허용**

---

## 🚦 리팩토링 원칙

### 원칙 1: 기능 우선
- **기존 기능이 100% 동작해야 합니다**
- UI만 바뀌고, 동작은 동일해야 합니다

### 원칙 2: 점진적 변경
- 한 번에 하나씩 변경합니다
- 변경 후 즉시 테스트합니다

### 원칙 3: 로직 분리
- **비즈니스 로직** (변경 금지) ↔ **UI 로직** (변경 허용)
- 로직을 이동할 때는 100% 동일하게 복사합니다

### 원칙 4: 문서 참조
- 확실하지 않으면 `BUSINESS_LOGIC_POLICY.md` 확인
- DB 변경이 필요하면 `DATABASE_SCHEMA.md` 확인

---

## ⚠️ 경고 사인

다음과 같은 경우 **즉시 중단**하고 재검토하세요:

- 🚨 Supabase 쿼리의 컬럼명을 바꾸고 있음
- 🚨 `status`, `visibility`, `onboarding_completed` 등의 필드를 수정하고 있음
- 🚨 OAuth token 처리 로직을 수정하고 있음
- 🚨 ISBN 체크 로직을 수정하고 있음
- 🚨 페이지 번호, 이미지 URL 저장 로직을 수정하고 있음
- 🚨 권한 체크 분기 로직을 수정하고 있음

---

## 📝 변경 시 기록

중요한 변경을 할 때는 다음을 기록하세요:

```markdown
## [날짜] 변경 내역
- **파일**: path/to/file.dart
- **변경 이유**: UI 개선
- **변경 내용**: 인라인 스타일 → AppColors 사용
- **비즈니스 로직 영향**: 없음
- **테스트 결과**: ✅ 통과
```

---

**마지막 업데이트**: 2025-01-22
**작성자**: 리팩토링 팀
**버전**: 1.0

