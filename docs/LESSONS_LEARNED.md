# 📚 학습 내용 및 레슨런 (Lessons Learned)

## 📋 개요

이 문서는 Milkyway 앱 개발 과정에서 배운 교훈과 실수를 기록하여 향후 유사한 문제를 방지하고, 더 나은 개발을 위한 가이드로 활용합니다.

**최종 업데이트:** 2025-11-20  
**작성자:** AI Assistant  
**검토자:** 개발팀

---

## 🎯 2025-11-19: 메모 프로필 정보 동기화

### 문제 상황
메모에 표시되는 프로필 이미지와 닉네임이 변경된 값으로 반영되지 않았습니다. 프로필을 업데이트해도 메모 목록에는 이전 정보가 그대로 표시되었습니다.

### 원인 분석
1. **Supabase 조인 결과 처리 미흡**: `Memo.fromJson`에서 `users` 조인 결과를 객체로만 가정하여, 배열로 반환될 경우 처리하지 못함
2. **Provider 무효화 누락**: 프로필 업데이트 시 메모 관련 provider를 무효화하지 않아 캐시된 데이터가 계속 표시됨

### 해결 과정
1. **`Memo.fromJson` 개선**: Supabase 조인 결과가 배열 또는 객체일 수 있음을 인지하고, 두 경우를 모두 처리하도록 수정
2. **Provider 무효화 추가**: `updateProfile` 메서드에서 메모 관련 provider들(`recentMemosProvider`, `homeRecentMemosProvider`, `allMemosProvider`, `paginatedMemosProvider`)을 무효화하여 최신 프로필 정보가 반영되도록 수정

### 배운 점
- **Supabase 조인 결과는 예측 불가능**: 같은 쿼리라도 상황에 따라 배열 또는 객체로 반환될 수 있으므로, 항상 두 경우를 모두 처리해야 함
- **데이터 변경 시 관련 Provider 무효화 필수**: 한 곳에서 데이터를 변경하면, 해당 데이터를 표시하는 모든 화면의 provider를 무효화해야 최신 정보가 반영됨
- **명시적 파라미터 전달**: null 값을 전달할 때도 명시적으로 전달하여 코드의 의도를 명확히 하는 것이 좋음

### 실수
- 처음에는 `users` 조인 결과를 객체로만 가정하여 타입 캐스팅 에러 발생 가능성 무시
- 프로필 업데이트 시 메모 provider 무효화를 고려하지 않음

---

## 🎯 2025-11-19: My Memo 화면 데이터 로딩

### 문제 상황
My Memo 화면에서 필터(모든/공개/비공개)를 사용했을 때 아무것도 표시되지 않았습니다.

### 원인 분석
`memo_list_screen.dart`에서 `MemoList()`를 호출할 때 `bookId`를 명시적으로 전달하지 않아, 기본값(null)에 의존하고 있었습니다. 이로 인해 `paginatedMemosProvider`가 올바르게 초기화되지 않았을 가능성이 있었습니다.

### 해결 과정
`MemoList(bookId: null)`을 명시적으로 전달하여 모든 책의 메모를 불러오도록 수정했습니다.

### 배운 점
- **명시적 파라미터 전달의 중요성**: 기본값에 의존하기보다는 명시적으로 파라미터를 전달하여 코드의 의도를 명확히 하는 것이 좋음
- **null 값도 명시적으로 전달**: null을 전달할 때도 명시적으로 전달하면 코드 가독성이 향상됨

---

## 🎯 2025-11-19: 홈 화면 단일 책 확대 효과

### 문제 상황
홈 화면에서 책이 하나만 있을 때 "읽고 있는 책" 섹션의 책이 확대되지 않았습니다. 여러 책이 있을 때는 중앙에 있는 책이 1.3배 확대되어 표시되었지만, 책이 하나만 있을 때는 확대 효과가 없었습니다.

### 원인 분석
`_SingleBookView`는 책이 하나일 때 사용되는 위젯인데, `_AnimatedBookItem`과 달리 `Transform.scale`을 사용하지 않아 확대 효과가 없었습니다.

