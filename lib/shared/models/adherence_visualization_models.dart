// ============================================
// FILE: adherence_visualization_models.dart
// LAYER: model
// DOMAIN: adherence
// RESPONSIBLE FOR: Output models for AdherenceVisualizationService.
//                  Feeds the 7-day strip, 30-day line chart, and 90-day bar chart.
// RECEIVES: nothing — pure data classes
// RETURNS: typed model instances
// CONNECTS TO: adherence_visualization_service.dart,
//              adherence_visualization_provider.dart
// MUST NEVER: import Flutter, contain business logic, or call any service
// ============================================

// internal — reuse existing status enum
import 'dose_log.dart' show DoseStatus;

// ─── shared primitives ────────────────────────────────────────────────────────

/// A single day's resolved status for one medication.
class DayStatusEntry {
  const DayStatusEntry({
    required this.date,
    required this.status,
    this.scheduledTime,
    this.loggedAt,
  });

  /// Midnight-normalised date for this entry.
  final DateTime date;

  /// Resolved status for this day. Reuses the existing [DoseStatus] enum.
  /// [DoseStatus.skipped] renders identically to [DoseStatus.missed] in the
  /// strip — a conscious product decision. Change only here if that changes.
  final DoseStatus status;

  /// Scheduled time for the dose on this day. Null if no dose was scheduled.
  final DateTime? scheduledTime;

  /// Actual logged time. Null if not yet taken or missed.
  final DateTime? loggedAt;
}

/// One medication row in the 7-day strip.
class MedicationStripRow {
  const MedicationStripRow({
    required this.medicationId,
    required this.name,
    required this.doseLabel,
    required this.statuses,
    required this.priorityScore,
  });

  final String medicationId;

  /// Display name — e.g. "Metformin 500mg".
  final String name;

  /// Short dose description — e.g. "1 tablet · twice daily".
  final String doseLabel;

  /// Exactly 7 entries, index 0 = oldest day, index 6 = today.
  final List<DayStatusEntry> statuses;

  /// Computed by the service. Higher = more informative / higher risk.
  /// UI sorts descending. Never displayed raw.
  final double priorityScore;
}

/// A single day's aggregate completion rate across all medications.
class DailyRate {
  const DailyRate({required this.date, required this.rate});

  /// Midnight-normalised date.
  final DateTime date;

  /// Fraction of scheduled doses taken that day across all medications.
  /// Range: 0.0–1.0. Excludes [DoseStatus.later] and [DoseStatus.dueNow]
  /// from the denominator — only resolved statuses count.
  final double rate;
}

/// One week's aggregate completion rate across all medications.
class WeeklyRate {
  const WeeklyRate({
    required this.weekNumber,
    required this.weekStart,
    required this.rate,
  });

  /// 1-indexed week number within the 90-day window. 1 = oldest, 13 = most recent.
  final int weekNumber;

  /// Monday of this week, midnight-normalised.
  final DateTime weekStart;

  /// Fraction of scheduled doses taken this week across all medications.
  /// Range: 0.0–1.0.
  final double rate;
}

// ─── view output models ───────────────────────────────────────────────────────

/// Output of [AdherenceVisualizationService.getStripData].
/// Feeds the 7-day strip view.
class AdherenceStripData {
  const AdherenceStripData({
    required this.medications,
    required this.generatedAt,
  });

  /// Returns an unauthenticated / cold-start sentinel with no medications.
  factory AdherenceStripData.empty() =>
      AdherenceStripData(medications: const [], generatedAt: DateTime(0));

  /// Sorted by [MedicationStripRow.priorityScore] descending.
  /// First 3 shown by default — remainder revealed on expand.
  final List<MedicationStripRow> medications;

  final DateTime generatedAt;

  /// Convenience — top 3 by priority for the collapsed default view.
  List<MedicationStripRow> get topMedications => medications.take(3).toList();

  /// Remainder shown on expand.
  List<MedicationStripRow> get remainingMedications =>
      medications.length > 3 ? medications.skip(3).toList() : [];

  bool get hasMore => medications.length > 3;
}

/// Output of [AdherenceVisualizationService.getMonthData].
/// Feeds the 30-day line chart.
class AdherenceMonthData {
  const AdherenceMonthData({
    required this.dailyRates,
    required this.averageRate,
    required this.bestDayOfWeek,
    required this.worstDayOfWeek,
    required this.generatedAt,
  });

  /// Returns an unauthenticated / cold-start sentinel with no data.
  factory AdherenceMonthData.empty() => AdherenceMonthData(
    dailyRates: const [],
    averageRate: 0.0,
    bestDayOfWeek: '',
    worstDayOfWeek: '',
    generatedAt: DateTime(0),
  );

  /// Exactly 30 entries, index 0 = oldest day, index 29 = today.
  final List<DailyRate> dailyRates;

  /// Mean of all 30 daily rates.
  final double averageRate;

  /// Day of week with highest average rate — e.g. "Wednesday".
  final String bestDayOfWeek;

  /// Day of week with lowest average rate — e.g. "Tuesday".
  final String worstDayOfWeek;

  final DateTime generatedAt;
}

/// Output of [AdherenceVisualizationService.getTrendData].
/// Feeds the 90-day bar chart.
class AdherenceTrendData {
  const AdherenceTrendData({
    required this.weeklyRates,
    required this.averageRate,
    required this.trendDirection,
    required this.generatedAt,
  });

  /// Returns an unauthenticated / cold-start sentinel with no data.
  factory AdherenceTrendData.empty() => AdherenceTrendData(
    weeklyRates: const [],
    averageRate: 0.0,
    trendDirection: TrendDirection.stable,
    generatedAt: DateTime(0),
  );

  /// Exactly 13 entries, index 0 = oldest week, index 12 = current week.
  final List<WeeklyRate> weeklyRates;

  /// Mean of all 13 weekly rates.
  final double averageRate;

  /// Reuses [TrendDirection] from adherence_dashboard_state.dart.
  /// Computed by comparing first-half average vs second-half average
  /// of the 13-week window.
  final TrendDirection trendDirection;

  final DateTime generatedAt;
}

// ─── trend direction ──────────────────────────────────────────────────────────

/// Reused across dashboard state and visualization trend data.
/// Defined here to avoid a circular import with adherence_dashboard_state.dart.
///
/// If [TrendDirection] already exists in adherence_dashboard_state.dart,
/// remove this declaration and import from there instead.
enum TrendDirection { improving, stable, declining }
