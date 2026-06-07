// ============================================
// FILE: adherence_dashboard_state.dart
// LAYER: model
// DOMAIN: adherence
// RESPONSIBLE FOR: Data container for the fully translated adherence dashboard state
// RECEIVES: nothing — pure data container
// RETURNS: nothing — pure data container
// CONNECTS TO: adherence_provider.dart, adherence_risk_score.dart
// MUST NEVER: contain logic — fields only. riskLevel must never be read from a screen file.
// ============================================

// flutter — none
// packages — none
// internal — models
import 'dart:ui';

import 'adherence_risk_score.dart';

enum TrendDirection { improving, stable, declining }

// ─── per-medication ML risk entry ────────────────────────────────────────────

/// Flat pairing of a medication ID and its ML-predicted risk level.
/// Produced by adherenceProvider and passed to AdherenceStripWidget
/// for the ML rating section. Name and frequency are resolved at the
/// widget level from AdherenceStripData — this model stays domain-pure.
class AdherenceMedicationRisk {
  final String medicationId;
  final AdherenceRiskLevel riskLevel;

  const AdherenceMedicationRisk({
    required this.medicationId,
    required this.riskLevel,
  });
}

// ─── dashboard state ─────────────────────────────────────────────────────────

class AdherenceDashboardState {
  /// Weakest-link streak across all medications.
  final int currentStreakDays;

  /// Mean 7-day rolling rate across all medications. UI formats as percentage.
  final double weeklyAdherenceRate;

  /// Derived from 3d vs 7d rate delta across all medications.
  final TrendDirection trendDirection;

  /// Plain-language observation. Never contains a score or enum label.
  final String insightCardText;

  /// Plain-language suggested action. May be overridden by enrichment rules.
  final String insightCardAction;

  /// Personalised observations. Empty list when none apply.
  final List<String> patternObservations;

  /// True when insufficient history exists. UI shows onboarding card.
  final bool isColdStart;

  /// Timestamp of last successful computation.
  final DateTime lastUpdated;

  /// Internal use only — for future notification service.
  /// Must not be read from any screen or widget file.
  final AdherenceRiskLevel riskLevel;

  final String eyebrowLabel;
  final Color adherenceStateColor;

  /// Per-medication ML risk levels. Ordered by descending risk (highest first).
  /// Empty when isColdStart is true. Passed to AdherenceStripWidget for the
  /// ML rating section — never read directly by screen-level layout logic.
  final List<AdherenceMedicationRisk> medicationRiskScores;

  const AdherenceDashboardState({
    required this.currentStreakDays,
    required this.weeklyAdherenceRate,
    required this.trendDirection,
    required this.insightCardText,
    required this.insightCardAction,
    required this.patternObservations,
    required this.isColdStart,
    required this.lastUpdated,
    required this.riskLevel,
    required this.eyebrowLabel,
    required this.adherenceStateColor,
    required this.medicationRiskScores,
  });
}
