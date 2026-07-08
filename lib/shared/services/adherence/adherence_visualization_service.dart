// ============================================
// FILE: adherence_visualization_service.dart
// LAYER: service
// DOMAIN: adherence
// RESPONSIBLE FOR: Computing daily compliance grids and calculating status
//                  matrices for past, present, and future scheduled doses.
// RECEIVES: Service instances via dependency injection
// RETURNS: Visualisation states and historic status grids
// CONNECTS TO: medication_service.dart, dose_log_service.dart, dose_status_resolver.dart
// MUST NEVER: Keep local UI states or directly query collections bypass-style
// ============================================

import '../../../shared/models/dose_log.dart';
import '../../../shared/models/medication.dart';
import '../../../shared/models/adherence_visualization_models.dart';
import '../../../shared/utils/time_parser.dart';
import '../../../shared/services/dose_status_resolver.dart';
import '../dose_log_service.dart';
import '../medication_service.dart';

class AdherenceVisualizationService {
  const AdherenceVisualizationService({
    required MedicationService medicationService,
    required DoseLogService doseLogService,
  }) : _medicationService = medicationService,
       _doseLogService = doseLogService;

  final MedicationService _medicationService;
  final DoseLogService _doseLogService;

  // ─── Public API Endpoints ──────────────────────────────────────────────────

