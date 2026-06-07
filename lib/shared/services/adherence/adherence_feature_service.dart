// ============================================
// FILE: adherence_feature_service.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Fetches dose logs and medication from repositories and returns a computed AdherenceFeature
// RECEIVES: userId, medicationId
// RETURNS: Future<AdherenceFeature>, Future<List<AdherenceFeature>>
// CONNECTS TO: dose_log_repository.dart, medication_repository.dart, adherence_feature_logic.dart
// MUST NEVER: call Firestore directly or throw on missing data
// ============================================

// EXPOSES:
//   computeFeatures(String userId, String medicationId) → Future<AdherenceFeature>
//   computeAllFeatures(String userId) → Future<List<AdherenceFeature>>

// flutter — none
// packages — none
// internal — models
// Note: Adjust paths as needed for your project structure
import '../../models/adherence_feature.dart';
// internal — repositories
import '../../repositories/dose_log_repository.dart';
import '../../repositories/medication_repository.dart';
// internal — logic
import '../../logic/adherence_feature_logic.dart';

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
    try {
      // Passed userId downstream to the repository
      final logs = await _doseLogRepository.getByMedicationId(
        userId,
        medicationId,
      );
      final med = await _medicationRepository.getById(userId, medicationId);

      if (med == null) return _safeDefault(userId, medicationId);

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
    } catch (_) {
      return _safeDefault(userId, medicationId);
    }
  }

  Future<List<AdherenceFeature>> computeAllFeatures(String userId) async {
    try {
      // Passed userId downstream to the repository
      final medications = await _medicationRepository.getAll(userId);
      return Future.wait(
        medications.map((med) => computeFeatures(userId, med.id)).toList(),
      );
    } catch (_) {
      return [];
    }
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
