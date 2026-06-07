// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adherence_risk_api_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adherenceRiskApiService)
final adherenceRiskApiServiceProvider = AdherenceRiskApiServiceProvider._();

final class AdherenceRiskApiServiceProvider
    extends
        $FunctionalProvider<
          AdherenceRiskApiService,
          AdherenceRiskApiService,
          AdherenceRiskApiService
        >
    with $Provider<AdherenceRiskApiService> {
  AdherenceRiskApiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceRiskApiServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceRiskApiServiceHash();

  @$internal
  @override
  $ProviderElement<AdherenceRiskApiService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdherenceRiskApiService create(Ref ref) {
    return adherenceRiskApiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdherenceRiskApiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdherenceRiskApiService>(value),
    );
  }
}

String _$adherenceRiskApiServiceHash() =>
    r'610014c8b5bd26a1e809a1c83f2ab9db6698bcc3';
