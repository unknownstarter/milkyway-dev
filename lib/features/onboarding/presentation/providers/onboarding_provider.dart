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
}
