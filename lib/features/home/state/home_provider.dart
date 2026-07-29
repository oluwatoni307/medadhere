// ===
// FILE: home_provider.dart
// LAYER: state
// DOMAIN: home
// RESPONSIBLE FOR: Derives and exposes the filtered, sorted, and enriched
//                  list of due medication entries for today's home screen,
//                  plus a same-day tally (total/logged/missed) used by the
//                  streak card's "today" messaging.
// RECEIVES: Ref — reads medicationServiceProvider, doseLogServiceProvider,
//           categoryServiceProvider, authProvider
// RETURNS: AsyncValue<List<DueMedicationEntry>> (unchanged public contract);
//          AsyncValue<TodaySummary> via todaySummaryProvider (new) — a thin
//          watchable wrapper around HomeNotifier.getTodaySummary
// CONNECTS TO: MedicationService, DoseLogService, CategoryService, AuthNotifier
// MUST NEVER: Hold UI layout primitives, make direct repository requests,
//             or import from parallel feature folders
// ===

// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — models
import '../../../shared/models/category.dart';
import '../../../shared/models/medication.dart';
import '../../../shared/models/dose_log.dart';
import '../../../shared/models/adherence_risk_score.dart';

// internal — services
import '../../../shared/services/medication_service_provider.dart';
import '../../../shared/services/dose_log_service_provider.dart';
import '../../../shared/services/dose_log_service.dart';
import '../../../shared/services/category/category_service_provider.dart';

// internal — state (Auth)
import '../../auth/state/auth_notifier_provider.dart';

// internal — utils
import '../../../shared/utils/time_parser.dart';

part 'home_provider.g.dart';

// ─── Urgency tier ────────────────────────────────────────────────────────────

enum MedicationUrgencyTier { tier1, tier2, tier3, tier4 }

// ─── View models ─────────────────────────────────────────────────────────────

class DueMedicationEntry {
  const DueMedicationEntry({
    required this.medication,
    required this.scheduledTime,
    required this.scheduleLabel,
    required this.scheduledTimeDisplay,
    required this.timeRemaining,
    required this.urgencyTier,
    this.categoryLabel,
    this.adherenceRiskLevel,
  });

  final Medication medication;
  final DateTime scheduledTime;
  final String scheduleLabel;
  final String scheduledTimeDisplay;
  final String timeRemaining;
  final MedicationUrgencyTier urgencyTier;
  final String? categoryLabel;
  final AdherenceRiskLevel? adherenceRiskLevel;
}

/// Same-day dose tally for the home screen's streak/today card.
///
/// Built from the same resolved-dose pass as [DueMedicationEntry] so the
/// card's "1 down, 2 to go" messaging can never disagree with the dose
/// list rendered below it — both read off one resolution, not two.
class TodaySummary {
  const TodaySummary({
    required this.total,
    required this.logged,
    required this.missed,
    required this.overdue,
  });

  /// All dose slots scheduled for today, regardless of status.
  final int total;

  /// Doses with status [DoseStatus.taken] or [DoseStatus.skipped] —
  /// anything the user has already acted on.
  final int logged;

  /// Doses with status [DoseStatus.missed] specifically — a status your
  /// system has already finalized as missed, distinct from overdue.
  final int missed;

  /// Doses with status [DoseStatus.overdue] — past their scheduled time
  /// but not yet finalized as missed. Tracked separately from [missed]
  /// because it was previously falling through to neither logged nor
  /// missed, which let the streak card report "nothing logged yet" on a
  /// day already showing several overdue doses in the list below it.
  final int overdue;

  /// Safe fallback for an unauthenticated or errored read. Renders as
  /// "nothing scheduled" rather than a misleading zero-progress state —
  /// callers should treat total == 0 as "don't show a today count," not
  /// as "0 of 0 doses missed."
  static const empty = TodaySummary(total: 0, logged: 0, missed: 0, overdue: 0);
}

