// ============================================
// FILE: dose_status_resolver.dart
// LAYER: service
// DOMAIN: dose_logging
// RESPONSIBLE FOR: Pure domain resolver — single source of truth for dose status.
//
// No async, no DB, no side effects. Input in, status out.
// ============================================

import '../models/dose_log.dart';

class DoseStatusResolver {
  const DoseStatusResolver._();

  /// Resolves the canonical status for a single scheduled dose.
  ///
  /// [scheduledTime] — exact DateTime the dose is scheduled for today.
  /// [now]           — current DateTime.
  /// [slotId]        — deterministic ID for this scheduled slot.
  /// [createdAt]     — when the medication was added. Slots before this
  ///                   are treated as later — user cannot have missed them.
  /// [existingLog]   — the DoseLog record if the user already logged this dose.
  static DoseStatus resolve({
    required DateTime scheduledTime,
    required DateTime now,
    required String slotId,
    required DateTime createdAt,
    DoseLog? existingLog,
  }) {
    // User has already logged this dose — match by slotId, trust the status.
    if (existingLog != null && existingLog.slotId == slotId) {
      return existingLog.status;
    }

    // Slot predates medication creation — user cannot have missed this.
    if (scheduledTime.isBefore(createdAt)) {
      return DoseStatus.later;
    }

    final deltaMinutes = scheduledTime.difference(now).inMinutes;

    // Future: more than 30 minutes away
    if (deltaMinutes > 30) {
      return DoseStatus.later;
    }

    // Future: within 30 minutes before scheduled time
    if (deltaMinutes > 0) {
      return DoseStatus.dueNow;
    }

    // Past: within 6 hours of scheduled time (0 to -360 min)
    if (deltaMinutes >= -360) {
      return DoseStatus.overdue;
    }

    // Past: more than 6 hours ago
    return DoseStatus.missed;
  }
}
