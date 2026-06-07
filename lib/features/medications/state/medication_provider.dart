// ============================================
// FILE: medication_provider.dart
// LAYER: state
// DOMAIN: medications
// RESPONSIBLE FOR: Medication CRUD with notification reschedule trigger after each mutation.
// RECEIVES: Service method calls
// RETURNS: MedicationState
// CONNECTS TO: medication_service.dart, category_service.dart,
//              medication_service_provider.dart, category_service_provider.dart,
//              dose_log_service_provider.dart, time_parser.dart, auth_notifier_provider.dart,
//              notification_scheduler_service_provider.dart
// MUST NEVER: Contain UI code or call repositories directly
// ============================================

// packages
import 'package:flutter/foundation.dart' hide Category;
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — models
import '../../../shared/models/medication.dart';
import '../../../shared/models/category.dart';
import '../../../shared/models/dose_log.dart';

// internal — services
import '../../../shared/services/category/category_service_provider.dart';
import '../../../shared/services/medication_service_provider.dart';
import '../../../shared/services/dose_log_service_provider.dart';
import '../../../shared/services/dose_log_service.dart';
import '../../../shared/services/notification_service.dart';
import '../../../shared/services/notification_scheduler_service_provider.dart';

// internal — state (Auth)
import '../../auth/state/auth_notifier_provider.dart';

// internal — logic
import '../../../shared/utils/time_parser.dart';

part 'medication_provider.g.dart';

// --- sentinel ---

class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

// --- data classes ---

class MedicationGroup {
  const MedicationGroup({required this.label, required this.medications});

  final String label;
  final List<EnrichedMedication> medications;
}

class EnrichedMedication {
  const EnrichedMedication({
    required this.medication,
    required this.statusByTime,
  });

  final Medication medication;
  final Map<String, ResolvedDoseStatus> statusByTime;

  DoseStatus get primaryStatus => medication.times.isNotEmpty
      ? statusByTime[medication.times.first]?.status ?? DoseStatus.later
      : DoseStatus.later;
}

// --- state ---

class MedicationState {
  const MedicationState({
    this.medications = const [],
    this.categories = const [],
    this.groupedMedications = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Medication> medications;
  final List<Category> categories;
  final List<MedicationGroup> groupedMedications;
  final bool isLoading;
  final String? error;

  MedicationState copyWith({
    List<Medication>? medications,
    List<Category>? categories,
    List<MedicationGroup>? groupedMedications,
    bool? isLoading,
    Object? error = _sentinel,
  }) {
    return MedicationState(
      medications: medications ?? this.medications,
      categories: categories ?? this.categories,
      groupedMedications: groupedMedications ?? this.groupedMedications,
      isLoading: isLoading ?? this.isLoading,
      error: error == _sentinel ? this.error : error as String?,
    );
  }
}

// --- notifier ---

@riverpod
class MedicationNotifier extends _$MedicationNotifier {
  @override
  MedicationState build() => const MedicationState();

  // --- private helpers ---

  String? _getUid() {
    final authState = ref.read(authProvider);
    return authState.value?.uid;
  }

  /// Fire-and-forget notification reschedule.
  /// Skipped if uid is null. Notification failure never breaks mutation.
  void _triggerReschedule(String uid) {
    // ── DIAGNOSTIC PROBE ── remove after fix confirmed ──────────
    print('NSS|TRIGGER|uid=$uid');
    print('NSS|PERMISSION|${NotificationService.instance.permissionGranted}');
    ref
        .read(medicationServiceProvider)
        .getMedications(uid)
        .then(
          (list) => print('NSS|HIVE_COUNT|${list.length}'),
          onError: (e) => print('NSS|HIVE_ERROR|$e'),
        );
    // ────────────────────────────────────────────────────────────

    ref
        .read(notificationSchedulerServiceProvider)
        .rescheduleAll(uid)
        .then((_) => print('NSS|DONE|success'))
        .catchError((e, stack) {
          print('NSS|FAILED|$e');
          print('NSS|STACK|$stack');
        });
  }

  // --- public methods ---

  Future<void> loadMedications() async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final now = DateTime.now();

      final futures = await Future.wait([
        ref.read(medicationServiceProvider).getMedications(uid),
        ref.read(categoryServiceProvider).getCategories(uid),
      ]);

      final meds = futures[0] as List<Medication>;
      final cats = futures[1] as List<Category>;

      final enrichedMedications = <EnrichedMedication>[];
      final doseLogService = ref.read(doseLogServiceProvider);

      for (final med in meds) {
        final statusByTime = await doseLogService.resolveStatusesForMedication(
          uid,
          med.id,
          med.times,
          now,
          med.createdAt,
        );
        enrichedMedications.add(
          EnrichedMedication(medication: med, statusByTime: statusByTime),
        );
      }

      state = state.copyWith(
        medications: meds,
        categories: cats,
        groupedMedications: _groupMedications(enrichedMedications, now),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addMedication(Medication medication) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(medicationServiceProvider).addMedication(uid, medication);
      await loadMedications();
      _triggerReschedule(uid);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateMedication(Medication medication) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref
          .read(medicationServiceProvider)
          .updateMedication(uid, medication);
      await loadMedications();
      _triggerReschedule(uid);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteMedication(String id) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(medicationServiceProvider).deleteMedication(uid, id);
      await loadMedications();
      _triggerReschedule(uid);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addCategory(Category category) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(categoryServiceProvider).addCategory(uid, category);
      await loadMedications();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteCategory(String id) async {
    final uid = _getUid();
    if (uid == null) {
      state = state.copyWith(error: 'Not authenticated', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(categoryServiceProvider).deleteCategory(uid, id);
      await loadMedications();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  // --- private helpers ---

  List<MedicationGroup> _groupMedications(
    List<EnrichedMedication> enrichedMeds,
    DateTime now,
  ) {
    final buckets = <String, List<EnrichedMedication>>{};
    for (final enriched in enrichedMeds) {
      buckets
          .putIfAbsent(_resolveGroupLabel(enriched.medication), () => [])
          .add(enriched);
    }
    return ['Morning', 'Afternoon', 'Evening', 'Night', 'As needed']
        .where((label) => buckets.containsKey(label))
        .map(
          (label) =>
              MedicationGroup(label: label, medications: buckets[label]!),
        )
        .toList();
  }

  String _resolveGroupLabel(Medication med) {
    if (med.times.isEmpty || med.frequency == 'As needed') return 'As needed';
    final h = TimeParser.parseTimeString(med.times.first, DateTime.now())?.hour;
    if (h == null) return 'As needed';
    if (h >= 5 && h < 12) return 'Morning';
    if (h >= 12 && h < 17) return 'Afternoon';
    if (h >= 17 && h < 21) return 'Evening';
    return 'Night';
  }
}
