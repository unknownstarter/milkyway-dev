# 🚀 배포 전 체크리스트 (Deployment Checklist)

## 📋 개요
리팩토링된 dev 버전을 기존 milkyway 프로젝트로 배포하기 전 확인해야 할 사항들입니다.

---

## 1️⃣ 앱 식별자 (App Identifiers)

### 현재 설정 (dev 버전)
- **Package Name (pubspec.yaml)**: `whatif_milkyway_app`
- **Android Application ID**: `com.whatif.milkyway.android`
- **iOS Bundle Identifier**: `com.whatif.milkyway.whatifMilkywayApp`
- **iOS Display Name**: `Whatif Milkyway App`

### ✅ 확인 사항
- [ ] 기존 프로젝트의 Android Application ID 확인
- [ ] 기존 프로젝트의 iOS Bundle Identifier 확인
- [ ] 기존 프로젝트의 앱 이름 확인
- [ ] **변경 필요 시 다음 파일 수정:**
  - `pubspec.yaml` - `name` 필드
  - `android/app/build.gradle` - `applicationId`
  - `ios/Runner.xcodeproj/project.pbxproj` - `PRODUCT_BUNDLE_IDENTIFIER`
  - `ios/Runner/Info.plist` - `CFBundleDisplayName`, `CFBundleName`
  - `macos/Runner/Configs/AppInfo.xcconfig` - `PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`

---

## 2️⃣ 앱 버전 (App Version)

### 현재 설정
- **Version**: `0.0.2+0` (pubspec.yaml)
  - Version Name: `0.0.2`
  - Build Number: `0`

### ✅ 확인 사항
- [ ] 기존 프로젝트의 현재 버전 확인
- [ ] 배포할 버전 결정 (예: `1.0.0+1`)
- [ ] **변경 필요 시 다음 파일 수정:**
  - `pubspec.yaml` - `version` 필드
  - (Android/iOS는 pubspec.yaml에서 자동으로 가져옴)

---

## 3️⃣ 앱 아이콘 (App Icon)

### 현재 상태
- ✅ `assets/images/app_icon.png` 존재
- ✅ `flutter_launcher_icons` 설정 완료
- ✅ Android/iOS 아이콘 생성 완료

### ✅ 확인 사항
- [ ] 기존 프로젝트의 앱 아이콘과 동일한지 확인
- [ ] 필요 시 `assets/images/app_icon.png` 교체
- [ ] 교체 후 `dart run flutter_launcher_icons` 재실행

---

## 4️⃣ 앱 서명 (App Signing)

### Android
- **Keystore 파일**: `android/app/key.properties` 참조
- **Signing Config**: `android/app/build.gradle`의 `signingConfigs.release`

### ✅ 확인 사항
- [ ] 기존 프로젝트의 `key.properties` 파일 확인
- [ ] 기존 프로젝트의 keystore 파일 위치 확인
- [ ] **변경 필요 시:**
  - `android/app/key.properties` 파일 복사 또는 생성
  - keystore 파일 경로 확인

### iOS
- **Development Team**: `U8354289DY`
- **Code Signing**: Xcode 프로젝트 설정

### ✅ 확인 사항
- [ ] 기존 프로젝트의 Development Team 확인
- [ ] 기존 프로젝트의 Provisioning Profile 확인
- [ ] **변경 필요 시:**
  - `ios/Runner.xcodeproj/project.pbxproj` - `DEVELOPMENT_TEAM`
  - Xcode에서 Provisioning Profile 재설정

---

## 5️⃣ 환경 변수 및 설정 파일

### ✅ 확인 사항
- [ ] `.env` 파일 확인 (Supabase URL, API Key 등)
- [ ] `android/app/google-services.json` 확인 (Firebase 설정)
- [ ] `ios/Runner/GoogleService-Info.plist` 확인 (Firebase 설정)
- [ ] 기존 프로젝트의 환경 변수와 동일한지 확인

### 파일 위치
- `.env` (프로젝트 루트)
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

---

## 6️⃣ Supabase 설정

### ✅ 확인 사항
- [ ] Supabase 프로젝트 URL 확인
- [ ] Supabase Anon Key 확인
- [ ] Supabase Service Role Key 확인 (필요 시)
- [ ] `.env` 파일의 Supabase 설정 확인
- [ ] 기존 프로젝트와 동일한 Supabase 프로젝트 사용하는지 확인

---

## 7️⃣ Firebase 설정