### 해결 과정
`_SingleBookView`에도 `Transform.scale(scale: 1.3)`을 적용하여 여러 책일 때와 동일한 확대 효과를 제공하도록 수정했습니다.

### 배운 점
- **일관된 UI/UX 유지**: 조건에 따라 다른 위젯을 사용하더라도, 시각적 효과는 일관되게 유지해야 함
- **단일 케이스도 고려**: 여러 항목과 단일 항목 모두 동일한 사용자 경험을 제공해야 함

---

## 🎯 2025-11-20: Bundle ID 불일치로 인한 App Store Connect 연결 실패

### 문제 상황
Xcode에서 Archive를 생성하고 Distribute App을 시도했을 때, Xcode가 기존 App Store Connect의 "milkyway" 앱을 인식하지 못하고 새로운 앱을 만들려고 했습니다. "Runner"로 Archive가 생성되어 기존 앱과 연결되지 않았습니다.

### 원인 분석
1. **Bundle ID 불일치**: 프로젝트의 Bundle ID가 `com.whatif.milkyway.whatifMilkywayApp`로 설정되어 있었지만, App Store Connect의 실제 앱은 `com.whatif.milkyway`를 사용하고 있었습니다.
2. **Xcode 서명 설정 누락**: `CODE_SIGN_STYLE = Automatic`이 Runner 타겟에 설정되지 않아 자동 서명이 제대로 작동하지 않았습니다.

### 해결 과정
1. **Bundle ID 수정**: `project.pbxproj`에서 모든 Bundle ID를 `com.whatif.milkyway`로 변경
2. **Xcode 서명 설정 추가**: Debug, Release, Profile 빌드 설정에 `CODE_SIGN_STYLE = Automatic` 추가
3. **Scheme 이름 변경**: `Runner.xcscheme`를 `milkyway.xcscheme`로 변경하여 Archive 이름 개선

### 배운 점
- **Bundle ID는 App Store Connect와 정확히 일치해야 함**: Bundle ID가 다르면 Xcode가 다른 앱으로 인식하여 새 앱을 만들려고 시도함
- **기존 프로젝트 리팩토링 시 Bundle ID 확인 필수**: 프로젝트를 리팩토링할 때도 기존 App Store Connect의 Bundle ID를 확인하고 일치시켜야 함
- **Xcode 서명 설정 확인**: 자동 서명이 제대로 작동하려면 `CODE_SIGN_STYLE = Automatic`이 명시적으로 설정되어 있어야 함
- **Archive 이름은 Scheme 이름을 따름**: Scheme 이름을 변경하면 Archive 이름도 변경되어 App Store Connect 연결이 더 명확해짐

### 실수
- Bundle ID를 확인하지 않고 프로젝트를 진행함
- App Store Connect의 실제 Bundle ID를 확인하지 않음
- Xcode 서명 설정이 누락되어 있음을 간과함

---

## 🎯 2025-11-20: iOS Launch Screen과 Flutter 스플래시 화면의 차이

### 문제 상황
TestFlight에서 실제 디바이스로 앱을 다운로드했을 때, 스플래시 화면 대신 하얀색 화면이 나타났습니다.

### 원인 분석
1. **iOS Launch Screen은 네이티브 레벨**: iOS Launch Screen은 Flutter 엔진이 로드되기 전에 네이티브 레벨에서 표시되는 정적 화면입니다.
2. **배경색이 흰색으로 설정**: `LaunchScreen.storyboard`의 배경색이 흰색(`red="1" green="1" blue="1"`)으로 설정되어 있었습니다.
3. **Flutter 스플래시는 엔진 로드 후**: Flutter 위젯 스플래시 화면은 Flutter 엔진이 로드된 후에 표시되므로, Launch Screen이 먼저 보입니다.

