# FCM 서비스 계정 키 설정 가이드 (단계별)

**작성일:** 2026-01-02

## ✅ Edge Function 업데이트 완료

FCM HTTP v1 API를 사용하도록 Edge Function이 업데이트되었습니다.

---

## 📋 단계별 설정 방법

### Step 1: Firebase Console에서 서비스 계정 키 다운로드

1. [Firebase Console](https://console.firebase.google.com/) 접속
2. 프로젝트: `milkyway-app-f0848` 선택
3. **프로젝트 설정 (⚙️)** → **서비스 계정** 탭
4. **"새 비공개 키 만들기"** 버튼 클릭
5. JSON 파일이 자동으로 다운로드됩니다

---

### Step 2: Supabase Dashboard에서 Secret 설정

1. [Supabase Dashboard](https://supabase.com/dashboard/project/hyjgfgzexvxhgfmqgiqu) 접속
2. 왼쪽 메뉴에서 **Settings** 클릭
3. **Edge Functions** 섹션에서 **Secrets** 클릭
4. **Add new secret** 버튼 클릭

---

### Step 3: Secret 정보 입력

#### 방법 1: JSON 전체 내용 그대로 붙여넣기 (권장)

1. **Name**: `FCM_SERVICE_ACCOUNT_JSON` 입력
2. **Value**: 다운로드한 JSON 파일의 **전체 내용**을 복사하여 붙여넣기
   - JSON 파일을 텍스트 에디터로 열기
   - 전체 내용 선택 (Ctrl+A / Cmd+A)
   - 복사 (Ctrl+C / Cmd+C)
   - Supabase Secrets의 Value 필드에 붙여넣기 (Ctrl+V / Cmd+V)

**예시:**
```
{
  "type": "service_account",
  "project_id": "milkyway-app-f0848",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "...",
  ...
}
```

**✅ 이 방법이 가장 간단하고 안전합니다!**

---

#### 방법 2: JSON을 한 줄로 변환 (선택적)

터미널에서 다음 명령어 실행:
```bash
# JSON 파일을 한 줄로 변환
cat path/to/service-account-key.json | jq -c .
```

출력된 한 줄 JSON을 복사하여 Value에 붙여넣기

---

### Step 4: 저장 및 확인

1. **Save** 버튼 클릭
2. Secret 목록에 `FCM_SERVICE_ACCOUNT_JSON`이 추가되었는지 확인

---

## ✅ 설정 확인

### Edge Function 테스트

설정 후 Edge Function이 정상 작동하는지 테스트:

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
- 설정이 올바른 경우:
  ```json
  {
    "success": true,
    "tokens_count": 0,
    "success_count": 0,
    "failure_count": 0,
    "message": "알림 전송 완료: 0개 성공, 0개 실패"
  }
  ```
  (테스트이므로 토큰이 없어서 0개가 정상입니다)

- 설정이 잘못된 경우:
  ```json
  {
    "success": false,
    "tokens_count": 0,
    "message": "FCM_SERVICE_ACCOUNT_JSON 환경 변수가 설정되지 않았습니다."
  }
  ```

---

## ⚠️ 주의사항

### 1. JSON 형식 확인
- JSON 파일의 전체 내용을 복사해야 합니다
- 중괄호 `{` `}` 포함하여 전체를 복사
- `private_key`의 줄바꿈(`\n`)은 그대로 유지되어야 합니다

### 2. 보안
- 서비스 계정 키는 매우 민감한 정보입니다
- 절대 Git에 커밋하지 마세요
- 공유하지 마세요
- 정기적으로 키를 로테이션하세요

### 3. JSON 파싱 오류 발생 시
- JSON 형식이 올바른지 확인
- 특수 문자가 올바르게 이스케이프되었는지 확인
- Supabase Dashboard에서 Secret을 다시 확인

---

## 🔍 문제 해결

### 문제: "FCM_SERVICE_ACCOUNT_JSON 환경 변수가 설정되지 않았습니다"
**해결:**
1. Supabase Dashboard → Settings → Edge Functions → Secrets 확인
2. `FCM_SERVICE_ACCOUNT_JSON`이 존재하는지 확인
3. 이름이 정확히 `FCM_SERVICE_ACCOUNT_JSON`인지 확인 (대소문자 구분)

### 문제: "서비스 계정 JSON 파싱 실패"
**해결:**
1. JSON 파일의 전체 내용이 복사되었는지 확인
2. JSON 형식이 올바른지 확인 (중괄호, 따옴표 등)
3. `private_key`의 줄바꿈(`\n`)이 올바르게 포함되었는지 확인

### 문제: "OAuth2 토큰 획득 실패"
**해결:**
1. 서비스 계정 키가 올바른지 확인
2. Firebase 프로젝트가 활성화되어 있는지 확인
3. 서비스 계정에 필요한 권한이 있는지 확인

---

## 📚 참고 자료

- [Firebase 서비스 계정 문서](https://firebase.google.com/docs/admin/setup)
- [FCM HTTP v1 API 문서](https://firebase.google.com/docs/cloud-messaging/migrate-v1)
- [Supabase Edge Functions Secrets](https://supabase.com/docs/guides/functions/secrets)

