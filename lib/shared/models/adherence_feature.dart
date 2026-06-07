// ============================================
// FILE: adherence_feature.dart
// LAYER: model
// DOMAIN: adherence
// RESPONSIBLE FOR: Data container for the 8 computed adherence features for one user-medication pair
// RECEIVES: nothing — pure data container
// RETURNS: nothing — pure data container
// CONNECTS TO: adherence_feature_service.dart
// MUST NEVER: contain logic — fields only
// ============================================

// flutter — none
// packages — none
// internal — none

class AdherenceFeature {
  final String userId;
  final String medicationId;
  final double rollingRate7d;
  final double rollingRate3d;
  final int currentStreakDays;
  final int lastStreakDays; // ← new

  final double previousDayAdherence;
  final double avgDoseTimeDeviationMinutes;
  final Map<int, double> dayOfWeekPattern;
  final double worstDayOfWeekRate;
  final int daysSinceTreatmentStart;
  final double postMissRecoveryRate;
  final bool isColdStart;

  const AdherenceFeature({
    required this.userId,
    required this.medicationId,
    required this.rollingRate7d,
    required this.rollingRate3d,
    required this.currentStreakDays,
    required this.previousDayAdherence,
    required this.avgDoseTimeDeviationMinutes,
    required this.dayOfWeekPattern,
    required this.worstDayOfWeekRate,
    required this.daysSinceTreatmentStart,
    required this.postMissRecoveryRate,
    required this.isColdStart,
    required this.lastStreakDays,
  });
}
