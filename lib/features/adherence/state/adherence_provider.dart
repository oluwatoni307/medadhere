// ============================================
// FILE: adherence_provider.dart
// LAYER: state
// DOMAIN: adherence
// RESPONSIBLE FOR: Orchestrates feature computation, ML prediction, aggregation, and enrichment into AdherenceDashboardState
// RECEIVES: nothing — reads from adherenceFeatureServiceProvider and adherenceRiskApiServiceProvider
// RETURNS: Future<AdherenceDashboardState>
// CONNECTS TO: adherence_feature_service_provider.dart, adherence_risk_api_service_provider.dart, adherence_enrichment_logic.dart
// MUST NEVER: import Flutter widgets, call Firestore directly, or expose riskLevel to UI
// ============================================

// EXPOSES: adherenceProvider

// flutter — none
// packages
import 'dart:ui';

import 'package:medadhere/features/auth/state/auth_notifier_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
// internal — models
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/adherence_dashboard_state.dart';
import '../../../shared/models/adherence_risk_score.dart';
// internal — services
import '../../../shared/services/adherence/adherence_feature_service_provider.dart';
import '../../../shared/services/adherence/adherence_risk_api_service_provider.dart';
// internal — logic
import '../../../shared/logic/adherence_enrichment_logic.dart';
// internal — auth

part 'adherence_provider.g.dart';

@riverpod
Future<AdherenceDashboardState> adherence(Ref ref) async {
  // Auth fix: watch real user — return cold start immediately if unauthenticated.
  final user = await ref.watch(authProvider.future);
  if (user == null) return _coldStartState();

  final featureService = ref.watch(adherenceFeatureServiceProvider);
  final riskService = ref.watch(adherenceRiskApiServiceProvider);

  final allFeatures = await featureService.computeAllFeatures(user.uid);

  if (allFeatures.isEmpty) return _coldStartState();

  // --- predict — fall back to atRisk on individual failure ---
  final scores = <AdherenceRiskScore>[];
  for (final feature in allFeatures) {
    try {
      scores.add(await riskService.predict(feature));
    } catch (e) {
      print(
        'adherenceProvider: predict failed for ${feature.medicationId}: $e',
      );
      scores.add(
        AdherenceRiskScore(
          riskLevel: AdherenceRiskLevel.atRisk,
          confidence: 1.0,
          isColdStart: feature.isColdStart,
        ),
      );
    }
  }

  // --- aggregate ---
  final overallRisk = aggregateRiskLevel(
    scores.map((s) => s.riskLevel).toList(),
  );
  final isColdStart = allFeatures.every((f) => f.isColdStart);

  final minStreak = allFeatures.fold<int>(
    allFeatures.first.currentStreakDays,
    (m, f) => f.currentStreakDays < m ? f.currentStreakDays : m,
  );

  // Exclude features that came back as _safeDefault (rollingRate of exactly
  // 1.0 with isColdStart true) from the mean calculation so that silent
  // service failures do not inflate the displayed weekly rate.
  final validFeatures = allFeatures
      .where(
        (f) =>
            !(f.isColdStart &&
                f.rollingRate7d == 1.0 &&
                f.rollingRate3d == 1.0),
      )
      .toList();

  // Fall back to all features if filtering leaves nothing.
  final featuresForRate = validFeatures.isNotEmpty
      ? validFeatures
      : allFeatures;

  final meanRate7d =
      featuresForRate.map((f) => f.rollingRate7d).reduce((a, b) => a + b) /
      featuresForRate.length;

  // trendDirection computed per-medication then aggregated via majority vote.
  // Declining wins on a tie to surface risk rather than hide it.
  final perMedDirections = featuresForRate.map((f) {
    final diff = f.rollingRate3d - f.rollingRate7d;
    if (diff > 0.05) return TrendDirection.improving;
    if (diff < -0.05) return TrendDirection.declining;
    return TrendDirection.stable;
  }).toList();

  final trendDir = _majorityTrend(perMedDirections);

  // --- reference feature: first medication at highest risk ---
  final refIndex = scores.indexWhere((s) => s.riskLevel == overallRisk);
  final refFeature = allFeatures[refIndex >= 0 ? refIndex : 0];

  // --- per-medication ML risk scores ---
  // Ordered descending: highRisk → atRisk → onTrack.
  final medicationRiskScores = List<AdherenceMedicationRisk>.unmodifiable(
    (List.generate(
      allFeatures.length,
      (i) => AdherenceMedicationRisk(
        medicationId: allFeatures[i].medicationId,
        riskLevel: scores[i].riskLevel,
      ),
    )..sort((a, b) => b.riskLevel.index.compareTo(a.riskLevel.index))),
  );

  // --- translation + enrichment ---
  final texts = riskToText(overallRisk, isColdStart);
  final enrichment = applyEnrichment(refFeature, overallRisk);

  final eyebrowLabel = _eyebrowFor(overallRisk, isColdStart);
  final adherenceStateColor = _stateColorFor(overallRisk, isColdStart);

  return AdherenceDashboardState(
    currentStreakDays: minStreak,
    weeklyAdherenceRate: meanRate7d,
    trendDirection: trendDir,
    insightCardText: texts.text,
    insightCardAction: enrichment.actionOverride ?? texts.action,
    patternObservations: enrichment.observations,
    isColdStart: isColdStart,
    lastUpdated: DateTime.now(),
    riskLevel: overallRisk,
    eyebrowLabel: eyebrowLabel,
    adherenceStateColor: adherenceStateColor,
    medicationRiskScores: medicationRiskScores,
  );
}

