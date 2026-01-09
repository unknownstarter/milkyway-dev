# FCM 서버 키 설정 가이드

**작성일:** 2026-01-02

## ✅ Edge Function 배포 완료

`notify-new-public-memo` Edge Function이 성공적으로 배포되었습니다.

---

## 🔑 FCM 서비스 계정 키 가져오기

**⚠️ 중요:** Firebase가 2024년 6월 20일부터 레거시 API를 중단했습니다. 이제는 **서비스 계정 키**를 사용해야 합니다.

### 1. Firebase Console 접속
1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트 선택: `milkyway-app-f0848`

### 2. 서비스 계정 키 다운로드
1. Firebase Console → **프로젝트 설정 (⚙️)** → **서비스 계정** 탭
2. "서비스 계정" 섹션에서 **"새 비공개 키 만들기"** 버튼 클릭
3. JSON 파일이 자동으로 다운로드됩니다
4. 다운로드된 JSON 파일의 **전체 내용**을 복사합니다

**JSON 파일 예시:**
```json
{
  "type": "service_account",
  "project_id": "milkyway-app-f0848",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-...@milkyway-app-f0848.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

**⚠️ 참고:**
- 서비스 계정 키는 매우 민감한 정보입니다
- 절대 Git에 커밋하지 마세요
- 정기적으로 키를 로테이션하세요

---

## 🔧 Supabase에 서비스 계정 키 설정

### 방법 1: Supabase Dashboard 사용 (권장)

1. [Supabase Dashboard](https://supabase.com/dashboard/project/hyjgfgzexvxhgfmqgiqu) 접속
2. **Settings** → **Edge Functions** → **Secrets** 이동
3. **Add new secret** 클릭
4. 다음 정보 입력:
   - **Name**: `FCM_SERVICE_ACCOUNT_JSON`
   - **Value**: 다운로드한 JSON 파일의 **전체 내용**을 그대로 복사하여 붙여넣기
     - JSON 파일을 텍스트 에디터로 열기
     - 전체 내용 선택 (Ctrl+A / Cmd+A) → 복사 (Ctrl+C / Cmd+C)
     - Value 필드에 붙여넣기 (Ctrl+V / Cmd+V)
     - **줄바꿈 포함하여 그대로 붙여넣어도 됩니다!**
5. **Save** 클릭

**✅ 가장 간단한 방법: JSON 파일 전체 내용을 그대로 복사하여 붙여넣기**

### 방법 2: Supabase CLI 사용

```bash
# JSON 파일을 한 줄로 변환하여 설정
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat path/to/service-account-key.json | jq -c .)"

# 또는 직접 JSON 내용 입력
supabase secrets set FCM_SERVICE_ACCOUNT_JSON='{"type":"service_account",...}'

# 확인
supabase secrets list
```

**⚠️ 주의:**
- JSON 파일의 전체 내용을 한 줄로 변환하여 설정해야 합니다
- 줄바꿈(`\n`)은 `\\n`으로 이스케이프되거나, 한 줄로 변환해야 합니다

---

## ✅ 설정 확인

### Edge Function 테스트

배포된 Edge Function이 정상 작동하는지 테스트:

```bash
curl -X POST https://hyjgfgzexvxhgfmqgiqu.supabase.co/functions/v1/notify-new-public-memo \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": "test-book-id",
    "memo_id": "test-memo-id",
    "memo_content": "테스트 메모 내용",
    "memo_author_nickname": "테스트 사용자",
    "memo_author_id": "test-author-id"
  }'
```

**예상 응답:**
- `FCM_SERVICE_ACCOUNT_JSON`가 설정되지 않은 경우:
  ```json
  {
    "success": false,
    "tokens_count": 0,
    "message": "FCM_SERVICE_ACCOUNT_JSON 환경 변수가 설정되지 않았습니다."
  }
  ```

- `FCM_SERVICE_ACCOUNT_JSON`가 설정된 경우:
  ```json
  {
    "success": true,
    "tokens_count": 1,
    "success_count": 1,
    "failure_count": 0,
    "message": "알림 전송 완료: 1개 성공, 0개 실패"
  }
  ```

---

## 🧪 전체 플로우 테스트

### 1. 사용자 A 설정
- [ ] 앱에서 로그인
- [ ] 알림 권한 허용
- [ ] 책 저장
- [ ] Profile → 알림 설정 ON 확인

### 2. 사용자 B 설정
- [ ] 다른 기기/계정으로 로그인
- [ ] 같은 책에 공개 메모 작성

### 3. 알림 수신 확인
- [ ] 사용자 A 기기에서 알림 수신 확인
- [ ] 알림 탭 시 메모 상세 화면으로 이동 확인

---

## ⚠️ 문제 해결

### 문제: "FCM_SERVICE_ACCOUNT_JSON 환경 변수가 설정되지 않았습니다"
**해결:**
1. Supabase Dashboard에서 Secrets 확인
2. `FCM_SERVICE_ACCOUNT_JSON`가 올바르게 설정되었는지 확인
3. JSON 형식이 올바른지 확인 (전체 JSON이 한 줄로 되어 있어야 함)
4. Edge Function 재배포 (필요 시)

### 문제: "서비스 계정 JSON 파싱 실패"
**해결:**
1. JSON 파일의 전체 내용이 올바른지 확인
2. JSON을 한 줄로 변환했는지 확인
3. 특수 문자 이스케이프 확인

### 문제: 알림이 수신되지 않음
**확인 사항:**
1. 사용자의 `fcm_token`이 `users` 테이블에 저장되어 있는지
2. 사용자의 `notification_enabled`가 `true`인지
3. 사용자가 해당 책을 저장했는지 (`user_books` 테이블)
4. 메모 작성자가 아닌지 (자신의 메모에는 알림 안 옴)
5. FCM 서버 키가 올바른지

### 문제: 알림은 수신되지만 딥링크가 작동하지 않음
**확인 사항:**
1. `lib/main.dart`에서 `onNotificationTapped` 콜백이 설정되었는지
2. 알림 데이터에 `memo_id`가 포함되어 있는지
3. `AppRoutes.memoDetailName`이 올바른지

---

## 📚 참고 자료

- [Firebase Cloud Messaging 문서](https://firebase.google.com/docs/cloud-messaging)
- [FCM HTTP API 문서](https://firebase.google.com/docs/cloud-messaging/http-server-ref)
- [Supabase Edge Functions Secrets](https://supabase.com/docs/guides/functions/secrets)

