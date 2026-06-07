// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adherence_feature_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adherenceFeatureService)
final adherenceFeatureServiceProvider = AdherenceFeatureServiceProvider._();

final class AdherenceFeatureServiceProvider
    extends
        $FunctionalProvider<
          AdherenceFeatureService,
          AdherenceFeatureService,
          AdherenceFeatureService
        >
    with $Provider<AdherenceFeatureService> {
  AdherenceFeatureServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceFeatureServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceFeatureServiceHash();

  @$internal
  @override
  $ProviderElement<AdherenceFeatureService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdherenceFeatureService create(Ref ref) {
    return adherenceFeatureService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdherenceFeatureService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdherenceFeatureService>(value),
    );
  }
}

String _$adherenceFeatureServiceHash() =>
    r'83bce6138053df9051a6a33329d0d80be5a18613';