/// One resolved dose slot for a single medication, before any filtering
/// or display formatting is applied. Internal to this file — [_fetchDue]
/// and [getTodaySummary] each derive their own view from a list of these
/// rather than re-querying or re-resolving status independently.
class _ResolvedDose {
  const _ResolvedDose({
    required this.medication,
    required this.timeStr,
    required this.status,
    required this.scheduledTime,
    this.categoryLabel,
  });

  final Medication medication;
  final String timeStr;
  final DoseStatus status;
  final DateTime? scheduledTime;
  final String? categoryLabel;
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  AsyncValue<List<DueMedicationEntry>> build() {
    final authState = ref.watch(authProvider);
    final String? uid = authState.value?.uid;

    if (uid == null) {
      return AsyncValue.error('Not authenticated', StackTrace.current);
    }

    _init(uid);
    return const AsyncValue.loading();
  }

  Future<void> _init(String uid) async {
    state = await AsyncValue.guard(() => _fetchDue(uid));
  }

  Future<void> loadDueMedications() async {
    final authState = ref.read(authProvider);
    final String? uid = authState.value?.uid;

    if (uid == null) {
      state = AsyncValue.error('Not authenticated', StackTrace.current);
      return;
    }

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchDue(uid));
  }

  /// Today's dose tally for the streak card. Independent read from the
  /// notifier's own [state] — callers (e.g. the streak notifier/message
  /// builder) invoke this directly rather than watching it, since it's a
  /// same-day snapshot, not part of the due-list stream.
  ///
  /// Returns [TodaySummary.empty] on any auth or fetch failure — the
  /// streak card should quietly omit the today line rather than throw.
  Future<TodaySummary> getTodaySummary(String uid) async {
    final result = await AsyncValue.guard(() => _fetchTodaySummary(uid));
    return result.value ?? TodaySummary.empty;
  }

  // ─── Shared resolution ───────────────────────────────────────────────────

  /// Resolves every dose slot, for every medication, for the current
  /// moment — no filtering, no formatting. Both [_fetchDue] and
  /// [_fetchTodaySummary] build their view on top of this single pass,
  /// so the due list and the today tally can never silently disagree.
  Future<List<_ResolvedDose>> _resolveAllDoses(String uid, DateTime now) async {
    final futures = await Future.wait([
      ref.read(medicationServiceProvider).getMedications(uid),
      ref.read(categoryServiceProvider).getCategories(uid),
    ]);

    final medications = futures[0] as List<Medication>;
    final categories = futures[1] as List<Category>;

    final categoryMap = {for (final c in categories) c.id: c.name};
    final doseLogService = ref.read(doseLogServiceProvider);

    final resolved = <_ResolvedDose>[];

    for (final med in medications) {
      final statusMap = await doseLogService.resolveStatusesForMedication(
        uid,
        med.id,
        med.times,
        now,
        med.createdAt,
      );

      for (final timeStr in med.times) {
        final entry = statusMap[timeStr];

        resolved.add(
          _ResolvedDose(
            medication: med,
            timeStr: timeStr,
            status: entry?.status ?? DoseStatus.later,
            scheduledTime: entry?.scheduledTime,
            categoryLabel: med.categoryId != null
                ? categoryMap[med.categoryId!]
                : null,
          ),
        );
      }
    }

    return resolved;
  }

  // ─── Due list (unchanged behavior, now built on the shared pass) ────────

  Future<List<DueMedicationEntry>> _fetchDue(String uid) async {
    final now = DateTime.now();
    final resolved = await _resolveAllDoses(uid, now);

    final entries = <DueMedicationEntry>[];

    for (final dose in resolved) {
      final status = dose.status;

      // Skip logged or finalized statuses
      if (status == DoseStatus.taken ||
          status == DoseStatus.skipped ||
          status == DoseStatus.missed) {
        continue;
      }

      // Skip past slots that predate medication creation
      final scheduledTime = dose.scheduledTime;
      if (scheduledTime == null) continue;

      if (status == DoseStatus.later && scheduledTime.isBefore(now)) {
        continue;
      }

      final delta = scheduledTime.difference(now);

      // Filter out doses more than 12 hours away — not actionable yet
      if (delta.inMinutes > 720) continue;

      // Filter out doses more than 6 hours overdue — already missed
      if (delta.inMinutes < -360) continue;

      String displayRemaining;
      MedicationUrgencyTier tier;

      if (status == DoseStatus.overdue) {
        displayRemaining = 'Overdue';
        tier = MedicationUrgencyTier.tier4;
      } else {
        displayRemaining = _formatFutureTimeRemaining(delta);
        tier = _deriveFutureUrgencyTier(delta);
      }

      entries.add(
        DueMedicationEntry(
          medication: dose.medication,
          scheduledTime: scheduledTime,
          scheduleLabel: TimeParser.buildScheduleLabel(
            dose.timeStr,
            dose.medication.frequency,
          ),
          scheduledTimeDisplay: dose.timeStr,
          timeRemaining: displayRemaining,
          urgencyTier: tier,
          categoryLabel: dose.categoryLabel,
          adherenceRiskLevel: null,
        ),
      );
    }

    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return entries;
  }

  // ─── Today summary (new) ─────────────────────────────────────────────────

  /// Tallies today's resolved doses into total/logged/missed.
  ///
  /// Deliberately does NOT apply [_fetchDue]'s 12-hour-ahead or 6-hour-
  /// overdue cutoffs — those exist to keep the actionable due list short,
  /// not to define what counts as "today." A dose missed 8 hours ago is
  /// still part of today's tally even though it's dropped from the due
  /// list.
  Future<TodaySummary> _fetchTodaySummary(String uid) async {
    final now = DateTime.now();
    final resolved = await _resolveAllDoses(uid, now);

    final todayResolved = resolved.where((dose) {
      final scheduledTime = dose.scheduledTime;
      if (scheduledTime == null) return false;
      return scheduledTime.year == now.year &&
          scheduledTime.month == now.month &&
          scheduledTime.day == now.day;
    });

    var total = 0;
    var logged = 0;
    var missed = 0;
    var overdue = 0;

    for (final dose in todayResolved) {
      total++;
      switch (dose.status) {
        case DoseStatus.taken:
        case DoseStatus.skipped:
          logged++;
          break;
        case DoseStatus.missed:
          missed++;
          break;
        case DoseStatus.overdue:
          overdue++;
          break;
        default:
          break;
      }
    }

    return TodaySummary(
      total: total,
      logged: logged,
      missed: missed,
      overdue: overdue,
    );
  }
}

