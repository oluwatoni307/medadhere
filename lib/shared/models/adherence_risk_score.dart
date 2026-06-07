// ============================================
// FILE: adherence_risk_score.dart
// LAYER: model
// DOMAIN: adherence
// RESPONSIBLE FOR: Data container for the ML service prediction result
// RECEIVES: nothing — pure data container
// RETURNS: nothing — pure data container
// CONNECTS TO: adherence_risk_api_service.dart
// MUST NEVER: contain logic — fields only
// ============================================

// EXPOSES: AdherenceRiskLevel, AdherenceRiskScore

// flutter — none
// packages — none
// internal — none

enum AdherenceRiskLevel { onTrack, atRisk, highRisk }

class AdherenceRiskScore {
  final AdherenceRiskLevel riskLevel;
  final double confidence;
  final bool isColdStart;

  const AdherenceRiskScore({
    required this.riskLevel,
    required this.confidence,
    required this.isColdStart,
  });
}
