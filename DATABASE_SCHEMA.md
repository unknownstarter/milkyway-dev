# 🗄️ Milkyway Database Schema

> **Supabase PostgreSQL 데이터베이스 구조**
> **⚠️ 이 스키마는 변경 금지입니다. 모든 쿼리는 이 구조를 기준으로 작성되어야 합니다.**

---

## 테이블 구조

### 1. users (회원)

**컬럼**:
| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | uuid | PK | uuid_generate_v4() | 사용자 고유 ID |
| email | text | UNIQUE, NOT NULL | - | 이메일 |
| nickname | text | NOT NULL | - | 닉네임 |
| picture_url | text | NULLABLE | - | 프로필 이미지 URL |
| gender | gender_type | NULLABLE | 'not_specified' | 성별 enum |
| age | integer | NULLABLE | - | 나이 |
| created_at | timestamptz | NOT NULL | now() | 생성 시각 |
| updated_at | timestamptz | NOT NULL | now() | 수정 시각 |
| onboarding_completed | boolean | NULLABLE | false | 온보딩 완료 여부 |
| auth_provider | auth_provider_type | NOT NULL | 'google' | 인증 제공자 enum |
| kakao_id | bigint | UNIQUE, NULLABLE | - | 카카오 ID (미래용) |

**Enum Types**:
- `gender_type`: 'male', 'female', 'other', 'not_specified'
- `auth_provider_type`: 'google', 'apple', 'kakao'

**RLS**: ✅ 활성화 (user_id = auth.uid())
**Rows**: 62

---

### 2. books (책)

**컬럼**:
| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | uuid | PK | uuid_generate_v4() | 책 고유 ID |
| title | text | NOT NULL | - | 책 제목 |
| author | text | NOT NULL | - | 저자 |
| isbn | text | UNIQUE, NOT NULL | - | ISBN |
| cover_url | text | NULLABLE | - | 표지 이미지 URL |
| description | text | NULLABLE | - | 책 설명 |
| publisher | text | NULLABLE | - | 출판사 |
| pubdate | text | NULLABLE | - | 출판일 |
| created_at | timestamptz | NOT NULL | now() | 생성 시각 |
| updated_at | timestamptz | NOT NULL | now() | 수정 시각 |

**RLS**: ✅ 활성화 (읽기만 public)
**Rows**: 101

---

### 3. user_books (사용자-책 관계)

**컬럼**:
| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | uuid | PK | uuid_generate_v4() | 관계 고유 ID |
| user_id | uuid | FK(users.id), NOT NULL | - | 사용자 ID |
| book_id | uuid | FK(books.id), NOT NULL | - | 책 ID |
| status | text | NOT NULL, CHECK | '읽고 싶은' | 책 상태 |
| created_at | timestamptz | NOT NULL | now() | 생성 시각 |
| updated_at | timestamptz | NOT NULL | now() | 수정 시각 |

**Check Constraint**: ⚠️ 절대 변경 금지
```sql
CHECK (status = ANY (ARRAY['읽고 싶은'::text, '읽는 중'::text, '완독'::text]))
```

**Foreign Keys**:
- `user_id` → `users.id`
- `book_id` → `books.id`

**RLS**: ✅ 활성화 (user_id = auth.uid())
**Rows**: 69

---

### 4. memos (메모)

**컬럼**:
| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | uuid | PK | uuid_generate_v4() | 메모 고유 ID |
| user_id | uuid | FK(users.id), NULLABLE | - | 작성자 ID |
| book_id | uuid | FK(books.id), NULLABLE | - | 책 ID |
| content | text | NOT NULL | - | 메모 내용 |
| visibility | visibility_type | NULLABLE | 'private' | 공개 여부 enum |
| created_at | timestamptz | NULLABLE | now() | 생성 시각 |
| updated_at | timestamptz | NULLABLE | now() | 수정 시각 |
| page | integer | NULLABLE | - | 페이지 번호 |
| image_url | text | NULLABLE | - | 첨부 이미지 URL |

**Enum Types**:
- `visibility_type`: 'private', 'public'

**Foreign Keys**:
- `user_id` → `users.id`
- `book_id` → `books.id`

**RLS**: ✅ 활성화 (user_id = auth.uid())
**Rows**: 119

---

### 5. statistics (통계)