  Future<AdherenceStripData> getStripData(String userId) async {
    final now = DateTime.now();
    final medications = await _medicationService.getMedications(userId);
    final rowList = <MedicationStripRow>[];

    for (final med in medications) {
      final entries = <DayStatusEntry>[];
      int missedCount = 0;
      int skippedCount = 0;

      for (int i = 4; i >= 0; i--) {
        final targetDate = now.subtract(Duration(days: i));
        final dayStart = DateTime(
          targetDate.year,
          targetDate.month,
          targetDate.day,
        );

        final statusMap = await resolveDayStatus(
          userId: userId,
          medicationId: med.id,
          targetDate: dayStart,
          now: now,
        );

        // Count misses and skips separately — skipped carries half the
        // priority weight of a miss since it was a deliberate user choice.
        for (final status in statusMap.values) {
          if (status == DoseStatus.missed) missedCount++;
          if (status == DoseStatus.skipped) skippedCount++;
        }
        const priorityOrder = [
          DoseStatus.missed,
          DoseStatus.overdue,
          DoseStatus.skipped,
          DoseStatus.dueNow,
          DoseStatus.later,
          DoseStatus.taken,
        ];

        final dayStatuses = statusMap.values.toList();
        final primaryStatus = dayStatuses.isEmpty
            ? DoseStatus.later
            : priorityOrder.firstWhere(
                (s) => dayStatuses.contains(s),
                orElse: () => DoseStatus.later,
              );

        DateTime? scheduledTime;
        if (med.times.isNotEmpty) {
          scheduledTime = TimeParser.parseTimeString(med.times.first, dayStart);
        }

        entries.add(
          DayStatusEntry(
            date: dayStart,
            status: primaryStatus,
            scheduledTime: scheduledTime,
            loggedAt: primaryStatus == DoseStatus.taken ? now : null,
          ),
        );
      }

      // Missed doses score 2 points, skipped score 1 point.
      // Skipped surfaces the medication in the strip but never above
      // a medication with genuine misses.
      final priorityScore = (missedCount * 2.0) + (skippedCount * 1.0);

      rowList.add(
        MedicationStripRow(
          medicationId: med.id,
          name: med.name,
          doseLabel: med.times.isNotEmpty
              ? '${med.times.length} doses · ${med.frequency}'
              : med.frequency,
          statuses: entries,
          priorityScore: priorityScore,
        ),
      );
    }

    rowList.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));

    return AdherenceStripData(medications: rowList, generatedAt: now);
  }

  Future<AdherenceMonthData> getMonthData(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final medications = await _medicationService.getMedications(userId);
    final dailyRates = <DailyRate>[];

    final dayOfWeekRates = <int, List<double>>{};

    for (int i = 29; i >= 1; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayStart = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      if (dayStart.isAfter(today)) continue;

      int totalResolvedDoses = 0;
      int completedDoses = 0;

      for (final med in medications) {
        final statusMap = await resolveDayStatus(
          userId: userId,
          medicationId: med.id,
          targetDate: dayStart,
          now: now,
        );

        for (final status in statusMap.values) {
          // Exclude unresolved and skipped — skipped is a deliberate choice
          // and should not penalise the adherence rate.
          if (status == DoseStatus.later ||
              status == DoseStatus.dueNow ||
              status == DoseStatus.skipped) {
            continue;
          }
          totalResolvedDoses++;
          if (status == DoseStatus.taken) completedDoses++;
        }
      }

      if (totalResolvedDoses == 0) continue;

      final rate = completedDoses / totalResolvedDoses;
      dailyRates.add(DailyRate(date: dayStart, rate: rate));

      final dayOfWeek = dayStart.weekday;
      dayOfWeekRates.putIfAbsent(dayOfWeek, () => []).add(rate);
    }

    final totalAverage = dailyRates.isEmpty
        ? 0.0
        : dailyRates.map((d) => d.rate).reduce((a, b) => a + b) /
              dailyRates.length;

    return AdherenceMonthData(
      dailyRates: dailyRates,
      averageRate: totalAverage,
      bestDayOfWeek: _convertWeekdayToString(
        _findExtremeDay(dayOfWeekRates, findBest: true),
      ),
      worstDayOfWeek: _convertWeekdayToString(
        _findExtremeDay(dayOfWeekRates, findBest: false),
      ),
      generatedAt: now,
    );
  }

  Future<AdherenceTrendData> getTrendData(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final medications = await _medicationService.getMedications(userId);
    final weeklyRates = <WeeklyRate>[];

    for (int week = 12; week >= 0; week--) {
      int totalScheduledDoses = 0;
      int completedDoses = 0;

      final weekBaseOffset = now.subtract(Duration(days: week * 7));
      final weekStart = DateTime(
        weekBaseOffset.year,
        weekBaseOffset.month,
        weekBaseOffset.day,
      );

      for (int day = 0; day < 7; day++) {
        final currentDay = weekStart.add(Duration(days: day));

        if (currentDay.isAfter(today) || currentDay.isAtSameMomentAs(today)) {
          continue;
        }

        for (final med in medications) {
          final statusMap = await resolveDayStatus(
            userId: userId,
            medicationId: med.id,
            targetDate: currentDay,
            now: now,
          );

          for (final status in statusMap.values) {
            // Exclude unresolved and skipped — skipped is a deliberate choice
            // and should not penalise the adherence rate.
            if (status == DoseStatus.later ||
                status == DoseStatus.dueNow ||
                status == DoseStatus.skipped) {
              continue;
            }
            totalScheduledDoses++;
            if (status == DoseStatus.taken) completedDoses++;
          }
        }
      }

      if (totalScheduledDoses == 0) continue;

      final rate = completedDoses / totalScheduledDoses;

      weeklyRates.add(
        WeeklyRate(weekNumber: 13 - week, weekStart: weekStart, rate: rate),
      );
    }

    final overallAverage = weeklyRates.isEmpty
        ? 0.0
        : weeklyRates.map((w) => w.rate).reduce((a, b) => a + b) /
              weeklyRates.length;

    TrendDirection direction = TrendDirection.stable;
    if (weeklyRates.length >= 4) {
      final mid = weeklyRates.length ~/ 2;
      final firstHalf = weeklyRates.take(mid).toList();
      final secondHalf = weeklyRates.skip(mid).toList();

      final firstHalfAvg =
          firstHalf.map((w) => w.rate).reduce((a, b) => a + b) /
          firstHalf.length;
      final secondHalfAvg =
          secondHalf.map((w) => w.rate).reduce((a, b) => a + b) /
          secondHalf.length;

      if (secondHalfAvg - firstHalfAvg > 0.05) {
        direction = TrendDirection.improving;
      } else if (firstHalfAvg - secondHalfAvg > 0.05) {
        direction = TrendDirection.declining;
      }
    }

    return AdherenceTrendData(
      weeklyRates: weeklyRates,
      averageRate: overallAverage,
      trendDirection: direction,
      generatedAt: now,
    );
  }

  // ─── Internal Resolution Engine ────────────────────────────────────────────

  Future<Map<String, DoseStatus>> resolveDayStatus({
    required String userId,
    required String medicationId,
    required DateTime targetDate,
    required DateTime now,
  }) async {
    try {
      final medication = await _medicationService.getMedicationById(
        userId,
        medicationId,
      );

      final dayStart = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final dayEnd = dayStart.add(const Duration(days: 1));

      final allLogs = await _doseLogService.getDoseLogsForDateRange(
        userId,
        dayStart,
        dayEnd,
      );
      final filteredLogs = allLogs
          .where((l) => l.medicationId == medicationId)
          .toList();

      return _resolveDay(medication, filteredLogs, dayStart, now);
    } catch (e) {
      return {};
    }
  }

  Map<String, DoseStatus> _resolveDay(
    Medication medication,
    List<DoseLog> logs,
    DateTime targetDayStart,
    DateTime now,
  ) {
    final result = <String, DoseStatus>{};

    for (final timeStr in medication.times) {
      final parsedScheduledTime = TimeParser.parseTimeString(
        timeStr,
        targetDayStart,
      );
      if (parsedScheduledTime == null) {
        result[timeStr] = DoseStatus.later;
        continue;
      }

      final slotId = TimeParser.buildSlotId(medication.id, parsedScheduledTime);
      final existingLog = logs.where((l) => l.slotId == slotId).firstOrNull;

      result[timeStr] = DoseStatusResolver.resolve(
        scheduledTime: parsedScheduledTime,
        now: now,
        slotId: slotId,
        existingLog: existingLog,
        createdAt: medication.createdAt,
      );
    }

    return result;
  }

  // ─── Private Algorithmic Aggregators ───────────────────────────────────────

  int _findExtremeDay(
    Map<int, List<double>> ratesByDay, {
    required bool findBest,
  }) {
    if (ratesByDay.isEmpty) return DateTime.monday;

    int extremeDay = ratesByDay.keys.first;
    double extremeAvg = findBest ? -1.0 : 2.0;

    ratesByDay.forEach((day, rates) {
      final avg = rates.reduce((a, b) => a + b) / rates.length;
      if (findBest ? avg > extremeAvg : avg < extremeAvg) {
        extremeAvg = avg;
        extremeDay = day;
      }
    });

    return extremeDay;
  }

  String _convertWeekdayToString(int weekday) {
    return const {
          DateTime.monday: 'Monday',
          DateTime.tuesday: 'Tuesday',
          DateTime.wednesday: 'Wednesday',
          DateTime.thursday: 'Thursday',
          DateTime.friday: 'Friday',
          DateTime.saturday: 'Saturday',
          DateTime.sunday: 'Sunday',
        }[weekday] ??
        'Unknown';
  }
}
