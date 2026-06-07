// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(DoseLogNotifier)
final doseLogProvider = DoseLogNotifierProvider._();

final class DoseLogNotifierProvider
    extends $NotifierProvider<DoseLogNotifier, DoseLogState> {
  DoseLogNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doseLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doseLogNotifierHash();

  @$internal
  @override
  DoseLogNotifier create() => DoseLogNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoseLogState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoseLogState>(value),
    );
  }
}

String _$doseLogNotifierHash() => r'826429cf629a093d57c187cce0c95c11a9b654db';

abstract class _$DoseLogNotifier extends $Notifier<DoseLogState> {
  DoseLogState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DoseLogState, DoseLogState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DoseLogState, DoseLogState>,
              DoseLogState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
