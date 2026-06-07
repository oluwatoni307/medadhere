// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(StreakNotifier)
final streakProvider = StreakNotifierProvider._();

final class StreakNotifierProvider
    extends $NotifierProvider<StreakNotifier, AsyncValue<StreakSummary>> {
  StreakNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'streakProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$streakNotifierHash();

  @$internal
  @override
  StreakNotifier create() => StreakNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<StreakSummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<StreakSummary>>(value),
    );
  }
}

String _$streakNotifierHash() => r'c0f35fdcbf3d5bcde6fd6256ad4c2670bbc21d7b';

abstract class _$StreakNotifier extends $Notifier<AsyncValue<StreakSummary>> {
  AsyncValue<StreakSummary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<StreakSummary>, AsyncValue<StreakSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<StreakSummary>, AsyncValue<StreakSummary>>,
              AsyncValue<StreakSummary>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
