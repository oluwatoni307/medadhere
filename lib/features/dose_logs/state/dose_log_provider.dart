// ============================================
// FILE: dose_log_provider.dart
// LAYER: state
// DOMAIN: dose_logs
// RESPONSIBLE FOR: Managing dose log state and actions including create, undo, and notes update
// RECEIVES: medicationId, scheduleId, scheduledTime, DoseStatus, and optional notes from log_dose_screen
// RETURNS: DoseLogState consumed by log_dose_screen
// CONNECTS TO: dose_log_service_provider.dart, dose_log.dart, auth_notifier_provider.dart
// MUST NEVER: Contain UI logic, hold timer state, or call repositories directly
// ============================================

// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — models
import '../../../shared/models/dose_log.dart';

// internal — services
import '../../../shared/services/dose_log_service_provider.dart';

// internal — state (Auth)
import '../../auth/state/auth_notifier_provider.dart';

// internal — utils
import '../../../shared/utils/time_parser.dart';

part 'dose_log_provider.g.dart';

// --- state ---

class DoseLogState {
  const DoseLogState({
    required this.doseLogs,
    required this.isLoading,
    required this.error,
    required this.lastLogId,
    required this.logStatus,
    required this.selectedStatus,
    required this.undoAvailable,
    required this.notesValue,
  });

  final List<DoseLog> doseLogs;
  final bool isLoading;
  final String? error;
  final String? lastLogId;
  final AsyncValue<void> logStatus;
  final DoseStatus? selectedStatus;
  final bool undoAvailable;
  final String? notesValue;

  DoseLogState copyWith({
    List<DoseLog>? doseLogs,
    bool? isLoading,
    String? error,
    String? lastLogId,
    AsyncValue<void>? logStatus,
    DoseStatus? selectedStatus,
    bool? undoAvailable,
    String? notesValue,
  }) => DoseLogState(
    doseLogs: doseLogs ?? this.doseLogs,
    isLoading: isLoading ?? this.isLoading,
    error: error ?? this.error,
    lastLogId: lastLogId ?? this.lastLogId,
    logStatus: logStatus ?? this.logStatus,
    selectedStatus: selectedStatus ?? this.selectedStatus,
    undoAvailable: undoAvailable ?? this.undoAvailable,
    notesValue: notesValue ?? this.notesValue,
  );
}

// --- notifier ---

@riverpod
class DoseLogNotifier extends _$DoseLogNotifier {
  @override
  DoseLogState build() => DoseLogState(
    doseLogs: const [],
    isLoading: false,
    error: null,
    lastLogId: null,
    logStatus: const AsyncData<void>(null),
    selectedStatus: null,
    undoAvailable: false,
    notesValue: null,
  );

  // --- private helper for UID extraction ---

  String? _getUid() {
    return ref.read(authProvider).value?.uid;
  }

  // --- public methods ---

  Future<void> logDose(
    String medicationId,
    String scheduleId,
    DateTime scheduledTime,
    DoseStatus status,
    String? notes,
  ) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      logStatus: const AsyncLoading<void>(),
    );
    try {
      // Build deterministic slotId — single source of truth for matching
      final slotId = TimeParser.buildSlotId(medicationId, scheduledTime);

      final log = DoseLog(
        id: slotId, // slotId as document ID prevents duplicates
        slotId: slotId,
        scheduleId: scheduleId,
        medicationId: medicationId,
        status: status,
        scheduledTime: scheduledTime,
        loggedAt: DateTime.now(),
        notes: notes,
        userId: uid,
      );

      await ref.read(doseLogServiceProvider).logDose(uid, log);

      state = state.copyWith(
        doseLogs: [...state.doseLogs, log],
        isLoading: false,
        lastLogId: log.id,
        logStatus: const AsyncData<void>(null),
        selectedStatus: status,
        undoAvailable: true,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        logStatus: AsyncError<void>(e, st),
      );
    }
  }

  Future<void> undoLog() async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    final logId = state.lastLogId;
    if (logId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(doseLogServiceProvider).undoLog(uid, logId);

      final remaining = state.doseLogs.where((l) => l.id != logId).toList();
      state = DoseLogState(
        doseLogs: remaining,
        isLoading: false,
        error: null,
        lastLogId: null,
        logStatus: const AsyncData<void>(null),
        selectedStatus: null,
        undoAvailable: false,
        notesValue: null,
      );
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        logStatus: AsyncError<void>(e, st),
      );
    }
  }

  void updateNotes(String value) {
    state = state.copyWith(notesValue: value);
  }

  Future<void> loadLogsForMedication(String medicationId) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final logs = await ref
          .read(doseLogServiceProvider)
          .getDoseLogsForMedication(uid, medicationId);

      state = state.copyWith(doseLogs: logs, isLoading: false);
    } catch (e, st) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        logStatus: AsyncError<void>(e, st),
      );
    }
  }
}
