// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dose_log_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(doseLogService)
final doseLogServiceProvider = DoseLogServiceProvider._();

final class DoseLogServiceProvider
    extends $FunctionalProvider<DoseLogService, DoseLogService, DoseLogService>
    with $Provider<DoseLogService> {
  DoseLogServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'doseLogServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$doseLogServiceHash();

  @$internal
  @override
  $ProviderElement<DoseLogService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DoseLogService create(Ref ref) {
    return doseLogService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DoseLogService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DoseLogService>(value),
    );
  }
}

String _$doseLogServiceHash() => r'1609c27c173f220999ff6861bcdbfd00e1cd601b';
