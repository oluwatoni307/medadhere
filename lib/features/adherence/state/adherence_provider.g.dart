// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adherence_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adherence)
final adherenceProvider = AdherenceProvider._();

final class AdherenceProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdherenceDashboardState>,
          AdherenceDashboardState,
          FutureOr<AdherenceDashboardState>
        >
    with
        $FutureModifier<AdherenceDashboardState>,
        $FutureProvider<AdherenceDashboardState> {
  AdherenceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceHash();

  @$internal
  @override
  $FutureProviderElement<AdherenceDashboardState> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdherenceDashboardState> create(Ref ref) {
    return adherence(ref);
  }
}

String _$adherenceHash() => r'e54a5027807371089f14ea04248f10412b4f8a52';
