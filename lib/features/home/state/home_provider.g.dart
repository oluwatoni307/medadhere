// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HomeNotifier)
final homeProvider = HomeNotifierProvider._();

final class HomeNotifierProvider
    extends
        $NotifierProvider<HomeNotifier, AsyncValue<List<DueMedicationEntry>>> {
  HomeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'homeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$homeNotifierHash();

  @$internal
  @override
  HomeNotifier create() => HomeNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<DueMedicationEntry>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<AsyncValue<List<DueMedicationEntry>>>(value),
    );
  }
}

String _$homeNotifierHash() => r'f1d60936c08c720e878f89ef522e79f226f083c3';

abstract class _$HomeNotifier
    extends $Notifier<AsyncValue<List<DueMedicationEntry>>> {
  AsyncValue<List<DueMedicationEntry>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<DueMedicationEntry>>,
              AsyncValue<List<DueMedicationEntry>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<DueMedicationEntry>>,
                AsyncValue<List<DueMedicationEntry>>
              >,
              AsyncValue<List<DueMedicationEntry>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(todaySummary)
final todaySummaryProvider = TodaySummaryProvider._();

final class TodaySummaryProvider
    extends
        $FunctionalProvider<
          AsyncValue<TodaySummary>,
          TodaySummary,
          FutureOr<TodaySummary>
        >
    with $FutureModifier<TodaySummary>, $FutureProvider<TodaySummary> {
  TodaySummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todaySummaryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todaySummaryHash();

  @$internal
  @override
  $FutureProviderElement<TodaySummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TodaySummary> create(Ref ref) {
    return todaySummary(ref);
  }
}

String _$todaySummaryHash() => r'bdc0a25a73ef3020ecfd34d010ad6c9fe6372b3b';