// ─── Trend aggregation ────────────────────────────────────────────────────────

TrendDirection _majorityTrend(List<TrendDirection> directions) {
  if (directions.isEmpty) return TrendDirection.stable;

  int improving = 0;
  int declining = 0;
  int stable = 0;

  for (final d in directions) {
    switch (d) {
      case TrendDirection.improving:
        improving++;
      case TrendDirection.declining:
        declining++;
      case TrendDirection.stable:
        stable++;
    }
  }

  if (declining >= improving && declining >= stable) {
    return TrendDirection.declining;
  }
  if (improving > declining && improving >= stable) {
    return TrendDirection.improving;
  }
  return TrendDirection.stable;
}

// ─── Cold start ───────────────────────────────────────────────────────────────

AdherenceDashboardState _coldStartState() {
  return AdherenceDashboardState(
    currentStreakDays: 0,
    weeklyAdherenceRate: 0.0,
    trendDirection: TrendDirection.stable,
    insightCardText: 'We\'re learning your pattern. Keep logging your doses.',
    insightCardAction:
        'Log each dose as you take it to get personalised insights.',
    patternObservations: const [],
    isColdStart: true,
    lastUpdated: DateTime.now(),
    riskLevel: AdherenceRiskLevel.atRisk,
    eyebrowLabel: 'A beginning',
    adherenceStateColor: AppColors.colorStateMorning,
    medicationRiskScores: const [],
  );
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _eyebrowFor(AdherenceRiskLevel risk, bool isColdStart) {
  if (isColdStart) return 'A beginning';
  return switch (risk) {
    AdherenceRiskLevel.onTrack => 'Settling in',
    AdherenceRiskLevel.atRisk => 'A small shift',
    AdherenceRiskLevel.highRisk => 'A little care',
  };
}

Color _stateColorFor(AdherenceRiskLevel risk, bool isColdStart) {
  if (isColdStart) return AppColors.colorStateMorning;
  return switch (risk) {
    AdherenceRiskLevel.onTrack => AppColors.colorStateConsistent,
    AdherenceRiskLevel.atRisk => AppColors.colorStateSlipping,
    AdherenceRiskLevel.highRisk => AppColors.colorStateRisk,
  };
}
