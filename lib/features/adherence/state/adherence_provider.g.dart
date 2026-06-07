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

String _$adherenceHash() => r'ce4ee1296acd496cd1a314478fe19e52d23f274f';
