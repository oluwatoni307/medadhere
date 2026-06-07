// ============================================
// FILE: adherence_feature_logic.dart
// LAYER: logic
// DOMAIN: adherence
// RESPONSIBLE FOR: Computes all 8 adherence features from dose logs and a medication record
// RECEIVES: List<DoseLog>, Medication, DateTime now
// RETURNS: individual feature values as primitives or collections
// CONNECTS TO: dose_log.dart, medication.dart
// MUST NEVER: import Flutter or call any repository
// ============================================

// flutter — none
// packages
import 'dart:math';
// internal — models
import '../models/dose_log.dart';
import '../models/medication.dart';

// --- helpers ---

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// --- rolling rate ---

double rollingRate(
  List<DoseLog> logs,
  Medication med,
  int windowDays,
  DateTime now,
) {
  final denominator = med.times.length * windowDays;
  if (denominator == 0) return 1.0;
  final windowStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: windowDays));
  final taken = logs
      .where(
        (l) =>
            l.loggedAt != null &&
            !l.loggedAt!.isBefore(windowStart) &&
            l.status == DoseStatus.taken,
      )
      .length;
  return taken / denominator;
}

// --- streak ---

int currentStreak(List<DoseLog> logs, Medication med, DateTime now) {
  if (med.times.isEmpty) return 0;
  int streak = 0;
  for (int i = 0; i < 90; i++) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: i));
    final takenCount = logs
        .where(
          (l) =>
              l.loggedAt != null &&
              _isSameDay(l.loggedAt!, day) &&
              l.status == DoseStatus.taken,
        )
        .length;
    if (takenCount < med.times.length) break;
    streak++;
  }
  return streak;
}

// --- previous day ---

double previousDayAdherence(List<DoseLog> logs, Medication med, DateTime now) {
  if (med.times.isEmpty) return 1.0;
  final yesterday = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 1));
  final taken = logs
      .where(
        (l) =>
            l.loggedAt != null &&
            _isSameDay(l.loggedAt!, yesterday) &&
            l.status == DoseStatus.taken,
      )
      .length;
  return taken / med.times.length;
}

// --- deviation ---

double avgDoseTimeDeviation(List<DoseLog> logs, DateTime now) {
  final windowStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(const Duration(days: 14));
  final taken = logs
      .where(
        (l) =>
            l.loggedAt != null &&
            !l.loggedAt!.isBefore(windowStart) &&
            l.status == DoseStatus.taken,
      )
      .toList();
  if (taken.length < 3) return 0.0;
  final total = taken.fold<double>(
    0.0,
    (sum, l) => sum + l.loggedAt!.difference(l.scheduledTime).inMinutes.abs(),
  );
  return total / taken.length;
}

// --- day of week pattern ---

Map<int, double> dayOfWeekPattern(
  List<DoseLog> logs,
  Medication med,
  DateTime now,
) {
  if (med.times.isEmpty) return {};
  final taken = <int, int>{};
  final scheduled = <int, int>{};
  for (int i = 0; i < 28; i++) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: i));
    final wd = day.weekday;
    scheduled[wd] = (scheduled[wd] ?? 0) + med.times.length;
    final dayTaken = logs
        .where(
          (l) =>
              l.loggedAt != null &&
              _isSameDay(l.loggedAt!, day) &&
              l.status == DoseStatus.taken,
        )
        .length;
    taken[wd] = (taken[wd] ?? 0) + dayTaken;
  }
  return {
    for (final wd in scheduled.keys)
      if ((scheduled[wd] ?? 0) > 0) wd: (taken[wd] ?? 0) / scheduled[wd]!,
  };
}

// --- worst day ---

double worstDayOfWeekRate(Map<int, double> pattern) {
  if (pattern.isEmpty) return 1.0;
  return pattern.values.reduce(min);
}

// --- treatment start ---

int daysSinceTreatmentStart(List<DoseLog> logs, DateTime now) {
  final timed = logs.where((l) => l.loggedAt != null).toList();
  if (timed.isEmpty) return 0;
  final earliest = timed
      .map((l) => l.loggedAt!)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return now.difference(earliest).inDays;
}

// --- recovery ---

double postMissRecoveryRate(List<DoseLog> logs) {
  final missed = logs.where((l) => l.status == DoseStatus.missed).toList();
  if (missed.isEmpty) return 0.0;
  final recoveries = missed.where((m) {
    if (m.loggedAt == null) return false;
    final nextDay = DateTime(
      m.loggedAt!.year,
      m.loggedAt!.month,
      m.loggedAt!.day,
    ).add(const Duration(days: 1));
    return logs.any(
      (l) =>
          l.loggedAt != null &&
          _isSameDay(l.loggedAt!, nextDay) &&
          l.status == DoseStatus.taken,
    );
  }).length;
  return recoveries / missed.length;
}

// --- last streak ---
//
// Walks backward past the current broken gap, then counts
// the previous consecutive fully-taken run.
// Returns 0 if no previous streak exists.

int lastStreak(List<DoseLog> logs, Medication med, DateTime now) {
  if (med.times.isEmpty) return 0;

  // Phase 1 — skip past the current gap (days with incomplete doses)
  int offset = 0;
  for (int i = 0; i < 90; i++) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: i));
    final takenCount = logs
        .where(
          (l) =>
              l.loggedAt != null &&
              _isSameDay(l.loggedAt!, day) &&
              l.status == DoseStatus.taken,
        )
        .length;
    if (takenCount >= med.times.length) {
      // Hit a fully-taken day — gap is behind us
      offset = i;
      break;
    }
  }

  // Phase 2 — count the consecutive run from that point
  int streak = 0;
  for (int i = offset; i < 90; i++) {
    final day = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: i));
    final takenCount = logs
        .where(
          (l) =>
              l.loggedAt != null &&
              _isSameDay(l.loggedAt!, day) &&
              l.status == DoseStatus.taken,
        )
        .length;
    if (takenCount < med.times.length) break;
    streak++;
  }

  return streak;
}