### 해결 과정
1. **Launch Screen 배경색 변경**: `LaunchScreen.storyboard`의 배경색을 검은색(`red="0" green="0" blue="0"`)으로 변경
2. **Flutter 스플래시 표시 시간 보장**: Flutter 스플래시 화면이 최소 1.5초 동안 표시되도록 지연 추가
3. **애니메이션 개선**: Flutter 스플래시 화면의 페이드 인 애니메이션을 더 부드럽게 개선

### 배운 점
- **iOS Launch Screen은 정적 이미지만 가능**: Flutter 엔진이 로드되기 전에 표시되므로 애니메이션이나 동적 콘텐츠 불가능
- **두 단계 스플래시 화면**: iOS 앱은 Launch Screen(네이티브) → Flutter 스플래시(위젯) 순서로 표시됨
- **배경색 일치 중요**: Launch Screen과 Flutter 스플래시의 배경색을 일치시켜야 자연스러운 전환 가능
- **TestFlight에서 확인 필수**: 시뮬레이터와 실제 디바이스의 Launch Screen 동작이 다를 수 있으므로 TestFlight에서 반드시 확인해야 함

---

## 🎯 2025-11-20: 하단 네비게이션 바 클릭 영역 확대와 오버플로우

### 문제 상황
하단 네비게이션 바의 클릭 영역을 넓히기 위해 `Expanded`, `Material`, `InkWell`을 사용하고 padding과 아이콘 크기를 늘렸더니 "OVERFLOWED BY 12" 오버플로우 에러가 발생했습니다.

### 원인 분석
1. **Container 높이 제약**: Container의 `maxHeight: 70` 제약이 있었는데, 내부 콘텐츠(아이콘 24px + 텍스트 + padding)가 이를 초과했습니다.
2. **클릭 영역과 시각적 크기 혼동**: 클릭 영역을 넓히는 것과 시각적 콘텐츠 크기를 늘리는 것을 혼동했습니다.

### 해결 과정
1. **maxHeight 제약 제거**: Container의 `maxHeight` 제약을 제거하여 높이 제한 해제
2. **콘텐츠 크기 최적화**: 아이콘 크기를 20으로 복원, padding을 `vertical: 8`로 조정
3. **클릭 영역은 보이지 않는 영역으로 확대**: `minHeight: 48` 설정으로 터치 영역만 확대하고, 실제 콘텐츠는 적절한 크기 유지

### 배운 점
- **클릭 영역과 시각적 크기는 별개**: 클릭 영역을 넓히는 것은 보이지 않는 영역(`minHeight`, `Expanded`)으로 확대하고, 실제 콘텐츠는 적절한 크기를 유지해야 함
- **오버플로우는 제약 조건 확인**: 오버플로우가 발생하면 부모 위젯의 제약 조건(`maxHeight`, `maxWidth` 등)을 확인해야 함
- **Material과 InkWell 활용**: `Material`과 `InkWell`을 사용하면 클릭 영역을 넓히면서도 리플 효과를 제공할 수 있음

---

## 🎯 2025-11-20: 햅틱 피드백 구현

### 구현 내용
하단 네비게이션 바 탭 시 카카오톡처럼 가벼운 진동 피드백을 추가했습니다.

### 사용 방법
- **Flutter 기본 기능 사용**: `HapticFeedback.selectionClick()` 사용 (추가 패키지 불필요)
- **권한 불필요**: iOS와 Android 모두 시스템 레벨 햅틱이므로 권한 설정 불필요

### 진동 강도 옵션
- `HapticFeedback.selectionClick()` - 가장 가벼운 선택 클릭 느낌 (현재 사용)
- `HapticFeedback.lightImpact()` - 가벼운 충격
- `HapticFeedback.mediumImpact()` - 중간 충격
- `HapticFeedback.heavyImpact()` - 강한 충격

### 배운 점
- **Flutter 기본 기능으로 충분**: 추가 패키지 없이 `HapticFeedback`만으로 구현 가능
- **권한 불필요**: 시스템 레벨 햅틱이므로 별도 권한 설정 불필요
- **사용자 경험 개선**: 작은 디테일이지만 사용자 경험을 크게 개선할 수 있음

