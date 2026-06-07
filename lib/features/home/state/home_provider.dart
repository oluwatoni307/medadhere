// ===
// FILE: home_provider.dart
// LAYER: state
// DOMAIN: home
// RESPONSIBLE FOR: Derives and exposes the filtered, sorted, and enriched
//                  list of due medication entries for today's home screen.
// RECEIVES: Ref — reads medicationServiceProvider, doseLogServiceProvider,
//           categoryServiceProvider, authProvider
// RETURNS: AsyncValue<List<DueMedicationEntry>>
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

// ─── View model ──────────────────────────────────────────────────────────────

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

  Future<List<DueMedicationEntry>> _fetchDue(String uid) async {
    final now = DateTime.now();

    final futures = await Future.wait([
      ref.read(medicationServiceProvider).getMedications(uid),
      ref.read(categoryServiceProvider).getCategories(uid),
    ]);

    final medications = futures[0] as List<Medication>;
    final categories = futures[1] as List<Category>;

    final categoryMap = {for (final c in categories) c.id: c.name};
    final doseLogService = ref.read(doseLogServiceProvider);

    final entries = <DueMedicationEntry>[];

    for (final med in medications) {
      final statusMap = await doseLogService.resolveStatusesForMedication(
        uid,
        med.id,
        med.times,
        now,
        med.createdAt, // ← added
      );

      for (final timeStr in med.times) {
        final resolved = statusMap[timeStr];
        final status = resolved?.status ?? DoseStatus.later;

        // Skip logged or finalized statuses
        if (status == DoseStatus.taken ||
            status == DoseStatus.skipped ||
            status == DoseStatus.missed) {
          continue;
        }

        // Skip past slots that predate medication creation
        final scheduledTime = resolved?.scheduledTime;
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
            medication: med,
            scheduledTime: scheduledTime,
            scheduleLabel: TimeParser.buildScheduleLabel(
              timeStr,
              med.frequency,
            ),
            scheduledTimeDisplay: timeStr,
            timeRemaining: displayRemaining,
            urgencyTier: tier,
            categoryLabel: med.categoryId != null
                ? categoryMap[med.categoryId!]
                : null,
            adherenceRiskLevel: null,
          ),
        );
      }
    }

    entries.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    return entries;
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
