import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_provider.g.dart';

enum OnboardingStep {
  nickname,
  interests,
  complete,
}

@riverpod
class Onboarding extends _$Onboarding {
  @override
  OnboardingStep build() {
    return OnboardingStep.nickname;
  }

  void nextStep() {
    switch (state) {
      case OnboardingStep.nickname:
        state = OnboardingStep.interests;
        break;
      case OnboardingStep.interests:
        state = OnboardingStep.complete;
        break;
      case OnboardingStep.complete:
        break;
    }
  }

  void previousStep() {
    switch (state) {
      case OnboardingStep.nickname:
        break;
      case OnboardingStep.interests:
        state = OnboardingStep.nickname;
        break;
      case OnboardingStep.complete:
        state = OnboardingStep.interests;
        break;
    }
  }

  void reset() {
    state = OnboardingStep.nickname;
  }

  Future<void> setNickname(String nickname) async {
    // 닉네임은 Auth Provider에서 처리되므로 여기서는 상태만 관리
    // 필요시 추가 로직 구현
  }

  Future<void> setProfileImage(String imagePath) async {
    // 프로필 이미지는 Auth Provider에서 처리되므로 여기서는 상태만 관리
    // 필요시 추가 로직 구현
  }
}
