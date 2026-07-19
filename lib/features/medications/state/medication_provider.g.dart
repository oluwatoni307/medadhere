// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MedicationNotifier)
final medicationProvider = MedicationNotifierProvider._();

final class MedicationNotifierProvider
    extends $NotifierProvider<MedicationNotifier, MedicationState> {
  MedicationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicationNotifierHash();

  @$internal
  @override
  MedicationNotifier create() => MedicationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicationState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicationState>(value),
    );
  }
}

String _$medicationNotifierHash() =>
    r'53b10355ba271eeb9d8c4dd48e7eed7affa3a294';

abstract class _$MedicationNotifier extends $Notifier<MedicationState> {
  MedicationState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MedicationState, MedicationState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MedicationState, MedicationState>,
              MedicationState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
