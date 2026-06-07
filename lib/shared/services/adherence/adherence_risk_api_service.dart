// ============================================
// FILE: adherence_risk_api_service.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Sends adherence features to the ML service and returns a parsed risk score.
//                  Falls back to rule-based scoring when the ML service is unreachable.
// RECEIVES: AdherenceFeature
// RETURNS: Future<AdherenceRiskScore>
// CONNECTS TO: adherence_risk_score.dart, adherence_feature.dart, app_constant.dart
// MUST NEVER: hardcode the ML service URL or import Flutter
// ============================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:medadhere/core/constants/app_constant.dart';
import 'package:medadhere/core/errors/app_exception.dart';
import 'package:medadhere/shared/models/adherence_feature.dart';

import '../../models/adherence_risk_score.dart';

class AdherenceRiskApiService {
  // ─── public ───────────────────────────────────────────────

  Future<AdherenceRiskScore> predict(AdherenceFeature feature) async {
    final uri = Uri.parse('${AppConstants.mlServiceBaseUrl}/predict');
    final body = jsonEncode({
      'user_id': feature.userId,
      'medication_id': feature.medicationId,
      'rolling_rate_7d': feature.rollingRate7d,
      'rolling_rate_3d': feature.rollingRate3d,
      'current_streak_days': feature.currentStreakDays,
      'previous_day_adherence': feature.previousDayAdherence,
      'avg_dose_time_deviation_minutes': feature.avgDoseTimeDeviationMinutes,
      'worst_day_of_week_rate': feature.worstDayOfWeekRate,
      'days_since_treatment_start': feature.daysSinceTreatmentStart,
      'post_miss_recovery_rate': feature.postMissRecoveryRate,
      'is_cold_start': feature.isColdStart,
    });

    try {
      final response = await http
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        // Server reachable but returned an error — fall back gracefully
        return _localFallback(feature);
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AdherenceRiskScore(
        riskLevel: _parseRiskLevel(json['risk_level'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        isColdStart: feature.isColdStart,
      );
    } on SocketException {
      // ML server not yet hosted — expected during development
      return _localFallback(feature);
    } on TimeoutException {
      // ML server unreachable or slow
      return _localFallback(feature);
    } on AppException {
      rethrow;
    } catch (_) {
      // Any other network or parse failure
      return _localFallback(feature);
    }
  }

  // ─── private ──────────────────────────────────────────────

  /// Rule-based fallback used when the ML service is unreachable.
  /// Uses the same features the ML model would receive.
  /// When the ML service goes live this method becomes dormant —
  /// it only fires on network failure.
  AdherenceRiskScore _localFallback(AdherenceFeature feature) {
    if (feature.isColdStart) {
      return AdherenceRiskScore(
        riskLevel: AdherenceRiskLevel.onTrack,
        confidence: 0.5,
        isColdStart: true,
      );
    }

    final AdherenceRiskLevel level;
    if (feature.rollingRate7d >= 0.85) {
      level = AdherenceRiskLevel.onTrack;
    } else if (feature.rollingRate7d >= 0.60) {
      level = AdherenceRiskLevel.atRisk;
    } else {
      level = AdherenceRiskLevel.highRisk;
    }

    return AdherenceRiskScore(
      riskLevel: level,
      confidence: 0.6,
      isColdStart: false,
    );
  }

  AdherenceRiskLevel _parseRiskLevel(String value) {
    return switch (value) {
      'on_track' => AdherenceRiskLevel.onTrack,
      'at_risk' => AdherenceRiskLevel.atRisk,
      'high_risk' => AdherenceRiskLevel.highRisk,
      _ => AdherenceRiskLevel.atRisk,
    };
  }
}
