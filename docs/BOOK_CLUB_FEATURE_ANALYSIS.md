# 📚 책 모임 기능 분석 문서

> **책 모임 기능의 요구사항, 구현 가능성, 잠재적 이슈 분석**
> **⚠️ 구현 전 검토용 문서입니다. 실제 구현은 하지 않았습니다.**

---

## 1. 요구사항 정리

### 1.1 모임 생성
- **모임장**: 사용자가 책 모임 생성 가능
- **모임 정보**:
  - 모임 소개 (description)
  - 주제 (topic)
  - 키워드 (keywords) - 배열 또는 텍스트
  - 권장 도서 (recommended_books) - 여러 권 가능
  - 일정 (schedule)
    - 시작 일시 (start_date)
    - 종료 일시 (end_date)
- **상세 페이지**: 모임 정보를 보여주는 페이지

### 1.2 모임 참여
- **참여 상태**:
  - 미참여 (not_joined)
  - 참여 (joined)
  - 참여 취소 (cancelled)
- **참여 프로세스**:
  1. 사용자가 모임 신청
  2. 모임장이 승인 (또는 자동 승인)
  3. 참여 상태로 변경
  4. 참여 취소 가능

### 1.3 모임 진행
- **모임 기간**: 시작일 ~ 종료일
- **메모 공유**: 
  - 참여자들이 작성한 메모를 모임 참여자들에게 공유
  - 모임 종료 후에도 조회 가능할지 결정 필요

### 1.4 모임장 권한
- **참여자 관리**:
  - 참여자 추방 (kick)
  - 참여 승인/거절
- **모임 관리**:
  - 모임 정보 수정
  - 모임 삭제
  - 일정 변경

---

## 2. 필요한 데이터베이스 구조

### 2.1 새로운 테이블

#### `book_clubs` (모임)
```sql
- id: uuid (PK)
- creator_id: uuid (FK → users.id) - 모임장
- title: text (NOT NULL) - 모임 제목
- description: text - 모임 소개
- topic: text - 주제
- keywords: text[] 또는 text - 키워드 배열
- start_date: timestamptz - 시작 일시
- end_date: timestamptz - 종료 일시
- max_members: integer - 최대 인원 (선택)
- status: enum - 'recruiting', 'ongoing', 'completed', 'cancelled'
- created_at: timestamptz
- updated_at: timestamptz
```

#### `book_club_members` (모임 멤버)
```sql
- id: uuid (PK)
- club_id: uuid (FK → book_clubs.id)
- user_id: uuid (FK → users.id)
- status: enum - 'pending', 'joined', 'cancelled', 'kicked'
- role: enum - 'owner', 'member' - 모임장/일반 멤버
- joined_at: timestamptz - 참여 일시
- created_at: timestamptz
- updated_at: timestamptz
- UNIQUE(club_id, user_id) - 중복 참여 방지
```

#### `book_club_books` (모임 권장 도서)
```sql
- id: uuid (PK)
- club_id: uuid (FK → book_clubs.id)
- book_id: uuid (FK → books.id) - ✅ books 테이블의 기존 책 참조
- order: integer - 순서
- created_at: timestamptz
- UNIQUE(club_id, book_id) - 중복 도서 방지
```

**✅ 확인**: `book_club_books`의 `book_id`는 모두 `books` 테이블에서 가져옵니다.
- 모임장이 권장 도서를 등록할 때, 이미 `books` 테이블에 존재하는 책을 선택합니다.
- 새로운 책을 등록하려면 먼저 `books` 테이블에 등록한 후 `book_club_books`에 연결합니다.

#### `book_club_memos` (모임 메모) - 옵션 1: 별도 테이블
```sql
- id: uuid (PK)
- club_id: uuid (FK → book_clubs.id)
- memo_id: uuid (FK → memos.id) - 기존 메모 참조
- created_at: timestamptz
```

**✅ 확인 사항**:

1. **메모 출처**: 
   - `book_club_memos`의 `memo_id`는 모두 `memos` 테이블에서 가져옵니다.
   - `book_club_memos`는 메모를 중복 저장하지 않고, `memos` 테이블의 메모를 참조만 합니다.

