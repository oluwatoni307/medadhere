// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adherence_visualization_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 7-day strip — per medication statuses sorted by priority.
/// Invalidate when a new dose is logged.

@ProviderFor(adherenceStrip)
final adherenceStripProvider = AdherenceStripProvider._();

/// 7-day strip — per medication statuses sorted by priority.
/// Invalidate when a new dose is logged.

final class AdherenceStripProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdherenceStripData>,
          AdherenceStripData,
          FutureOr<AdherenceStripData>
        >
    with
        $FutureModifier<AdherenceStripData>,
        $FutureProvider<AdherenceStripData> {
  /// 7-day strip — per medication statuses sorted by priority.
  /// Invalidate when a new dose is logged.
  AdherenceStripProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceStripProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceStripHash();

  @$internal
  @override
  $FutureProviderElement<AdherenceStripData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdherenceStripData> create(Ref ref) {
    return adherenceStrip(ref);
  }
}

String _$adherenceStripHash() => r'1d97b4ddc1b6f3f8a711337756d004e14626e7bb';

/// 30-day line chart — aggregate daily completion rates.
/// Slower-changing — does not need to invalidate on every dose log.

@ProviderFor(adherenceMonth)
final adherenceMonthProvider = AdherenceMonthProvider._();

/// 30-day line chart — aggregate daily completion rates.
/// Slower-changing — does not need to invalidate on every dose log.

final class AdherenceMonthProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdherenceMonthData>,
          AdherenceMonthData,
          FutureOr<AdherenceMonthData>
        >
    with
        $FutureModifier<AdherenceMonthData>,
        $FutureProvider<AdherenceMonthData> {
  /// 30-day line chart — aggregate daily completion rates.
  /// Slower-changing — does not need to invalidate on every dose log.
  AdherenceMonthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceMonthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceMonthHash();

  @$internal
  @override
  $FutureProviderElement<AdherenceMonthData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdherenceMonthData> create(Ref ref) {
    return adherenceMonth(ref);
  }
}

String _$adherenceMonthHash() => r'd9ff194748152f686b4d0b35dac097624d843b4e';

/// 90-day bar chart — aggregate weekly completion rates and trend direction.
/// Slowest-changing — invalidate daily or on explicit refresh only.

@ProviderFor(adherenceTrend)
final adherenceTrendProvider = AdherenceTrendProvider._();

/// 90-day bar chart — aggregate weekly completion rates and trend direction.
/// Slowest-changing — invalidate daily or on explicit refresh only.

final class AdherenceTrendProvider
    extends
        $FunctionalProvider<
          AsyncValue<AdherenceTrendData>,
          AdherenceTrendData,
          FutureOr<AdherenceTrendData>
        >
    with
        $FutureModifier<AdherenceTrendData>,
        $FutureProvider<AdherenceTrendData> {
  /// 90-day bar chart — aggregate weekly completion rates and trend direction.
  /// Slowest-changing — invalidate daily or on explicit refresh only.
  AdherenceTrendProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adherenceTrendProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adherenceTrendHash();

  @$internal
  @override
  $FutureProviderElement<AdherenceTrendData> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AdherenceTrendData> create(Ref ref) {
    return adherenceTrend(ref);
  }
}

String _$adherenceTrendHash() => r'a6f2eaedb918200126be07e28821261e5bc7f414';
