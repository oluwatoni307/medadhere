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

String _$homeNotifierHash() => r'72e5b570df7af955a47967139fdf7d0183b275bb';

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
