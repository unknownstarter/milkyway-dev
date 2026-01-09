# 🔐 세션 지속 시간 설정 가이드

## 개요

구글 로그인과 애플 로그인의 세션을 **1개월 동안 유지**하도록 설정하는 방법입니다.

## 현재 구현 상태

### ✅ 앱 코드에서 구현된 기능

1. **자동 세션 갱신**
   - `auth_provider.dart`에 `_refreshSessionIfNeeded()` 메서드 추가
   - 세션이 만료되기 5분 전에 자동으로 갱신 시도
   - `getCurrentUser()` 호출 시마다 세션 갱신 체크

2. **앱 시작 시 세션 갱신**
   - `splash_screen.dart`에서 앱 시작 시 세션이 만료된 경우 refresh token으로 갱신 시도
   - 갱신 성공 시 자동으로 홈 화면으로 이동

### 📋 Supabase 대시보드 설정 필요

Supabase 대시보드에서 다음 설정을 변경해야 합니다:

#### 1. JWT 만료 시간 설정 (최대 1주일)

1. [Supabase 대시보드](https://supabase.com/dashboard/project/hyjgfgzexvxhgfmqgiqu) 접속
2. **Authentication** → **Settings** → **Auth** 섹션으로 이동
3. **JWT expiry** 설정을 최대값인 **604800초 (1주일)**로 변경
   - 현재 기본값: 3600초 (1시간)
   - 변경할 값: 604800초 (7일)

#### 2. Refresh Token 설정 확인

1. **Authentication** → **Settings** → **Auth** 섹션에서 확인
2. **Enable refresh token rotation**이 활성화되어 있는지 확인
   - 활성화되어 있으면 refresh token이 자동으로 갱신됨
   - 이 설정으로 최대 1개월까지 세션 유지 가능

#### 3. 세션 타임아웃 설정 (선택사항)

1. **Authentication** → **Settings** → **Auth** 섹션
2. **Session timeout** 설정 확인
   - 기본값: 없음 (무제한)
   - 1개월 이상 유지하려면 이 설정을 변경하지 않음

## 작동 원리

### 세션 유지 메커니즘

1. **JWT 토큰 (Access Token)**
   - 만료 시간: 최대 1주일 (604,800초)
   - 만료되기 5분 전에 자동 갱신

2. **Refresh Token**
   - 만료되지 않음 (Supabase 기본 설정)
   - JWT 토큰이 만료되면 refresh token으로 새 JWT 토큰 발급
   - 이 과정을 반복하여 최대 1개월까지 세션 유지 가능

### 자동 갱신 흐름

```
사용자 로그인
  ↓
JWT 토큰 발급 (1주일 유효)
  ↓
5분 전에 자동 갱신 시도
  ↓
Refresh Token으로 새 JWT 토큰 발급
  ↓
(반복)
  ↓
최대 1개월까지 세션 유지
```

## 테스트 방법

1. **로그인 후 1개월 후 확인**
   - 로그인 후 앱을 1개월 동안 사용하지 않음
   - 1개월 후 앱 실행 시 자동으로 세션 갱신되어 로그인 상태 유지

2. **세션 갱신 로그 확인**
   - 앱 실행 시 콘솔에서 "세션 갱신 시도" 로그 확인
   - 갱신 성공 시 "세션 갱신 완료" 로그 확인

## 주의사항

1. **Supabase 대시보드 설정 필수**
   - JWT 만료 시간을 1주일로 설정하지 않으면 1시간 후 만료됨
   - Refresh token rotation이 비활성화되어 있으면 세션 유지 시간이 단축됨

2. **보안 고려사항**
   - 1개월 세션 유지는 사용자 편의성을 위한 설정
   - 보안이 중요한 경우 더 짧은 세션 시간을 고려

3. **네트워크 연결 필요**
   - 세션 갱신은 네트워크 연결이 필요함
   - 오프라인 상태에서는 세션 갱신 불가

## 관련 파일

- `lib/features/auth/presentation/providers/auth_provider.dart` - 세션 갱신 로직
- `lib/features/splash/presentation/screens/splash_screen.dart` - 앱 시작 시 세션 갱신
- `supabase/config.toml` - 로컬 개발 환경 설정 (참고용)

## 참고 자료

- [Supabase Auth 문서](https://supabase.com/docs/guides/auth)
- [Supabase Session Management](https://supabase.com/docs/guides/auth/sessions)