**컬럼**:
| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | uuid | PK | uuid_generate_v4() | 통계 고유 ID |
| user_id | uuid | FK(users.id), UNIQUE, NULLABLE | - | 사용자 ID |
| total_books | integer | NULLABLE | 0 | 총 책 수 |
| total_memos | integer | NULLABLE | 0 | 총 메모 수 |
| total_status_changes | integer | NULLABLE | 0 | 상태 변경 횟수 |
| last_updated_at | timestamptz | NULLABLE | now() | 마지막 갱신 시각 |

**Foreign Keys**:
- `user_id` → `users.id`

**RLS**: ✅ 활성화 (user_id = auth.uid())
**Rows**: 0 (미래 기능)

---

### 6. app_versions (앱 버전)

**컬럼**:
| 컬럼명 | 타입 | 제약조건 | 기본값 | 설명 |
|--------|------|----------|--------|------|
| id | bigint | PK, IDENTITY | GENERATED ALWAYS | 버전 ID |
| platform | text | NOT NULL | - | 플랫폼 (android/ios) |
| min_version | text | NOT NULL | - | 최소 버전 |
| latest_version | text | NOT NULL | - | 최신 버전 |
| force_update | boolean | NULLABLE | false | 강제 업데이트 여부 |
| created_at | timestamptz | NOT NULL | now() | 생성 시각 |
| updated_at | timestamptz | NOT NULL | now() | 수정 시각 |

**RLS**: ✅ 활성화
**Rows**: 2

---

## ERD (Entity Relationship Diagram)

```
┌──────────────┐
│    users     │
│              │
│  - id (PK)   │
│  - email     │
│  - nickname  │
│  - ...       │
└──────┬───────┘
       │
       │ 1:N
       ├─────────────────────┐
       │                     │
       ▼                     ▼
┌──────────────┐      ┌──────────────┐
│ user_books   │      │    memos     │
│              │      │              │
│  - id (PK)   │      │  - id (PK)   │
│  - user_id ◄─┘      │  - user_id ◄─┘
│  - book_id   │      │  - book_id   │
│  - status    │      │  - content   │
└──────┬───────┘      │  - page      │
       │              │  - image_url │
       │ N:1          └──────┬───────┘
       │                     │
       │                     │ N:1
       ▼                     ▼
┌──────────────┐             │
│    books     │◄────────────┘
│              │
│  - id (PK)   │
│  - title     │
│  - author    │
│  - isbn      │
└──────────────┘

┌──────────────┐
│ statistics   │
│              │
│  - id (PK)   │
│  - user_id ──┼──► users.id
└──────────────┘

┌──────────────┐
│ app_versions │
│              │
│  - id (PK)   │
│  - platform  │
└──────────────┘
```

---

## 주요 쿼리 패턴

### 1. 사용자 책 목록 조회
```sql
SELECT ub.*, b.*
FROM user_books ub
INNER JOIN books b ON ub.book_id = b.id
WHERE ub.user_id = ?
ORDER BY ub.created_at DESC
```

### 2. 책별 메모 조회
```sql
SELECT m.*, b.title, b.author, b.cover_url, u.nickname, u.picture_url
FROM memos m
INNER JOIN books b ON m.book_id = b.id
INNER JOIN users u ON m.user_id = u.id
WHERE m.book_id = ?
ORDER BY m.created_at DESC
```

### 3. ISBN으로 책 검색
```sql
SELECT b.*, ub.status
FROM books b
LEFT JOIN user_books ub ON b.id = ub.book_id AND ub.user_id = ?
WHERE b.isbn = ?
```

---

## Supabase Storage Buckets

### profile_images
- **용도**: 사용자 프로필 이미지
- **경로**: `{user_id}/{timestamp}.jpg`
- **공개**: Private (signed URL)

### memo_images
- **용도**: 메모 첨부 이미지
- **경로**: `{user_id}/{timestamp}.jpg`
- **공개**: Private (signed URL)
- **만료**: 1년

---

## 변경 이력

### v1.0 (2025-01-22)
- 초기 스키마 문서화
- 6개 테이블 정의
- RLS 정책 명시
- Storage 구조 추가

---

**⚠️ 중요**: 이 스키마를 변경하려면 반드시 Product Team과 협의하세요.

**마지막 업데이트**: 2025-01-22
**데이터베이스**: Supabase PostgreSQL
**버전**: 1.0