### ✅ 확인 사항
- [ ] Firebase 프로젝트 ID 확인
- [ ] `android/app/google-services.json` 확인
- [ ] `ios/Runner/GoogleService-Info.plist` 확인
- [ ] Firebase Analytics 설정 확인
- [ ] 기존 프로젝트와 동일한 Firebase 프로젝트 사용하는지 확인

---

## 8️⃣ GitHub 저장소

### 현재 상태
- **Repository**: `milkyway-dev` (dev 버전)

### ✅ 확인 사항
- [ ] 기존 프로젝트의 GitHub 저장소 URL 확인
- [ ] 기존 프로젝트의 브랜치 구조 확인 (main, develop 등)
- [ ] **변경 필요 시:**
  ```bash
  # 원격 저장소 변경
  git remote set-url origin <기존_프로젝트_저장소_URL>
  
  # 또는 새로운 원격 추가
  git remote add production <기존_프로젝트_저장소_URL>
  ```

---

## 9️⃣ 앱 스토어 정보

### Google Play Store (Android)
- [ ] 기존 앱의 Package Name 확인
- [ ] 기존 앱의 버전 코드 확인
- [ ] 기존 앱의 서명 키 확인

### App Store (iOS)
- [ ] 기존 앱의 Bundle ID 확인
- [ ] 기존 앱의 버전 확인
- [ ] 기존 앱의 App Store Connect 설정 확인

---

## 🔟 빌드 및 테스트

### ✅ 배포 전 테스트
- [ ] Android Debug 빌드 테스트
- [ ] Android Release 빌드 테스트
- [ ] iOS Debug 빌드 테스트
- [ ] iOS Release 빌드 테스트
- [ ] 주요 기능 동작 확인
  - [ ] 로그인/회원가입
  - [ ] 책 검색 및 등록
  - [ ] 메모 작성/수정/삭제
  - [ ] 프로필 수정
  - [ ] 네비게이션

### 빌드 명령어
```bash
# Android
flutter clean
flutter build apk --release
# 또는
flutter build appbundle --release

# iOS
flutter clean
flutter build ios --release
```

---

## 1️⃣1️⃣ 배포 단계

### 1단계: 설정 확인 및 변경
1. 위의 체크리스트를 모두 확인
2. 필요한 설정 파일들을 기존 프로젝트와 동일하게 변경
3. 버전 번호 업데이트

### 2단계: 코드 병합
1. 기존 프로젝트의 최신 코드 확인
2. 필요한 경우 기존 프로젝트의 특정 설정/파일 유지
3. 리팩토링된 코드 병합

### 3단계: 테스트
1. 로컬에서 빌드 및 테스트
2. 주요 기능 동작 확인
3. 버그 수정

### 4단계: GitHub 업로드
1. 변경사항 커밋
2. 기존 프로젝트 저장소에 푸시
3. Pull Request 생성 (필요 시)

### 5단계: 앱 스토어 배포
1. Android: Google Play Console에 업로드
2. iOS: App Store Connect에 업로드
3. 스토어 리뷰 대기

---

## 📝 체크리스트 요약

### 필수 확인 사항
- [ ] 앱 식별자 (Package Name, Bundle ID)
- [ ] 앱 버전
- [ ] 앱 서명 (Android keystore, iOS certificates)
- [ ] 환경 변수 (.env)
- [ ] Supabase 설정
- [ ] Firebase 설정
- [ ] GitHub 저장소

### 선택 확인 사항
- [ ] 앱 아이콘
- [ ] 앱 이름
- [ ] 스플래시 스크린
- [ ] 푸시 알림 설정
- [ ] 딥링크 설정

---

## 🚨 주의사항

1. **앱 식별자 변경 시**: 기존 사용자 데이터와의 연동 문제가 발생할 수 있습니다.
2. **버전 번호**: 기존 앱의 버전보다 높아야 합니다.
3. **서명 키**: Android keystore 파일을 잃어버리면 업데이트가 불가능합니다.
4. **환경 변수**: `.env` 파일은 절대 Git에 커밋하지 마세요.
5. **백업**: 배포 전 기존 프로젝트의 백업을 생성하세요.

---

## 📞 참고 자료

- [Flutter 배포 가이드](https://docs.flutter.dev/deployment)
- [Android 앱 서명](https://developer.android.com/studio/publish/app-signing)
- [iOS 앱 배포](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

---

**마지막 업데이트**: 2025-11-18

