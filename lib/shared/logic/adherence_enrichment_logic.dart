// ============================================
// FILE: adherence_enrichment_logic.dart
// LAYER: logic
// DOMAIN: adherence
// RESPONSIBLE FOR: Translates risk scores and feature data into user-facing text and pattern observations
// RECEIVES: AdherenceRiskLevel, AdherenceFeature, rate deltas
// RETURNS: RiskText, EnrichmentResult, TrendDirection, AdherenceRiskLevel
// CONNECTS TO: adherence_risk_score.dart, adherence_feature.dart, adherence_dashboard_state.dart
// MUST NEVER: import Flutter or call any repository or service
// ============================================

// flutter — none
// packages — none
// internal — models
import '../models/adherence_dashboard_state.dart';
import '../models/adherence_feature.dart';
import '../models/adherence_risk_score.dart';

// --- data classes ---

class RiskText {
  final String text;
  final String action;
  const RiskText({required this.text, required this.action});
}

class EnrichmentResult {
  final List<String> observations;
  final String? actionOverride;
  const EnrichmentResult({
    required this.observations,
    required this.actionOverride,
  });
}

// --- weekday ---

String weekdayName(int weekday) {
  const names = {
    1: 'Monday',
    2: 'Tuesday',
    3: 'Wednesday',
    4: 'Thursday',
    5: 'Friday',
    6: 'Saturday',
    7: 'Sunday',
  };
  return names[weekday] ?? 'Unknown';
}

// --- risk translation ---

RiskText riskToText(AdherenceRiskLevel level, bool isColdStart) {
  if (isColdStart) {
    return const RiskText(
      text: 'We\'re learning your pattern. Keep logging your doses.',
      action: 'Log each dose as you take it to get personalised insights.',
    );
  }
  switch (level) {
    case AdherenceRiskLevel.onTrack:
      return const RiskText(
        text: 'You\'re doing well. Keep it up.',
        action: 'Log your next dose when it\'s due.',
      );
    case AdherenceRiskLevel.atRisk:
      return const RiskText(
        text: 'Your pattern shows some missed doses recently.',
        action: 'Try setting a specific time for your medication today.',
      );
    case AdherenceRiskLevel.highRisk:
      return const RiskText(
        text: 'You\'ve missed several doses this week.',
        action: 'Taking your medication now can help get you back on track.',
      );
  }
}

// --- trend ---

TrendDirection trendDirection(double meanRate3d, double meanRate7d) {
  final delta = meanRate3d - meanRate7d;
  if (delta > 0.05) return TrendDirection.improving;
  if (delta < -0.05) return TrendDirection.declining;
  return TrendDirection.stable;
}

// --- aggregation ---

AdherenceRiskLevel aggregateRiskLevel(List<AdherenceRiskLevel> levels) {
  if (levels.contains(AdherenceRiskLevel.highRisk)) {
    return AdherenceRiskLevel.highRisk;
  }
  if (levels.contains(AdherenceRiskLevel.atRisk)) {
    return AdherenceRiskLevel.atRisk;
  }
  return AdherenceRiskLevel.onTrack;
}

// --- enrichment ---

EnrichmentResult applyEnrichment(
  AdherenceFeature feature,
  AdherenceRiskLevel riskLevel,
) {
  final observations = <String>[];
  String? actionOverride;

  // Rule 1 + Rule 4: worst day of week
  if (feature.dayOfWeekPattern.isNotEmpty) {
    final worst = feature.dayOfWeekPattern.entries.reduce(
      (a, b) => a.value < b.value ? a : b,
    );
    if (worst.value < 0.60) {
      final name = weekdayName(worst.key);
      observations.add('You tend to miss doses on $name.');
      if (riskLevel == AdherenceRiskLevel.atRisk ||
          riskLevel == AdherenceRiskLevel.highRisk) {
        actionOverride =
            'Pay extra attention on $name — that\'s when your pattern tends to slip.';
      }
    }
  }

  // Rule 2: time deviation — only fires if Rule 4 did not
  if (actionOverride == null && feature.avgDoseTimeDeviationMinutes > 30) {
    actionOverride =
        'Try taking it at the same time each day — linking it to a habit like a meal can help.';
  }

  // Rule 3: consistent timing reinforcement
  if (feature.avgDoseTimeDeviationMinutes <= 15 &&
      riskLevel == AdherenceRiskLevel.onTrack) {
    observations.add(
      'Your timing is consistent — that\'s one of the best habits you can build.',
    );
  }

  return EnrichmentResult(
    observations: observations,
    actionOverride: actionOverride,
  );
}
