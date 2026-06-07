// ============================================
// FILE: notification_scheduler_service.dart
// LAYER: service
// DOMAIN: shared
// RESPONSIBLE FOR: Pure orchestration of notification scheduling.
//                  Fetches medications, cancels old alarms, schedules new ones.
//                  Stateless, no Riverpod, no UI.
// RECEIVES: uid, plus injected NotificationService & MedicationService
// RETURNS: Future<void> — throws on failure, never swallows
// CONNECTS TO: MedicationNotifier (calls directly), NotificationService
// MUST NEVER: Import Riverpod, Flutter widgets, or provider ref
// ============================================

import 'package:flutter/foundation.dart';

import '../models/medication.dart';
import '../models/notification_payload.dart';
import 'medication_service.dart';
import 'notification_service.dart';

class NotificationSchedulerService {
  const NotificationSchedulerService({
    required NotificationService notificationService,
    required MedicationService medicationService,
  }) : _notificationService = notificationService,
       _medicationService = medicationService;

  final NotificationService _notificationService;
  final MedicationService _medicationService;

  /// Wipes all existing local notifications and re-schedules every
  /// medication + time combo for the given user.
  Future<void> rescheduleAll(String uid) async {
    if (!_notificationService.permissionGranted) {
      debugPrint('NotificationSchedulerService: permission denied, aborting');
      throw StateError('Notification permission not granted');
    }

    // 1. Cancel everything
    await _notificationService.cancelAll();

    // 2. Fetch current medications
    final medications = await _medicationService.getMedications(uid);
    if (medications.isEmpty) {
      debugPrint('NotificationSchedulerService: no medications to schedule');
      return;
    }

    // 3. Schedule
    for (final medication in medications) {
      for (final timeString in medication.times) {
        final parsed = _parseTime(timeString);
        if (parsed == null) {
          debugPrint(
            'NotificationSchedulerService: skipping unparseable time "$timeString"',
          );
          continue;
        }

        final notificationId = _stableId(medication.id, timeString);

        final payload = NotificationPayload(
          medicationId: medication.id,
          medicationName: medication.name,
          doseAmount: medication.dosage,
          scheduleLabel: timeString,
          scheduleId: '${medication.id}_$timeString',
          scheduledTimeMs: DateTime.now()
              .copyWith(hour: parsed.$1, minute: parsed.$2, second: 0)
              .millisecondsSinceEpoch,
        );

        await _notificationService.scheduleOne(
          id: notificationId,
          title: 'Time to take ${medication.name}',
          body: '${medication.dosage} — $timeString',
          payload: payload.toPayload(),
          hour: parsed.$1,
          minute: parsed.$2,
        );
      }
    }

    debugPrint(
      'NotificationSchedulerService: scheduled for ${medications.length} medications',
    );
  }

  /// Parses both 24-hour ("14:30") and 12-hour ("02:30 PM") time strings.
  /// Returns (hour, minute) in 24-hour values, or null if unparseable.
  (int, int)? _parseTime(String timeString) {
    // Normalise: collapse multiple spaces, uppercase
    final s = timeString.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

    // 12-hour: "HH:MM AM" or "HH:MM PM"
    final twelve = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$');
    final m12 = twelve.firstMatch(s);
    if (m12 != null) {
      var hour = int.parse(m12.group(1)!);
      final minute = int.parse(m12.group(2)!);
      final period = m12.group(3)!;
      if (minute < 0 || minute > 59) return null;
      if (period == 'AM') {
        if (hour == 12) hour = 0; // 12:xx AM → 0:xx
      } else {
        if (hour != 12) hour += 12; // 1–11 PM → 13–23
      }
      if (hour < 0 || hour > 23) return null;
      return (hour, minute);
    }

    // 24-hour: "HH:MM"
    final twentyFour = RegExp(r'^(\d{1,2}):(\d{2})$');
    final m24 = twentyFour.firstMatch(s);
    if (m24 != null) {
      final hour = int.parse(m24.group(1)!);
      final minute = int.parse(m24.group(2)!);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return (hour, minute);
    }

    return null;
  }

  /// Deterministic int ID. Object.hash is Jenkins-style and far safer
  /// than XOR of two hashCodes.
  static int _stableId(String medicationId, String timeString) {
    return Object.hash(medicationId, timeString);
  }
}