2. **모임 화면에서 보여줄 메모**:
   - **옵션 A (수동 등록)**: 모임 참여자가 자신의 메모를 모임에 "공유"하면 `book_club_memos`에 등록
   - **옵션 B (자동 수집)**: 모임 권장 도서(`book_club_books`)의 책에 대한 메모 중:
     - `visibility='public'`인 메모들
     - 또는 모임 참여자가 작성한 메모들 (private 포함)
   
3. **화면별 메모 표시**:
   - **모임 상세 화면**: 해당 모임의 메모들만 표시 (모임 참여자만 조회 가능)
   - **책 상세 화면**: 기존처럼 `visibility='public'`인 메모만 표시 (모든 사용자 조회 가능)
   - **모임 메모는 모임 참여자에게만 공개**, 일반 책 상세 화면의 공개 메모와는 별개

4. **권한**:
   - 모임 참여자만 모임 메모를 볼 수 있음 (RLS 정책 필요)
   - 모임 참여자가 작성한 메모를 모임에 공유할 수 있음

#### 또는 `memos` 테이블 확장 - 옵션 2: 기존 테이블 수정
```sql
- club_id: uuid (FK → book_clubs.id, NULLABLE) - 모임 메모인 경우
- visibility: 'private', 'public', 'club' - 'club' 추가
```

---

## 3. Supabase 구현 가능성

### ✅ 구현 가능한 기능

1. **모임 생성/수정/삭제**
   - PostgreSQL 테이블로 충분히 구현 가능
   - RLS 정책으로 모임장만 수정/삭제 가능

2. **참여 신청/승인/취소**
   - `book_club_members` 테이블로 상태 관리
   - RLS 정책으로 참여자만 자신의 상태 변경 가능

3. **권장 도서 등록**
   - `book_club_books` 테이블로 다대다 관계
   - 기존 `books` 테이블과 연결

4. **메모 공유**
   - 옵션 1: 별도 테이블로 모임 메모 관리
   - 옵션 2: `memos` 테이블에 `club_id` 추가
   - 옵션 3: `visibility`에 'club' 추가

5. **모임장 권한**
   - RLS 정책 + Edge Function으로 구현 가능
   - 모임장만 추방, 승인/거절 가능

---

## 4. 잠재적 이슈 분석

### 4.1 RLS (Row Level Security) 정책 이슈

#### 🔴 **심각한 이슈**

**이슈 1: 모임 정보 조회 권한**
- **문제**: 현재 RLS 정책은 `user_id = auth.uid()` 기반
- **영향**: 모임 참여자가 아닌 사용자도 모임 정보를 봐야 함 (신청 전)
- **해결**: 
  - `book_clubs` 테이블: 읽기는 public, 수정/삭제는 creator_id만
  - 또는 Edge Function으로 RLS 우회

**이슈 2: 모임 멤버 목록 조회**
- **문제**: 참여자 목록을 보려면 다른 사용자 정보 접근 필요
- **영향**: 현재 `users` 테이블 RLS는 `user_id = auth.uid()`만 허용
- **해결**:
  - Edge Function으로 Service Role Key 사용
  - 또는 `book_club_members` 조인 시 users 정보만 제한적으로 노출

**이슈 3: 모임 메모 공유**
- **문제**: 모임 참여자들의 메모를 참여자들에게만 공개
- **영향**: 현재 `memos` RLS는 `user_id = auth.uid()`만 허용
- **해결**:
  - 옵션 1: Edge Function으로 모임 참여자 확인 후 메모 조회
  - 옵션 2: `memos` 테이블에 `club_id` 추가하고 RLS 정책 수정
  - 옵션 3: 별도 `book_club_memos` 테이블 사용

#### 🟡 **중간 이슈**

**이슈 4: 모임장 권한 검증**
- **문제**: 모임장만 추방, 승인/거절 가능해야 함
- **영향**: RLS만으로는 복잡한 권한 체크 어려움
- **해결**: Edge Function으로 권한 검증 후 처리

**이슈 5: 모임 상태 자동 변경**
- **문제**: `start_date`, `end_date`에 따라 상태 자동 변경
- **영향**: PostgreSQL Cron Job 또는 Edge Function 스케줄러 필요
- **해결**: Supabase Edge Functions + Cron 또는 외부 스케줄러

---

### 4.2 기존 기능과의 충돌/통합 이슈

