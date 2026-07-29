// ============================================
// FILE: adherence_feature_service.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Fetches dose logs and medication from repositories and returns a computed AdherenceFeature
// RECEIVES: userId, medicationId
// RETURNS: Future<AdherenceFeature>, Future<List<AdherenceFeature>>
// CONNECTS TO: dose_log_repository.dart, medication_repository.dart, adherence_feature_logic.dart
// MUST NEVER: call Firestore directly or throw on missing data
//
// AMENDMENT — error vs. empty distinction:
//   Both public methods previously caught every exception and returned a
//   default value ([] for computeAllFeatures, _safeDefault for
//   computeFeatures) indistinguishable from a genuine "no data" result.
//   That meant a real repository failure (network, permissions, parsing)
//   silently rendered as Cold Start everywhere downstream — including on
//   the Adherence screen, where a user with real dose history and real
//   misses showed as a brand-new user with an empty risk section.
//
//   Fixed: computeAllFeatures no longer catches getAll()'s exceptions —
//   medication_repository.dart already throws a proper AppException on
//   real failure, matching the pattern adherence_risk_api_service.dart
//   already respects (`on AppException { rethrow; }`). Letting it
//   propagate here means adherenceProvider (which has no try/catch of
//   its own around this call) naturally surfaces it as AsyncError,
//   exactly like the strip/month/trend providers already behave.
//
//   computeFeatures still catches exceptions, but _safeDefault is now
//   reserved for the one case that's genuinely safe to default silently:
//   the medication itself doesn't exist (med == null). Any other
//   exception — a failed dose-log fetch, a logic error — now rethrows
//   as AppException instead of masquerading as a fully-adherent
//   cold-start feature.
//
//   "MUST NEVER throw on missing data" still holds — a missing
//   medication or a genuinely empty medication list are not errors and
//   never throw. Only genuine failures now throw, where they previously
//   didn't.
// ============================================

// EXPOSES:
//   computeFeatures(String userId, String medicationId) → Future<AdherenceFeature>
//   computeAllFeatures(String userId) → Future<List<AdherenceFeature>>

// flutter — none
// packages — none
// internal — models
// Note: Adjust paths as needed for your project structure
import '../../models/adherence_feature.dart';
import '../../models/medication.dart';
// internal — repositories
import '../../repositories/dose_log_repository.dart';
import '../../repositories/medication_repository.dart';
// internal — logic
import '../../logic/adherence_feature_logic.dart';
// internal — errors
import '../../../core/errors/app_exception.dart';

class AdherenceFeatureService {
  final DoseLogRepository _doseLogRepository;
  final MedicationRepository _medicationRepository;

  const AdherenceFeatureService({
    required DoseLogRepository doseLogRepository,
    required MedicationRepository medicationRepository,
  }) : _doseLogRepository = doseLogRepository,
       _medicationRepository = medicationRepository;

  // --- public methods ---

  Future<AdherenceFeature> computeFeatures(
    String userId,
    String medicationId,
  ) async {
    final Medication? med;
    try {
      med = await _medicationRepository.getById(userId, medicationId);
    } catch (e) {
      // A failed fetch is not "missing data" — surface it rather than
      // silently reporting a fake fully-adherent feature.
      throw AppException('Failed to fetch medication $medicationId: $e');
    }

    // Genuinely missing medication — this is the one case _safeDefault
    // exists for. Not an error; nothing to compute against.
    if (med == null) return _safeDefault(userId, medicationId);

    try {
      final logs = await _doseLogRepository.getByMedicationId(
        userId,
        medicationId,
      );

      final now = DateTime.now();
      final dowPattern = dayOfWeekPattern(logs, med, now);
      final daySince = daysSinceTreatmentStart(logs, now);

      return AdherenceFeature(
        userId: userId,
        medicationId: medicationId,
        rollingRate7d: rollingRate(logs, med, 7, now),
        rollingRate3d: rollingRate(logs, med, 3, now),
        currentStreakDays: currentStreak(logs, med, now),
        lastStreakDays: lastStreak(logs, med, now),
        previousDayAdherence: previousDayAdherence(logs, med, now),
        avgDoseTimeDeviationMinutes: avgDoseTimeDeviation(logs, now),
        dayOfWeekPattern: dowPattern,
        worstDayOfWeekRate: worstDayOfWeekRate(dowPattern),
        daysSinceTreatmentStart: daySince,
        postMissRecoveryRate: postMissRecoveryRate(logs),
        isColdStart: daySince < 7 || logs.length < 10,
      );
    } catch (e) {
      // Real failure computing features for a medication that DOES
      // exist — not the same as "no data yet." Surface it instead of
      // returning a fake 100%-adherent cold-start feature.
      throw AppException('Failed to compute features for $medicationId: $e');
    }
  }

  Future<List<AdherenceFeature>> computeAllFeatures(String userId) async {
    // No try/catch here — let a real failure from getAll() (an
    // AppException per medication_repository.dart) propagate rather
    // than being reported as "this user has no medications." Only an
    // actually-empty result from a successful getAll() call means
    // genuine Cold Start.
    final medications = await _medicationRepository.getAll(userId);

    if (medications.isEmpty) {
      return [];
    }

    return Future.wait(
      medications.map((med) => computeFeatures(userId, med.id)).toList(),
    );
  }

  // --- private helpers ---

  AdherenceFeature _safeDefault(String userId, String medicationId) {
    return AdherenceFeature(
      userId: userId,
      medicationId: medicationId,
      rollingRate7d: 1.0,
      rollingRate3d: 1.0,
      currentStreakDays: 0,
      lastStreakDays: 0,
      previousDayAdherence: 1.0,
      avgDoseTimeDeviationMinutes: 0.0,
      dayOfWeekPattern: const {},
      worstDayOfWeekRate: 1.0,
      daysSinceTreatmentStart: 0,
      postMissRecoveryRate: 0.0,
      isColdStart: true,
    );
  }
}
