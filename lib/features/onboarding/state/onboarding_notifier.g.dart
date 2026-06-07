// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingNotifier)
final onboardingProvider = OnboardingNotifierProvider._();

final class OnboardingNotifierProvider
    extends $AsyncNotifierProvider<OnboardingNotifier, OnboardingState> {
  OnboardingNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingNotifierHash();

  @$internal
  @override
  OnboardingNotifier create() => OnboardingNotifier();
}

String _$onboardingNotifierHash() =>
    r'41bdef8e7d315e6bf362df822500c0837aab9e5a';

abstract class _$OnboardingNotifier extends $AsyncNotifier<OnboardingState> {
  FutureOr<OnboardingState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<OnboardingState>, OnboardingState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingState>, OnboardingState>,
              AsyncValue<OnboardingState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
