// ============================================
// FILE: medication_detail_provider.dart
// LAYER: state
// DOMAIN: medications
// RESPONSIBLE FOR: Notifier managing medication detail, dose logs, and ML risk score
// RECEIVES: medicationId via build argument
// RETURNS: MedicationDetailState
// CONNECTS TO: medication_provider.dart, dose_log_service_provider.dart,
//              adherence_feature_service_provider.dart, adherence_risk_api_service_provider.dart, auth_notifier_provider.dart
// MUST NEVER: call repositories directly or throw on ML failure
// ============================================

// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — models
import '../../../shared/models/medication.dart';
import '../../../shared/models/dose_log.dart';
import '../../../shared/models/adherence_risk_score.dart';

// internal — providers
import '../../../shared/services/dose_log_service_provider.dart';
import '../../../shared/services/adherence/adherence_feature_service_provider.dart';
import '../../../shared/services/adherence/adherence_risk_api_service_provider.dart';
import '../../auth/state/auth_notifier_provider.dart';
import '../state/medication_provider.dart';

part 'medication_detail_provider.g.dart';

// --- sentinel ---

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

// --- state ---

class MedicationDetailState {
  const MedicationDetailState({
    this.medication,
    this.logs = const [],
    this.riskScore,
    this.isLoading = false,
    this.error,
  });

  final Medication? medication;
  final List<DoseLog> logs;
  final AdherenceRiskScore? riskScore; // null = ML unavailable, silent
  final bool isLoading;
  final String? error;

  bool get hasMedication => medication != null;
  bool get hasInsight => riskScore != null;

  MedicationDetailState copyWith({
    Medication? medication,
    List<DoseLog>? logs,
    AdherenceRiskScore? riskScore,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return MedicationDetailState(
      medication: medication ?? this.medication,
      logs: logs ?? this.logs,
      riskScore: riskScore ?? this.riskScore,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

// --- notifier ---

@riverpod
class MedicationDetailNotifier extends _$MedicationDetailNotifier {
  @override
  MedicationDetailState build(String medicationId) =>
      const MedicationDetailState();

  // --- private helper for UID extraction ---

  String? _getUid() {
    return ref.read(authProvider).value?.uid;
  }

  // --- public methods ---

  Future<void> load() async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      // — step 1: resolve medication from existing notifier —
      var med = ref
          .read(
            medicationProvider,
          ) // Note: ensured matching generated name based on your previous file
          .medications
          .where((m) => m.id == medicationId)
          .firstOrNull;

      if (med == null) {
        await ref.read(medicationProvider.notifier).loadMedications();
        med = ref
            .read(medicationProvider)
            .medications
            .where((m) => m.id == medicationId)
            .firstOrNull;
      }

      if (med == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Medication not found.',
        );
        return;
      }

      // — step 2: fan out logs + ML in parallel, passing the real UID down —
      final results = await Future.wait([
        _fetchLogs(uid, medicationId),
        _fetchRiskScore(uid, medicationId),
      ]);

      state = state.copyWith(
        medication: med,
        logs: results[0] as List<DoseLog>,
        riskScore: results[1] as AdherenceRiskScore?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteMedication() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(medicationProvider.notifier)
          .deleteMedication(medicationId);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // --- private helpers ---

  Future<List<DoseLog>> _fetchLogs(String uid, String medicationId) async {
    try {
      return await ref
          .read(doseLogServiceProvider)
          .getDoseLogsForMedication(uid, medicationId); // <-- UID injected
    } catch (_) {
      return [];
    }
  }

  Future<AdherenceRiskScore?> _fetchRiskScore(
    String uid,
    String medicationId,
  ) async {
    try {
      final feature = await ref
          .read(adherenceFeatureServiceProvider)
          .computeFeatures(uid, medicationId); // <-- Replaced AppConstants

      return await ref.read(adherenceRiskApiServiceProvider).predict(feature);
    } catch (_) {
      // ML failure is always silent — null tells the screen to skip the pattern card
      return null;
    }
  }
}
