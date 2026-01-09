# Notification 시스템 빠른 테스트 가이드

**작성일:** 2026-01-02

## 🚀 빠른 테스트 (5분)

### Step 1: 앱에서 FCM 토큰 등록 확인

1. **앱 실행 및 로그인**
2. **알림 권한 허용** (로그인 시 다이얼로그 또는 Profile → 알림 설정)
3. **Profile 화면** → **알림 설정** 확인 (ON 상태)

### Step 2: 데이터베이스에서 확인

Supabase Dashboard → SQL Editor에서 실행:

```sql
-- FCM 토큰이 등록되었는지 확인
SELECT id, fcm_token IS NOT NULL as has_token, notification_enabled 
FROM users 
ORDER BY updated_at DESC 
LIMIT 5;
```

**예상 결과:**
- `has_token = true`: FCM 토큰이 등록됨 ✅
- `has_token = false`: FCM 토큰이 아직 등록되지 않음 (알림 권한 허용 필요)

### Step 3: 실제 알림 테스트

**시나리오:**
1. **사용자 A**: 책 저장 + 알림 권한 허용
2. **사용자 B**: 같은 책에 공개 메모 작성
3. **사용자 A**: 알림 수신 확인

---

## ✅ 테스트 완료 기준

- [ ] Edge Function이 정상적으로 호출됨
- [ ] FCM 서비스 계정 키가 올바르게 파싱됨
- [ ] OAuth2 토큰이 정상적으로 획득됨
- [ ] FCM v1 API 호출이 성공함
- [ ] 실제 알림이 수신됨 (FCM 토큰이 있는 경우)
- [ ] 알림 탭 시 메모 상세 화면으로 이동함

---

## 🔍 로그 확인

Supabase Dashboard → Logs → Edge Functions에서 `notify-new-public-memo` 로그 확인:

**정상적인 로그:**
```
알림 전송 완료: 성공 1개, 실패 0개
```

**오류 로그:**
```
FCM_SERVICE_ACCOUNT_JSON가 설정되지 않았습니다.
서비스 계정 JSON 파싱 실패
OAuth2 토큰 획득 실패
```

---

## 💡 팁

- **FCM 토큰이 없으면**: 앱에서 알림 권한을 허용하고 Profile → 알림 설정을 ON으로 설정
- **알림이 수신되지 않으면**: 기기가 백그라운드에 있는지 확인 (포그라운드에서는 로컬 알림으로 표시)
- **Edge Function 오류**: Supabase Dashboard → Logs에서 상세 오류 확인

