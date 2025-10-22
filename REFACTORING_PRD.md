# 📐 Milkyway 리팩토링 PRD (Product Requirements Document)

> **프로젝트**: Milkyway App 전면 리팩토링
> **목표**: UI/UX 개선, 코드 품질 향상, 유지보수성 강화
> **원칙**: 기능 100% 보존

---

## 1. 프로젝트 개요

### 1.1 배경
현재 Milkyway 앱은 기능적으로는 완성되었으나, 다음과 같은 문제가 있습니다:
- 디자인 시스템 부재로 인한 일관성 부족
- 코드 중복 (특히 권한 처리, 이미지 picker)
- GoRouter 네비게이션 구조 문제 (스택 쌓임)
- 스타일 하드코딩 및 인라인 스타일

### 1.2 목표
- ✅ **사용성 개선**: 깔끔하고 일관된 UI/UX
- ✅ **네비게이션 최적화**: GoRouter 제대로 활용
- ✅ **유지보수성 향상**: 코드 중복 제거, 구조 개선
- ✅ **기능 100% 보존**: 모든 비즈니스 로직 유지

### 1.3 범위
- **포함**: UI, 스타일, 컴포넌트 구조, 네비게이션
- **제외**: DB 스키마, API 로직, 비즈니스 규칙

---

## 2. 디자인 요구사항

### 2.1 디자인 시스템

#### 색상 팔레트
**Primary Colors** (검은색 & 그레이):
- Black: `#000000`
- Gray 900-100: `#1A1A1A` ~ `#F5F5F5`
- White: `#FFFFFF`

**Accent Color** (형광 초록 - 로고 색상):
- Neon Green: `#00FF00`
- Neon Green Dark: `#00CC00`
- Neon Green Light: `#66FF66`

**Semantic Colors** (차분한 톤):
- Success: `#4CAF50`
- Warning: `#FF9800`
- Error: `#F44336`
- Info: `#2196F3`

**Book Status Colors**:
- Want to Read: `#64B5F6` (차분한 파랑)
- Reading: `#FFB74D` (차분한 주황)
- Completed: `#81C784` (차분한 초록)

#### 타이포그래피
- **폰트**: Pretendard (Google Fonts)
- **Letter Spacing**: -0.01
- **Line Height**: 
  - Display/Headline: 1.2-1.3
  - Body: 1.6
  - Label: 1.2

#### Spacing & Layout
- **좌우 패딩**: 20px (고정)
- **카드 Radius**: 12px (고정)
- **표준 간격**: 4, 8, 16, 24, 32, 48px

### 2.2 디자인 방향
- **미니멀**: v0 스타일 참고, 깔끔하고 명확
- **별 테마**: 최소한만 적용 (로그인/스플래시)
- **파스텔/그라데이션**: 사용하지 않음
- **비비드**: 피하고 차분한 톤 유지

---

## 3. 기능 요구사항

### 3.1 절대 변경 금지 항목

#### 인증 & 회원
- Google/Apple OAuth 로그인 플로우
- 온보딩 프로세스 (닉네임 → 프로필 이미지 → 책 소개)
- 닉네임 Validation (2-20자, 특수문자 제외)
- onboarding_completed 플래그 체크

#### 책 관리
- Naver Book Search API 연동
- ISBN 중복 체크
- 책 상태 ('읽고 싶은', '읽는 중', '완독')
- user_books 관계 테이블 로직

#### 메모 관리
- 페이지 번호 저장
- 이미지 첨부 (Supabase Storage)
- visibility (private/public)
- 메모 pagination (limit: 10)

#### 데이터베이스
- 모든 테이블 구조
- RLS 정책
- Foreign Key Constraints
- Check Constraints

### 3.2 변경 허용 항목

#### UI/UX
- 컴포넌트 구조 및 위젯 분리
- 색상, 폰트, 간격 (디자인 시스템 적용)
- 레이아웃 및 애니메이션
- 빈 상태, 에러 상태 UI

#### 네비게이션
- GoRouter 라우트 구조
- ShellRoute 활용한 BottomNav 통합
- Named routes 및 pathParameters
- 화면 전환 방식 (Navigator → context.go/pop)

#### 코드 구조
- Provider 파일 위치
- 서비스 레이어 추출 (중복 제거)
- 에러 타입 표준화
- 로깅 방식 통일

---

## 4. 기술 요구사항

### 4.1 아키텍처
- **패턴**: Clean Architecture (Data-Domain-Presentation)
- **상태 관리**: Riverpod (@riverpod annotation)
- **라우팅**: GoRouter
- **테마**: Material Design 3

