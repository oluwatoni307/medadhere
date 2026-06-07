// ============================================
// FILE: dose_log_service.dart
// LAYER: service
// DOMAIN: dose_logging
// RESPONSIBLE FOR: Mediating dose logging business logic between caller and repository
// RECEIVES: Auth UID, DoseLog objects and IDs
// RETURNS: Future<void>, Future<List<DoseLog>>
// CONNECTS TO: dose_log_repository.dart, app_exception.dart, time_parser.dart, dose_status_resolver.dart
// MUST NEVER: Call Firestore directly or contain UI code
// ============================================

// internal — models
import '../models/dose_log.dart';

// internal — repositories
import '../repositories/dose_log_repository.dart';

// internal — core
import '../../core/errors/app_exception.dart';

// internal — utils & resolvers
import '../utils/time_parser.dart';
import 'dose_status_resolver.dart';

// ─── Result object ────────────────────────────────────────────────────────────

class ResolvedDoseStatus {
  const ResolvedDoseStatus({
    required this.status,
    required this.scheduledTime,
    required this.slotId,
  });

  final DoseStatus status;
  final DateTime scheduledTime;
  final String slotId;
}

// ─── Service ──────────────────────────────────────────────────────────────────

class DoseLogService {
  const DoseLogService(this._repository);

  final DoseLogRepository _repository;

  Future<void> logDose(String uid, DoseLog log) async {
    if (log.status == DoseStatus.later || log.status == DoseStatus.dueNow) {
      throw AppException('Cannot log a transient status: ${log.status.name}');
    }
    try {
      await _repository.add(uid, log);
    } catch (e) {
      throw AppException('Failed to log dose: $e');
    }
  }

  Future<List<DoseLog>> getDoseLogsForMedication(
    String uid,
    String medicationId,
  ) async {
    try {
      return await _repository.getByMedicationId(uid, medicationId);
    } catch (e) {
      throw AppException('Failed to fetch dose logs: $e');
    }
  }

  Future<List<DoseLog>> getDoseLogsForDateRange(
    String uid,
    DateTime start,
    DateTime end,
  ) async {
    try {
      return await _repository.getByDateRange(uid, start, end);
    } catch (e) {
      throw AppException('Failed to fetch dose logs: $e');
    }
  }

  Future<void> undoLog(String uid, String logId) async {
    try {
      await _repository.delete(uid, logId);
    } catch (e) {
      throw AppException('Failed to undo log: $e');
    }
  }

  /// Resolves [ResolvedDoseStatus] for every scheduled time on a medication for today.
  ///
  /// Builds a deterministic slotId for each scheduled time, looks up
  /// any existing log by slotId directly — no fragile time comparison.
  Future<Map<String, ResolvedDoseStatus>> resolveStatusesForMedication(
    String uid,
    String medicationId,
    List<String> timeStrings,
    DateTime now,
    DateTime createdAt, // ← added
  ) async {
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    try {
      final allLogs = await _repository.getByDateRange(
        uid,
        todayStart,
        todayEnd,
      );
      final medLogs = allLogs
          .where((l) => l.medicationId == medicationId)
          .toList();

      final result = <String, ResolvedDoseStatus>{};

      for (final timeStr in timeStrings) {
        final parsed = TimeParser.parseTimeString(timeStr, now);
        if (parsed == null) {
          result[timeStr] = ResolvedDoseStatus(
            status: DoseStatus.later,
            scheduledTime: now,
            slotId: '',
          );
          continue;
        }

        final slotId = TimeParser.buildSlotId(medicationId, parsed);

        final existingLog = medLogs
            .where((l) => l.slotId == slotId)
            .firstOrNull;

        final status = DoseStatusResolver.resolve(
          scheduledTime: parsed,
          now: now,
          slotId: slotId,
          existingLog: existingLog,
          createdAt: createdAt, // ← added
        );

        result[timeStr] = ResolvedDoseStatus(
          status: status,
          scheduledTime: parsed,
          slotId: slotId,
        );
      }

      return result;
    } catch (e) {
      throw AppException('Failed to resolve dose statuses: $e');
    }
  }
}