// ─── Local Helpers ────────────────────────────────────────────────────────────

MedicationUrgencyTier _deriveFutureUrgencyTier(Duration delta) {
  final minutes = delta.inMinutes;
  if (minutes > 360) return MedicationUrgencyTier.tier1;
  if (minutes > 120) return MedicationUrgencyTier.tier2;
  if (minutes > 30) return MedicationUrgencyTier.tier3;
  return MedicationUrgencyTier.tier4;
}

String _formatFutureTimeRemaining(Duration delta) {
  final totalMinutes = delta.inMinutes;
  if (totalMinutes <= 0) return '0m';

  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours == 0) return '${minutes}m';
  return '${hours}h ${minutes}m';
}

// ─── Today summary — watchable wrapper ─────────────────────────────────────
//
// Thin pass-through, not a second source of logic. All real aggregation
// lives in HomeNotifier.getTodaySummary / _fetchTodaySummary above — this
// exists only so the widget tree can `ref.watch` it, since a plain async
// method on a Notifier isn't watchable on its own. Refresh via
// `ref.invalidate(todaySummaryProvider)` rather than a hand-written
// reload method.

@riverpod
Future<TodaySummary> todaySummary(Ref ref) async {
  final authState = ref.watch(authProvider);
  final String? uid = authState.value?.uid;
  if (uid == null) return TodaySummary.empty;

  return ref.read(homeProvider.notifier).getTodaySummary(uid);
}