---

## 📝 일반적인 레슨런

### 1. Provider 무효화 타이밍
- **데이터 변경 시 즉시 무효화**: 데이터를 변경하는 작업(생성, 수정, 삭제) 후에는 관련된 모든 provider를 즉시 무효화해야 함
- **관련 화면 모두 고려**: 한 곳에서 변경한 데이터가 표시되는 모든 화면의 provider를 무효화해야 함

### 2. Supabase 조인 결과 처리
- **배열/객체 모두 처리**: Supabase의 조인 결과는 상황에 따라 배열 또는 객체로 반환될 수 있으므로, 두 경우를 모두 처리해야 함
- **안전한 타입 체크**: `is List`와 `is Map`을 사용하여 타입을 확인한 후 처리

### 3. 명시적 파라미터 전달
- **기본값에 의존 지양**: 기본값이 있더라도 명시적으로 파라미터를 전달하여 코드의 의도를 명확히 함
- **null 값도 명시**: null을 전달할 때도 명시적으로 전달하면 코드 가독성이 향상됨

### 4. UI 일관성 유지
- **조건부 위젯도 일관된 효과**: 조건에 따라 다른 위젯을 사용하더라도, 시각적 효과는 일관되게 유지해야 함
- **단일 케이스도 고려**: 여러 항목과 단일 항목 모두 동일한 사용자 경험을 제공해야 함

### 5. Bundle ID 관리
- **App Store Connect와 정확히 일치**: 프로젝트의 Bundle ID는 App Store Connect에 등록된 앱의 Bundle ID와 정확히 일치해야 함
- **리팩토링 시 확인 필수**: 프로젝트를 리팩토링하거나 새로 설정할 때도 기존 App Store Connect의 Bundle ID를 먼저 확인해야 함
- **Xcode 서명 설정 확인**: 자동 서명이 제대로 작동하려면 `CODE_SIGN_STYLE = Automatic`이 명시적으로 설정되어 있어야 함

### 6. iOS Launch Screen과 Flutter 스플래시
- **두 단계 스플래시 화면**: iOS 앱은 Launch Screen(네이티브, 정적) → Flutter 스플래시(위젯, 동적) 순서로 표시됨
- **배경색 일치 중요**: Launch Screen과 Flutter 스플래시의 배경색을 일치시켜야 자연스러운 전환 가능
- **TestFlight에서 확인**: 시뮬레이터와 실제 디바이스의 Launch Screen 동작이 다를 수 있으므로 TestFlight에서 반드시 확인해야 함

### 7. 클릭 영역 확대
- **보이지 않는 영역으로 확대**: 클릭 영역을 넓히는 것은 `minHeight`, `Expanded` 등으로 보이지 않는 영역을 확대하고, 실제 콘텐츠는 적절한 크기를 유지해야 함
- **오버플로우 주의**: 클릭 영역을 넓힐 때 부모 위젯의 제약 조건(`maxHeight`, `maxWidth` 등)을 확인해야 함

### 8. 햅틱 피드백
- **Flutter 기본 기능 활용**: `HapticFeedback`는 추가 패키지 없이 사용 가능하며, 권한도 필요 없음
- **사용자 경험 개선**: 작은 디테일이지만 사용자 경험을 크게 개선할 수 있음

---

## 🔄 개선 사항

### 향후 개선 계획
1. **Provider 무효화 자동화**: 데이터 변경 시 관련 provider를 자동으로 무효화하는 유틸리티 함수 고려
2. **타입 안전성 강화**: Supabase 조인 결과를 처리하는 공통 유틸리티 함수 생성
3. **테스트 코드 작성**: 이러한 케이스들을 테스트로 커버하여 재발 방지

---

**문서 작성일:** 2025-11-19  
**작성자:** AI Assistant  
**검토자:** 개발팀  
**다음 검토 예정일:** 2025-12-19