#### 🔴 **심각한 이슈**

**이슈 6: 메모 visibility 정책 변경**
- **현재**: `memos.visibility`는 'private', 'public'만 존재
- **요구사항**: 모임 참여자에게만 공개하는 'club' 필요
- **영향**: 
  - 기존 코드에서 `MemoVisibility` enum 수정 필요
  - 기존 메모 조회 로직 변경 필요
  - `get-public-book-memos` Edge Function 수정 필요
- **해결**:
  - 옵션 1: `visibility`에 'club' 추가 (기존 테이블 수정)
  - 옵션 2: 별도 `book_club_memos` 테이블 사용 (기존 코드 영향 최소)

**이슈 7: 기존 메모를 모임에 연결**
- **문제**: 사용자가 이미 작성한 메모를 모임에 공유하고 싶을 때
- **영향**: 메모 작성 시점과 모임 참여 시점이 다를 수 있음
- **해결**: 
  - 메모 작성 후 모임에 "공유" 기능 추가
  - 또는 모임 참여 시 자동으로 해당 책의 메모를 모임에 연결

#### 🟡 **중간 이슈**

**이슈 8: 책 상세 페이지의 메모 표시**
- **현재**: 책 상세에서 공개 메모만 표시
- **요구사항**: 모임 메모도 표시해야 할지 결정 필요
- **영향**: UI/UX 변경 필요

**이슈 9: 통계 데이터**
- **현재**: `statistics` 테이블에 개인 통계만 저장
- **요구사항**: 모임별 통계도 필요할 수 있음
- **영향**: 통계 수집 로직 확장 필요

---

### 4.3 데이터 무결성 이슈

#### 🟡 **중간 이슈**

**이슈 10: 모임 삭제 시 관련 데이터**
- **문제**: 모임 삭제 시 `book_club_members`, `book_club_books`, `book_club_memos` 처리
- **영향**: CASCADE DELETE 또는 소프트 삭제 필요
- **해결**: 
  - Foreign Key에 `ON DELETE CASCADE` 설정
  - 또는 `book_clubs.status = 'cancelled'`로 소프트 삭제

**이슈 11: 모임장 탈퇴/삭제**
- **문제**: 모임장이 탈퇴하거나 계정 삭제 시 모임 처리
- **영향**: 모임장 위임 또는 모임 종료 처리 필요
- **해결**: 
  - 모임장 위임 기능 추가
  - 또는 모임장 탈퇴 시 모임 자동 종료

**이슈 12: 중복 참여 방지**
- **문제**: 같은 사용자가 같은 모임에 중복 참여
- **영향**: `UNIQUE(club_id, user_id)` 제약조건 필요
- **해결**: 데이터베이스 제약조건으로 해결 가능

**이슈 13: 모임 기간 중 참여/탈퇴**
- **문제**: 모임이 진행 중일 때 참여/탈퇴 가능 여부
- **영향**: 비즈니스 로직 결정 필요
- **해결**: `book_clubs.status`에 따라 참여/탈퇴 제한

---

### 4.4 성능 이슈

#### 🟡 **중간 이슈**

**이슈 14: 모임 목록 조회 성능**
- **문제**: 많은 모임이 있을 때 목록 조회 성능
- **영향**: 페이지네이션, 인덱싱 필요
- **해결**: 
  - `book_clubs` 테이블에 인덱스 추가 (status, start_date, end_date)
  - 페이지네이션 구현

**이슈 15: 모임 메모 조회 성능**
- **문제**: 많은 참여자가 많은 메모를 작성할 때
- **영향**: 조인 쿼리 성능 저하 가능
- **해결**: 
  - 페이지네이션 필수
  - 인덱스 최적화 (club_id, created_at)

**이슈 16: 실시간 알림**
- **문제**: 모임 일정 변경, 새 참여자 등 실시간 알림
- **영향**: Supabase Realtime 사용 시 성능 고려
- **해결**: 
  - 필요한 경우에만 Realtime 구독
  - 또는 Push Notification 사용

---

### 4.5 보안 이슈

#### 🔴 **심각한 이슈**

**이슈 17: 모임 메모 접근 권한**
- **문제**: 모임 참여자만 모임 메모 조회 가능해야 함
- **영향**: RLS 정책으로는 복잡한 권한 체크 어려움
- **해결**: Edge Function으로 참여자 확인 후 메모 조회

