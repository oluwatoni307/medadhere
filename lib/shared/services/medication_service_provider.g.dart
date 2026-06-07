// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(medicationService)
final medicationServiceProvider = MedicationServiceProvider._();

final class MedicationServiceProvider
    extends
        $FunctionalProvider<
          MedicationService,
          MedicationService,
          MedicationService
        >
    with $Provider<MedicationService> {
  MedicationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'medicationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$medicationServiceHash();

  @$internal
  @override
  $ProviderElement<MedicationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MedicationService create(Ref ref) {
    return medicationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicationService>(value),
    );
  }
}

String _$medicationServiceHash() => r'a4509d8cde7e9157e3200bebb59f20cb8888fbb3';
