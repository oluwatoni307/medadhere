// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medication_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MedicationDetailNotifier)
final medicationDetailProvider = MedicationDetailNotifierFamily._();

final class MedicationDetailNotifierProvider
    extends $NotifierProvider<MedicationDetailNotifier, MedicationDetailState> {
  MedicationDetailNotifierProvider._({
    required MedicationDetailNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'medicationDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$medicationDetailNotifierHash();

  @override
  String toString() {
    return r'medicationDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MedicationDetailNotifier create() => MedicationDetailNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MedicationDetailState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MedicationDetailState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MedicationDetailNotifierProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$medicationDetailNotifierHash() =>
    r'9075019deae3d1161ca689e3c8d609e8454c0074';

final class MedicationDetailNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          MedicationDetailNotifier,
          MedicationDetailState,
          MedicationDetailState,
          MedicationDetailState,
          String
        > {
  MedicationDetailNotifierFamily._()
    : super(
        retry: null,
        name: r'medicationDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MedicationDetailNotifierProvider call(String medicationId) =>
      MedicationDetailNotifierProvider._(argument: medicationId, from: this);

  @override
  String toString() => r'medicationDetailProvider';
}

abstract class _$MedicationDetailNotifier
    extends $Notifier<MedicationDetailState> {
  late final _$args = ref.$arg as String;
  String get medicationId => _$args;

  MedicationDetailState build(String medicationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<MedicationDetailState, MedicationDetailState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MedicationDetailState, MedicationDetailState>,
              MedicationDetailState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
