// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adherence_visualization_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adherenceVisualizationService)
final adherenceVisualizationServiceProvider =
    AdherenceVisualizationServiceProvider._();

final class AdherenceVisualizationServiceProvider
    extends
        $FunctionalProvider<
          AdherenceVisualizationService,
          AdherenceVisualizationService,
          AdherenceVisualizationService
        >
    with $Provider<AdherenceVisualizationService> {
  AdherenceVisualizationServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceVisualizationServiceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceVisualizationServiceHash();

  @$internal
  @override
  $ProviderElement<AdherenceVisualizationService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdherenceVisualizationService create(Ref ref) {
    return adherenceVisualizationService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdherenceVisualizationService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdherenceVisualizationService>(
        value,
      ),
    );
  }
}

String _$adherenceVisualizationServiceHash() =>
    r'13457f9dc47c4ca003fc6e96ce2100aca30f05f1';
