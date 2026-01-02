# iOS Push Notification 설정 가이드

**작성일:** 2026-01-02

## ✅ 완료된 작업

### 1. entitlements 파일 설정
- ✅ `ios/Runner/Runner.entitlements`에 `aps-environment` 추가 완료
- ✅ `ios/Runner/Info.plist`에 `UIBackgroundModes` → `remote-notification` 추가 완료

---

## 🔧 Xcode에서 추가 설정 필요

### ⚠️ 최신 Xcode (15+) 참고사항

**최신 Xcode에서는 Push Notifications capability가 자동으로 처리되거나, entitlements 파일에 `aps-environment`만 있으면 충분할 수 있습니다.**

현재 설정 상태:
- ✅ `Runner.entitlements`에 `aps-environment` 추가 완료
- ✅ `Info.plist`에 `UIBackgroundModes` → `remote-notification` 추가 완료

**만약 Xcode에서 Push Notifications capability를 찾을 수 없다면:**
1. **entitlements 파일만으로 충분할 수 있습니다** - Firebase SDK가 자동으로 처리합니다
2. 또는 **Background Modes capability**를 추가하고 **Remote notifications**를 체크하세요

---

### Step 1: Background Modes Capability 추가 (선택 사항)

**Push Notifications capability를 찾을 수 없는 경우:**

1. **Xcode에서 프로젝트 열기**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Runner 타겟 선택**
   - 왼쪽 네비게이터에서 **Runner** 프로젝트 선택
   - **TARGETS** → **Runner** 선택

3. **Signing & Capabilities 탭**
   - 상단 탭에서 **Signing & Capabilities** 클릭

4. **Background Modes Capability 추가**
   - **+ Capability** 버튼 클릭
   - 검색창에 "Background Modes" 입력
   - **Background Modes** 선택하여 추가
   - 추가된 **Background Modes** 섹션에서 **Remote notifications** 체크박스 선택

**또는:**

**entitlements 파일만으로 충분합니다** - 현재 설정으로도 작동할 수 있습니다:
- ✅ `Runner.entitlements`에 `aps-environment` 추가 완료
- ✅ `Info.plist`에 `UIBackgroundModes` → `remote-notification` 추가 완료

**확인 사항:**
- `Runner.entitlements` 파일에 `aps-environment`가 `production` 또는 `development`로 설정되어 있는지 확인

---

## 🔑 APNs 인증 키 생성 및 Firebase 업로드

### Step 2: Apple Developer Portal에서 APNs 인증 키 생성

1. **Apple Developer Portal 접속**
   - [Apple Developer Portal - Keys](https://developer.apple.com/account/resources/authkeys/list) 접속
   - Apple ID로 로그인

2. **새 키 생성**
   - **+ (플러스)** 버튼 클릭
   - **Key Name** 입력 (예: "milkyway-push-notifications")
   - **Apple Push Notifications service (APNs)** 체크박스 선택
   - **Continue** 클릭
   - **Register** 클릭

3. **키 다운로드**
   - **Download** 버튼 클릭하여 `.p8` 파일 다운로드
   - ⚠️ **중요**: 이 파일은 한 번만 다운로드 가능하므로 안전한 곳에 보관하세요
   - **Key ID** 복사 (나중에 필요)

4. **Team ID 확인**
   - Apple Developer Portal → **Membership** 섹션
   - **Team ID** 확인 및 복사

---

### Step 3: Firebase Console에 APNs 인증 키 업로드

1. **Firebase Console 접속**
   - [Firebase Console](https://console.firebase.google.com/) 접속
   - 프로젝트 선택: `milkyway-app-f0848`

2. **프로젝트 설정 열기**
   - 왼쪽 상단 ⚙️ 아이콘 클릭
   - **프로젝트 설정** 선택

3. **Cloud Messaging 탭**
   - 상단 탭에서 **Cloud Messaging** 선택

4. **APNs 인증 키 업로드**
   - **Apple app configuration** 섹션 찾기
   - **APNs Authentication Key** 섹션에서:
     - **Upload** 버튼 클릭
     - 다운로드한 `.p8` 파일 선택
     - **Key ID** 입력 (Apple Developer Portal에서 복사한 값)
     - **Team ID** 입력 (Apple Developer Portal → Membership에서 확인)
     - **Upload** 클릭

**확인 사항:**
- 업로드 후 "APNs Authentication Key uploaded successfully" 메시지 확인

---

## ✅ 설정 완료 확인

### 1. Xcode에서 확인
- `Runner.entitlements` 파일에 `aps-environment` 키가 있는지 확인
- (선택 사항) Xcode → Signing & Capabilities에서 "Background Modes" capability가 추가되어 있고 "Remote notifications"가 체크되어 있는지 확인
  - **참고**: 최신 Xcode에서는 Push Notifications capability가 자동으로 처리되거나 entitlements 파일만으로 충분할 수 있습니다

### 2. Firebase Console에서 확인
- Firebase Console → 프로젝트 설정 → Cloud Messaging
- **APNs Authentication Key** 섹션에 업로드된 키 정보가 표시되는지 확인

### 3. 앱에서 테스트
- iOS 기기에서 앱 실행
- 로그인 후 알림 권한 허용
- FCM 토큰이 정상적으로 등록되는지 확인
- 다른 사용자가 공개 메모를 작성했을 때 알림이 수신되는지 확인

---

## ⚠️ 주의사항

### APNs 인증 키 보안
- `.p8` 파일은 절대 Git에 커밋하지 마세요
- 안전한 곳에 백업 보관하세요
- 키가 유출되면 즉시 Apple Developer Portal에서 삭제하고 새로 생성하세요

### 프로덕션 vs 개발 환경
- APNs 인증 키는 프로덕션과 개발 환경 모두에서 사용 가능합니다
- `aps-environment`는 Xcode 빌드 설정에 따라 자동으로 설정됩니다:
  - **Debug**: `development`
  - **Release**: `production`

### 이전 APNs 인증서 사용 시
- 이전에 APNs 인증서를 사용했다면, 인증 키로 마이그레이션하는 것이 권장됩니다
- 인증 키는 인증서보다 관리가 쉽고 만료되지 않습니다

---

## 🔄 문제 해결

### 알림이 수신되지 않는 경우

1. **Xcode 설정 확인**
   - Push Notifications capability가 추가되어 있는지 확인
   - `Runner.entitlements`에 `aps-environment`가 있는지 확인

2. **Firebase Console 확인**
   - APNs 인증 키가 올바르게 업로드되었는지 확인
   - Key ID와 Team ID가 정확한지 확인

3. **앱 권한 확인**
   - iOS 설정 → milkyway → 알림 권한이 허용되어 있는지 확인
   - 앱 내에서 알림 설정이 ON인지 확인

4. **FCM 토큰 확인**
   - Supabase `users` 테이블에서 `fcm_token`이 등록되어 있는지 확인
   - `notification_enabled`가 `true`인지 확인

5. **기기 확인**
   - 실제 iOS 기기에서 테스트 (시뮬레이터는 푸시 알림을 지원하지 않음)
   - 인터넷 연결 확인

---

## 📚 참고 문서

- [Firebase Cloud Messaging iOS 설정](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [Apple Push Notification Service](https://developer.apple.com/documentation/usernotifications)
- [APNs 인증 키 생성 가이드](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/establishing_a_token-based_connection_to_apns)

