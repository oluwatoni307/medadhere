import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/services/onboarding_preference_service.dart';

part 'onboarding_notifier.g.dart';

// PATH: lib/features/onboarding/state/onboarding_notifier.dart
// DOMAIN: features
// LAYER: state
// RESPONSIBLE FOR: Hydrates onboarding completion flags from SharedPreferences and exposes methods to mark intro and name collection complete

/// State representation container for the onboarding workflow flags.
class OnboardingState {
  final bool isIntroSeen;
  final bool isNameCollected;

  const OnboardingState({
    required this.isIntroSeen,
    required this.isNameCollected,
  });

  OnboardingState copyWith({bool? isIntroSeen, bool? isNameCollected}) {
    return OnboardingState(
      isIntroSeen: isIntroSeen ?? this.isIntroSeen,
      isNameCollected: isNameCollected ?? this.isNameCollected,
    );
  }
}

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  final OnboardingPreferenceService _preferenceService =
      OnboardingPreferenceService();

  @override
  Future<OnboardingState> build() async {
    final results = await Future.wait([
      _preferenceService.isIntroSeen(),
      _preferenceService.isNameCollected(),
    ]);

    return OnboardingState(
      isIntroSeen: results[0],
      isNameCollected: results[1],
    );
  }

  Future<void> markIntroSeen() async {
    await _preferenceService.markIntroSeen();

    state = state.whenData((current) => current.copyWith(isIntroSeen: true));
  }

  Future<void> markNameCollected() async {
    await _preferenceService.markNameCollected();

    state = state.whenData(
      (current) => current.copyWith(isNameCollected: true),
    );
  }
}