**이슈 18: 모임장 권한 검증**
- **문제**: 클라이언트에서 모임장 권한 검증 시 위조 가능
- **영향**: 서버 사이드 검증 필수
- **해결**: Edge Function으로 권한 검증

#### 🟡 **중간 이슈**

**이슈 19: 모임 정보 수정 권한**
- **문제**: 모임장만 수정 가능해야 함
- **영향**: RLS 정책으로 `creator_id = auth.uid()` 체크 가능
- **해결**: RLS 정책으로 해결 가능

**이슈 20: 스팸/부적절한 모임 생성**
- **문제**: 악의적인 사용자의 모임 생성
- **영향**: 신고 기능, 관리자 승인 필요할 수 있음
- **해결**: 
  - 초기에는 자유 생성
  - 문제 발생 시 신고 기능 추가

---

## 5. 기존 정책과의 충돌

### 5.1 DATABASE_SCHEMA.md
- **⚠️ 경고**: "이 스키마는 변경 금지입니다"
- **영향**: 새로운 테이블 추가는 가능하지만, 기존 테이블 수정 시 주의
- **해결**: 가능한 한 별도 테이블로 구현

### 5.2 BUSINESS_LOGIC_POLICY.md
- **메모 visibility 정책**: 현재 'private', 'public'만 존재
- **영향**: 'club' 추가 시 정책 문서 수정 필요
- **해결**: 정책 문서 업데이트 필요

### 5.3 REFACTORING_RULES.md
- **⚠️ 경고**: "memos visibility 정책 변경 금지"
- **영향**: 모임 메모를 위해 정책 변경 필요
- **해결**: 
  - 옵션 1: 별도 테이블 사용 (정책 변경 최소화)
  - 옵션 2: 정책 변경 후 코드 전면 수정

---

## 6. 권장 구현 방안

### 6.1 단계별 구현

#### Phase 1: 기본 모임 기능
1. `book_clubs` 테이블 생성
2. `book_club_members` 테이블 생성
3. 모임 생성/조회 기능
4. 참여 신청/승인 기능

#### Phase 2: 권장 도서
1. `book_club_books` 테이블 생성
2. 권장 도서 등록 기능

#### Phase 3: 메모 공유
1. **옵션 A (권장)**: 별도 `book_club_memos` 테이블 사용
   - 기존 코드 영향 최소화
   - 모임 메모만 별도 관리
2. **옵션 B**: `memos` 테이블에 `club_id` 추가
   - 기존 코드 수정 필요
   - 통합 관리 가능

#### Phase 4: 고급 기능
1. 모임장 권한 (추방, 승인/거절)
2. 모임 상태 자동 변경
3. 실시간 알림

### 6.2 테이블 설계 권장사항

#### ✅ 권장: 별도 테이블 사용
- `book_club_memos` 테이블로 모임 메모 관리
- 기존 `memos` 테이블은 그대로 유지
- 모임 메모는 `memo_id`로 기존 메모 참조
- 장점: 기존 코드 영향 최소화

#### ❌ 비권장: 기존 테이블 수정
- `memos` 테이블에 `club_id` 추가
- `visibility`에 'club' 추가
- 단점: 기존 코드 전면 수정 필요

---

## 7. 결론

### ✅ 구현 가능성: **높음**
- Supabase의 PostgreSQL + RLS + Edge Functions로 충분히 구현 가능
- 다만 RLS 정책 설계가 복잡함

### ⚠️ 주요 이슈
1. **RLS 정책 복잡성**: 모임 참여자 권한 관리
2. **기존 코드 영향**: 메모 visibility 정책 변경 시 전면 수정
3. **성능**: 모임 메모 조회 시 조인 쿼리 최적화 필요

### 📋 우선 해결 사항
1. 모임 메모 관리 방식 결정 (별도 테이블 vs 기존 테이블 수정)
2. RLS 정책 설계 (모임 정보, 멤버 목록, 메모 공유)
3. Edge Function 설계 (권한 검증, 메모 조회)

---

**작성일**: 2025-01-22
**버전**: 1.0
**상태**: 분석 완료 (구현 전)