### 4.2 컴포넌트 구조
```
lib/core/
  theme/              # 디자인 시스템
    - app_colors.dart
    - app_typography.dart
    - app_spacing.dart
    - app_constants.dart
    - app_theme.dart
  
  presentation/
    widgets/          # 공통 컴포넌트
      buttons/
      layouts/
      states/
      inputs/
      images/
      dialogs/
      animations/
  
  services/           # 비즈니스 로직 재사용
    - permission_service.dart
    - image_picker_service.dart
    - storage_service.dart
  
  utils/              # 유틸리티
    - validators.dart
    - formatters.dart
    - logger.dart
```

### 4.3 GoRouter 구조
```
/ (Splash)
/login
/onboarding/nickname
/onboarding/profile-image
/onboarding/book-intro

ShellRoute (with BottomNav):
  /home
  /books
  /books/detail/:id
  /books/search
  /memos
  /memos/detail/:id
  /memos/create
  /memos/edit/:id
  /profile
```

---

## 5. 성공 기준

### 5.1 기능 검증
- ✅ 모든 기존 기능 정상 동작
- ✅ 로그인/회원가입 플로우 정상
- ✅ 책 검색/등록/상태 변경 정상
- ✅ 메모 CRUD 정상
- ✅ 이미지 업로드 정상

### 5.2 코드 품질
- ✅ 코드 중복 80% 감소
- ✅ 일관된 코딩 스타일
- ✅ 명확한 파일 구조
- ✅ 적절한 주석 및 문서

### 5.3 성능
- ✅ 네비게이션 응답 속도 개선
- ✅ 불필요한 rebuild 제거
- ✅ 이미지 로딩 최적화

### 5.4 사용자 경험
- ✅ 일관된 디자인
- ✅ 직관적인 네비게이션
- ✅ 부드러운 애니메이션
- ✅ 명확한 에러 메시지

---

## 6. 마일스톤

### Phase 1: 디자인 시스템 (1-2일)
- [ ] 색상 팔레트
- [ ] 타이포그래피
- [ ] Spacing & Constants
- [ ] Material Theme 3

### Phase 2: 서비스 레이어 (1-2일)
- [ ] Permission Service
- [ ] ImagePicker Service
- [ ] Storage Service
- [ ] API Config

### Phase 3: 공통 컴포넌트 (2-3일)
- [ ] 버튼, 레이아웃
- [ ] 상태, 입력
- [ ] 이미지, 다이얼로그
- [ ] 애니메이션

### Phase 4: 유틸리티 & 에러 처리 (1일)
- [ ] Validators
- [ ] Formatters
- [ ] AppLogger
- [ ] AppException

### Phase 5: Provider 구조 (1일)
- [ ] Provider 파일 분리
- [ ] @riverpod 전환

### Phase 6: GoRouter (1-2일)
- [ ] 라우트 재설계
- [ ] MainShell 구현
- [ ] Named Routes

### Phase 7: Repository 통합 (1일)
- [ ] BookRepository 통합
- [ ] 중복 메서드 제거

### Phase 8: 화면 리팩토링 (4-5일)
- [ ] Home, BookShelf, MemoList
- [ ] BookDetail, MemoDetail
- [ ] Profile, Auth, Onboarding

### Phase 9: 최적화 & 정리 (1-2일)
- [ ] Provider 최적화
- [ ] 이미지 최적화
- [ ] Asset 정리
- [ ] 전체 테스트

---

## 7. 리스크 관리

### 7.1 주요 리스크
| 리스크 | 확률 | 영향 | 완화 방안 |
|--------|------|------|-----------|
| 네비게이션 변경 시 기능 손상 | 중 | 고 | 단계별 테스트, 기존 로직 최대한 유지 |
| Provider 전환 시 상태 손실 | 중 | 중 | 점진적 전환, 철저한 테스트 |
| 권한 처리 로직 통합 실수 | 저 | 고 | 기존 로직 100% 복사, 검증 |
| DB 쿼리 실수로 변경 | 저 | 고 | 코드 리뷰, REFACTORING_RULES.md 준수 |

### 7.2 롤백 계획
- Git branch 전략: `refactor/phase-{N}`
- 각 Phase 완료 시 커밋
- 문제 발생 시 이전 Phase로 롤백

---

## 8. 참고 문서
- `REFACTORING_RULES.md`: 리팩토링 절대 규칙
- `BUSINESS_LOGIC_POLICY.md`: 비즈니스 로직 정책
- `DATABASE_SCHEMA.md`: DB 구조 문서

---

**작성일**: 2025-01-22
**작성자**: Product & Dev Team
**승인**: 대기 중
**버전**: 1.0

