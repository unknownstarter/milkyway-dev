# 📋 Milkyway 비즈니스 로직 정책

> **이 문서는 앱의 핵심 비즈니스 로직을 정의합니다.**
> **모든 변경은 이 정책을 기준으로 검토되어야 합니다.**

---

## 1. 회원 관리 정책

### 1.1 회원가입
- **지원 방식**: Google OAuth, Apple Sign In
- **필수 정보**: email, nickname
- **선택 정보**: picture_url, gender, age
- **초기 상태**: `onboarding_completed = false`

### 1.2 온보딩 프로세스
1. **닉네임 설정** (필수)
   - 길이: 2-20자
   - 제한: 특수문자 불가 (`!@#$%^&*(),.?":{}|<>`)
   - 정규식: `/[!@#$%^&*(),.?":{}|<>]/`

2. **프로필 이미지 설정** (선택)
   - 최대 크기: 800px
   - 압축 품질: 80
   - 저장 위치: Supabase Storage `profile_images` bucket

3. **책 소개** (정보 제공)

4. **완료 처리**
   - `onboarding_completed = true` 설정
   - `/home`으로 리다이렉트

### 1.3 로그인 플로우
```
1. Splash Screen
   ↓
2. 세션 체크 (Supabase.instance.client.auth.currentSession)
   ↓
3-1. 세션 없음 → Login Screen
3-2. 세션 있음 → users 테이블에서 사용자 정보 조회
   ↓
4-1. onboarding_completed = false → /onboarding/nickname
4-2. onboarding_completed = true → /home
```

### 1.4 회원 탈퇴
- **Edge Function 호출**: `delete-user`
- **삭제 범위**: user, user_books, memos, statistics
- **로컬 정리**: Google/Apple 로그아웃, Supabase 세션 삭제

---

## 2. 책 관리 정책

### 2.1 책 검색
- **API**: Naver Book Search API (via Supabase Edge Function)
- **검색 가능 필드**: 제목, 저자, ISBN, 출판사
- **결과**: NaverBook 객체 리스트

### 2.2 책 등록
1. **ISBN 중복 체크**
   - `books` 테이블에서 ISBN 검색
   - 중복 시: 기존 책 사용

2. **새 책 생성**
   - `books` 테이블 INSERT
   - 필드: title, author, isbn, cover_url, description, publisher, pubdate

3. **유저-책 관계 생성**
   - `user_books` 테이블 INSERT
   - 초기 status: '읽고 싶은'

### 2.3 책 상태 관리
**허용된 상태**: (변경 불가)
- `읽고 싶은` (want to read)
- `읽는 중` (reading)
- `완독` (completed)

**상태 변경 규칙**:
- 모든 상태 간 자유로운 변경 가능
- `user_books` 테이블의 `status` 컬럼 UPDATE
- `updated_at` 자동 갱신

### 2.4 책 조회
- **최근 책**: ORDER BY created_at DESC LIMIT 10
- **책 상세**: books LEFT JOIN user_books (status 포함)
- **필터링**: user_id 기준 (RLS 적용)

---

## 3. 메모 관리 정책

### 3.1 메모 작성
**필수 필드**:
- `book_id`: 어떤 책에 대한 메모인지
- `content`: 메모 내용 (빈 값 불가)
- `user_id`: 작성자 (자동 설정)

**선택 필드**:
- `page`: 페이지 번호 (integer, nullable)
- `image_url`: 첨부 이미지 (Supabase Storage URL)
- `visibility`: 'private' (기본) | 'public'

### 3.2 이미지 첨부
1. **이미지 선택**
   - 출처: Camera 또는 Gallery
   - 권한 체크: Android SDK 33+ → Photos, 33- → Storage
   - iOS: 자동 처리

2. **이미지 압축**
   - maxWidth: 800px
   - imageQuality: 80

3. **업로드**
   - Bucket: `memo_images`
   - 경로: `{user_id}/{timestamp}.jpg`
   - URL: Signed URL (1년 유효)

### 3.3 메모 조회
- **책별 메모**: `memos WHERE book_id = ? ORDER BY created_at DESC`
- **최근 메모**: `memos ORDER BY created_at DESC LIMIT 2`
- **전체 메모 (페이지네이션)**:
  - LIMIT: 10
  - OFFSET: page * 10
  - 책 필터링 옵션

### 3.4 메모 수정/삭제
- **수정**: content, page, image_url 변경 가능
- **삭제**: 물리 삭제 (DELETE)
- **권한**: user_id 일치 시에만 (RLS)

---

## 4. 통계 & 정책

### 4.1 통계 수집 (미래 기능)
- `statistics` 테이블 사용
- `total_books`: 사용자가 등록한 총 책 수
- `total_memos`: 작성한 총 메모 수
- `total_status_changes`: 책 상태 변경 횟수

### 4.2 앱 버전 관리
- **테이블**: `app_versions`
- **플랫폼**: android | ios
- **강제 업데이트**: `force_update = true`
- **체크 시점**: Splash Screen

### 4.3 Firebase Analytics
**로그 이벤트**:
- `login`: 로그인 성공 (provider: google|apple)
- `screen_view`: 화면 진입
- `button_click`: 주요 버튼 클릭
- `book_status_changed`: 책 상태 변경

---

## 5. 데이터 정책

### 5.1 타임스탬프
- **자동 생성**: `created_at`, `updated_at`
- **기본값**: `timezone('utc', now())`
- **UPDATE 시**: `updated_at` 자동 갱신

### 5.2 Row Level Security (RLS)
**모든 테이블 RLS 활성화**:
- `users`: user_id = auth.uid()
- `books`: public (읽기만)
- `user_books`: user_id = auth.uid()
- `memos`: user_id = auth.uid()
- `statistics`: user_id = auth.uid()

### 5.3 데이터 무결성
**Foreign Key Constraints**:
- `user_books.user_id` → `users.id`
- `user_books.book_id` → `books.id`
- `memos.user_id` → `users.id`
- `memos.book_id` → `books.id`
- `statistics.user_id` → `users.id`

**Unique Constraints**:
- `users.email`
- `books.isbn`
- `statistics.user_id`

---

## 6. 에러 처리 정책

### 6.1 에러 유형
- **AuthException**: 인증 실패, 세션 만료
- **NetworkException**: API 통신 실패
- **ValidationException**: 입력 검증 실패
- **StorageException**: 파일 업로드 실패

### 6.2 사용자 메시지
- **한글**: 모든 에러 메시지는 한글로 표시
- **명확성**: "무엇이 잘못되었는지" 명확히 전달
- **액션**: 가능한 경우 해결 방법 제시

---

## 7. 변경 이력

### v1.0 (2025-01-22)
- 초기 정책 문서 작성
- 회원, 책, 메모 관리 정책 정의
- DB 제약조건 명시

---

**마지막 업데이트**: 2025-01-22
**관리자**: Product Team
**버전**: 1.0

