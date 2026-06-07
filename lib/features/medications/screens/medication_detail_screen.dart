// ============================================
// FILE: medication_detail_screen.dart
// LAYER: screen
// DOMAIN: medications
// RESPONSIBLE FOR: Displaying full medication detail — identity, stat cards,
//                  ML pattern insight, and scrollable dose log.
// RECEIVES: medicationId via router
// RETURNS: Widget
// CONNECTS TO: medication_detail_provider.dart, delete_medication_sheet.dart,
//              app_colors.dart, app_spacing.dart, app_typography.dart,
//              app_radius.dart, app_animations.dart
// MUST NEVER: Call services or repositories directly
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/adherence_risk_score.dart';
import '../../../shared/models/dose_log.dart';
import '../../../shared/models/medication.dart';
import '../state/medication_detail_provider.dart';
import '../widgets/delete_medication_sheet.dart';

class MedicationDetailScreen extends ConsumerStatefulWidget {
  const MedicationDetailScreen({super.key, required this.medicationId});

  final String medicationId;

  @override
  ConsumerState<MedicationDetailScreen> createState() =>
      _MedicationDetailScreenState();
}

class _MedicationDetailScreenState
    extends ConsumerState<MedicationDetailScreen> {
  // — lifecycle —

  @override
  void initState() {
    super.initState();
    Future(() {
      ref.read(medicationDetailProvider(widget.medicationId).notifier).load();
    });
  }

  // — actions —

  void _onBack() => context.pop();

  void _onEdit(String id, Medication med) => context.pushNamed(
    'editMedication',
    pathParameters: {'id': id},
    extra: med,
  );

  void _onDeleteConfirm() async {
    Navigator.of(context).pop();
    await ref
        .read(medicationDetailProvider(widget.medicationId).notifier)
        .deleteMedication();
    if (mounted) context.pop();
  }

  void _onCancel() => Navigator.of(context).pop();

  void _showDeleteSheet(String medicationName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: AppColors.colorCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radiusXL),
        ),
      ),
      builder: (_) => DeleteMedicationSheet(
        medicationName: medicationName,
        onCancel: _onCancel,
        onDeleteConfirm: _onDeleteConfirm,
      ),
    );
  }

  // — build —

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(medicationDetailProvider(widget.medicationId));

    // STATE 02 — LOADING
    if (state.isLoading || (!state.hasMedication && state.error == null)) {
      return _buildLoadingState(context);
    }

    // STATE 03 — ERROR
    if (state.error != null && !state.hasMedication) {
      return _buildErrorState(context);
    }

    // STATE 01 — POPULATED (with or without insight)
    return _buildPopulatedState(context, state);
  }

  // — state builders —

  Widget _buildLoadingState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNavHeader(context, showEdit: false),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.viewportMarginHorizontal,
              ),
              child: Semantics(
                label: 'Loading medication details. Please wait.',
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: AppSpacing.space24),
                      // — identity skeleton —
                      LoadingPulseAnimation(
                        isLoading: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 180,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.colorSkeleton,
                                borderRadius: AppRadius.badge,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space8),
                            Container(
                              width: 140,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.colorSkeleton,
                                borderRadius: AppRadius.badge,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space24),
                          ],
                        ),
                      ),
                      // — stat cards skeleton —
                      LoadingPulseAnimation(
                        isLoading: true,
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.colorSkeleton,
                                  borderRadius: AppRadius.card,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.space12),
                            Expanded(
                              child: Container(
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.colorSkeleton,
                                  borderRadius: AppRadius.card,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space16),
                      // — log skeleton —
                      LoadingPulseAnimation(
                        isLoading: true,
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            color: AppColors.colorSkeleton,
                            borderRadius: AppRadius.card,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavHeader(context, showEdit: false),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.viewportMarginHorizontal,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.colorTextTertiary,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      'Couldn\'t load this medication.',
                      style: typography.textHeading1.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Text(
                      'This medication could not be found. It may have been removed already.',
                      style: typography.textBody.copyWith(
                        color: AppColors.colorTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    SizedBox(
                      width: double.infinity,
                      height: AppSpacing.buttonHeightPrimary,
                      child: DoseLogConfirmationAnimation(
                        onTap: _onBack,
                        child: ElevatedButton(
                          onPressed: _onBack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.colorPrimary,
                            foregroundColor: AppColors.colorOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.button,
                            ),
                          ),
                          child: Text(
                            'Back to medications',
                            style: typography.textLabel.copyWith(
                              color: AppColors.colorOnPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopulatedState(
    BuildContext context,
    MedicationDetailState state,
  ) {
    final med = state.medication!;
    final groupedLogs = _groupLogsByDate(state.logs);

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // — nav header —
            SliverToBoxAdapter(
              child: _buildNavHeader(context, showEdit: true, med: med),
            ),

            // — identity —
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.viewportMarginHorizontal,
                ),
                child: _buildIdentity(context, med),
              ),
            ),

            // — stat cards —
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.viewportMarginHorizontal,
                ),
                child: _buildStatCards(context, state),
              ),
            ),

            // — pattern insight (only when ML available) —
            if (state.hasInsight)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.viewportMarginHorizontal,
                  ),
                  child: _buildPatternCard(context, state.riskScore!),
                ),
              ),

            // — log section label —
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.viewportMarginHorizontal,
                  AppSpacing.space24,
                  AppSpacing.viewportMarginHorizontal,
                  AppSpacing.space12,
                ),
                child: _buildSectionLabel(context, 'Dose log'),
              ),
            ),

            // — log groups —
            if (groupedLogs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.viewportMarginHorizontal,
                  ),
                  child: _buildEmptyLog(context),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = groupedLogs[index];
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.viewportMarginHorizontal,
                      0,
                      AppSpacing.viewportMarginHorizontal,
                      AppSpacing.space12,
                    ),
                    child: _buildLogGroup(context, group),
                  );
                }, childCount: groupedLogs.length),
              ),

            // — delete + bottom padding —
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.viewportMarginHorizontal,
                ),
                child: _buildDeleteRow(context, med.name),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // — block builders —

  Widget _buildIdentity(BuildContext context, Medication med) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space8,
        bottom: AppSpacing.space20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              med.name,
              style: typography.textHeading1.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            '${med.dosage} · ${med.frequency}',
            style: typography.textBody.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(BuildContext context, MedicationDetailState state) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final arcColor = _resolveArcColor(state.riskScore);
    final takenCount = state.logs
        .where((l) => l.status == DoseStatus.taken)
        .length;
    final totalCount = state.logs.length;
    final adherenceRate = totalCount > 0 ? (takenCount / totalCount) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space16),
      child: Row(
        children: [
          // — this month —
          Expanded(
            child: _StatCard(
              label: 'This month',
              value: adherenceRate != null
                  ? '${(adherenceRate * 100).round()}'
                  : '—',
              unit: adherenceRate != null ? '%' : '',
              valueColor: arcColor,
              barFill: adherenceRate,
              barColor: arcColor,
              typography: typography,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          // — streak —
          Expanded(
            child: _StatCard(
              label: 'Streak',
              value:
                  '${state.riskScore?.isColdStart == true ? 0 : _computeStreak(state.logs)}',
              unit: 'days',
              valueColor: AppColors.colorAccent,
              barFill: null,
              barColor: AppColors.colorAccent,
              typography: typography,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternCard(BuildContext context, AdherenceRiskScore riskScore) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final arcColor = _resolveArcColor(riskScore);
    final arcSurface = _resolveArcSurface(riskScore);
    final insight = _resolveInsightCopy(riskScore);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space4),
      child: Container(
        decoration: BoxDecoration(
          color: arcSurface,
          borderRadius: AppRadius.card,
          border: Border(
            left: BorderSide(
              color: arcColor,
              width: AppSpacing.insightCardBorderWidth,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.insightCardPaddingHorizontal -
              AppSpacing.insightCardBorderWidth,
          AppSpacing.insightCardPaddingVertical,
          AppSpacing.insightCardPaddingHorizontal,
          AppSpacing.insightCardPaddingVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PATTERN',
              style: typography.textInsightCardEyebrow.copyWith(
                color: arcColor,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              insight.headline,
              style: typography.textInsightCardBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(
              insight.body,
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Text(
      label.toUpperCase(),
      style: typography.textInsightCardEyebrow.copyWith(
        color: AppColors.colorTextTertiary,
      ),
    );
  }

  Widget _buildLogGroup(BuildContext context, _LogGroup group) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // — date header —
          Container(
            width: double.infinity,
            color: AppColors.colorSurfaceMuted,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space8,
            ),
            child: Text(
              group.label,
              style: typography.textCaption.copyWith(
                color: AppColors.colorTextTertiary,
              ),
            ),
          ),
          // — log rows —
          ...group.logs.asMap().entries.map((entry) {
            final isLast = entry.key == group.logs.length - 1;
            return _buildLogRow(context, entry.value, isLast: isLast);
          }),
        ],
      ),
    );
  }

  Widget _buildLogRow(
    BuildContext context,
    DoseLog log, {
    required bool isLast,
  }) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final badge = _resolveBadge(log.status);
    final time = _formatTime(log.scheduledTime);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          child: Row(
            children: [
              // — status dot —
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: badge.dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              // — time + dose —
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      time,
                      style: typography.textBodySmall.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                    ),
                    if (log.notes != null && log.notes!.isNotEmpty)
                      Text(
                        log.notes!,
                        style: typography.textCaption.copyWith(
                          color: AppColors.colorTextTertiary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // — badge —
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: AppSpacing.space4,
                ),
                decoration: BoxDecoration(
                  color: badge.background,
                  borderRadius: AppRadius.badge,
                ),
                child: Text(
                  badge.label.toUpperCase(),
                  style: typography.textLabel.copyWith(color: badge.textColor),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 0.5,
            color: AppColors.colorBorder,
            indent: AppSpacing.space16,
            endIndent: AppSpacing.space16,
          ),
      ],
    );
  }

  Widget _buildEmptyLog(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space24),
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      child: Text(
        'No doses logged yet.',
        style: typography.textBody.copyWith(
          color: AppColors.colorTextSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDeleteRow(BuildContext context, String medicationName) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space32,
        bottom: AppSpacing.space40,
      ),
      child: Semantics(
        label: 'Delete medication',
        button: true,
        child: GestureDetector(
          onTap: () => _showDeleteSheet(medicationName),
          child: SizedBox(
            height: AppSpacing.touchTargetMin,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Delete medication',
                style: typography.textBodySmall.copyWith(
                  color: AppColors.colorStateRisk,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // — shared nav header —

  Widget _buildNavHeader(
    BuildContext context, {
    required bool showEdit,
    Medication? med,
  }) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return SizedBox(
      height: AppSpacing.navHeaderHeight,
      width: double.infinity,
      child: Row(
        children: [
          Semantics(
            label: 'Go back to medication list',
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              color: AppColors.colorTextPrimary,
              iconSize: AppSpacing.iconSizeStandard,
              onPressed: _onBack,
            ),
          ),
          const Spacer(),
          if (showEdit && med != null)
            Semantics(
              label: 'Edit medication details',
              child: GestureDetector(
                onTap: () => _onEdit(med.id, med),
                child: SizedBox(
                  height: AppSpacing.navTouchTarget,
                  width: AppSpacing.navTouchTarget,
                  child: Center(
                    child: Text(
                      'Edit',
                      style: typography.textLabel.copyWith(
                        color: AppColors.colorPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // — helpers —

  List<_LogGroup> _groupLogsByDate(List<DoseLog> logs) {
    if (logs.isEmpty) return [];
    final sorted = [...logs]
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    final groups = <_LogGroup>[];
    final seen = <String>[];
    for (final log in sorted) {
      final key = _dateKey(log.scheduledTime);
      if (!seen.contains(key)) {
        seen.add(key);
        groups.add(
          _LogGroup(
            label: _formatDateHeader(log.scheduledTime),
            logs: sorted
                .where((l) => _dateKey(l.scheduledTime) == key)
                .toList(),
          ),
        );
      }
    }
    return groups;
  }

  String _dateKey(DateTime dt) => '${dt.year}-${dt.month}-${dt.day}';

  String _formatDateHeader(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  int _computeStreak(List<DoseLog> logs) {
    if (logs.isEmpty) return 0;
    final sorted = [...logs]
      ..sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));
    int streak = 0;
    DateTime? lastDate;
    for (final log in sorted) {
      if (log.status != DoseStatus.taken) continue;
      final date = DateTime(
        log.scheduledTime.year,
        log.scheduledTime.month,
        log.scheduledTime.day,
      );
      if (lastDate == null) {
        lastDate = date;
        streak = 1;
      } else if (lastDate.difference(date).inDays == 1) {
        lastDate = date;
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // — arc colour resolvers —

  Color _resolveArcColor(AdherenceRiskScore? score) {
    if (score == null) return AppColors.colorStateConsistent;
    if (score.isColdStart) return AppColors.colorStateMorning;
    switch (score.riskLevel) {
      case AdherenceRiskLevel.onTrack:
        return AppColors.colorStateConsistent;
      case AdherenceRiskLevel.atRisk:
        return AppColors.colorStateSlipping;
      case AdherenceRiskLevel.highRisk:
        return AppColors.colorStateRisk;
    }
  }

  Color _resolveArcSurface(AdherenceRiskScore score) {
    if (score.isColdStart) return AppColors.colorStateMorningSurface;
    switch (score.riskLevel) {
      case AdherenceRiskLevel.onTrack:
        return AppColors.colorStateConsistentSurface;
      case AdherenceRiskLevel.atRisk:
        return AppColors.colorStateSlippingSurface;
      case AdherenceRiskLevel.highRisk:
        return AppColors.colorStateRiskSurface;
    }
  }

  _InsightCopy _resolveInsightCopy(AdherenceRiskScore score) {
    if (score.isColdStart) {
      return _InsightCopy(
        headline: 'Just getting started — no pattern yet.',
        body: 'Keep logging and a picture will form over the next few days.',
      );
    }
    switch (score.riskLevel) {
      case AdherenceRiskLevel.onTrack:
        return _InsightCopy(
          headline: 'Strong overall — you rarely miss this one.',
          body: 'Morning doses are solid. Keep it up.',
        );
      case AdherenceRiskLevel.atRisk:
        return _InsightCopy(
          headline: 'Slipping a little — some doses need attention.',
          body: 'A few recent misses. Worth checking your schedule.',
        );
      case AdherenceRiskLevel.highRisk:
        return _InsightCopy(
          headline: 'Needs a reset — most doses going unlogged.',
          body: 'Less than half taken recently. Worth checking your schedule.',
        );
    }
  }

  _BadgeStyle _resolveBadge(DoseStatus status) {
    switch (status) {
      case DoseStatus.taken:
        return _BadgeStyle(
          label: 'Taken',
          background: AppColors.badgeTakenBackground,
          textColor: AppColors.badgeTakenText,
          dotColor: AppColors.colorStateConsistent,
        );
      case DoseStatus.missed:
        return _BadgeStyle(
          label: 'Missed',
          background: AppColors.badgeMissedBackground,
          textColor: AppColors.badgeMissedText,
          dotColor: AppColors.colorStateRisk,
        );
      case DoseStatus.skipped:
        return _BadgeStyle(
          label: 'Skipped',
          background: AppColors.badgeLaterBackground,
          textColor: AppColors.badgeLaterText,
          dotColor: AppColors.colorTextTertiary,
        );
      case DoseStatus.dueNow:
        return _BadgeStyle(
          label: 'Due now',
          background: AppColors.badgeDueBackground,
          textColor: AppColors.badgeDueText,
          dotColor: AppColors.colorStateDusk,
        );
      case DoseStatus.overdue:
        return _BadgeStyle(
          label: 'Overdue',
          background: AppColors.badgeMissedBackground,
          textColor: AppColors.badgeMissedText,
          dotColor: AppColors.colorStateRisk,
        );
      case DoseStatus.later:
        return _BadgeStyle(
          label: 'Later',
          background: AppColors.badgeLaterBackground,
          textColor: AppColors.badgeLaterText,
          dotColor: AppColors.colorTextTertiary,
        );
    }
  }
}

// — private data classes —

class _LogGroup {
  const _LogGroup({required this.label, required this.logs});
  final String label;
  final List<DoseLog> logs;
}

class _InsightCopy {
  const _InsightCopy({required this.headline, required this.body});
  final String headline;
  final String body;
}

class _BadgeStyle {
  const _BadgeStyle({
    required this.label,
    required this.background,
    required this.textColor,
    required this.dotColor,
  });
  final String label;
  final Color background;
  final Color textColor;
  final Color dotColor;
}

// — stat card widget —

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    required this.barFill,
    required this.barColor,
    required this.typography,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final double? barFill;
  final Color barColor;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: typography.textInsightCardEyebrow.copyWith(
              color: AppColors.colorTextTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: typography.textDisplay.copyWith(
                    fontSize: 28,
                    color: valueColor,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: ' $unit',
                    style: typography.textBodySmall.copyWith(
                      color: AppColors.colorTextSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          ClipRRect(
            borderRadius: AppRadius.pill,
            child: SizedBox(
              height: AppSpacing.progressBarHeight,
              child: LinearProgressIndicator(
                value: barFill,
                backgroundColor: AppColors.colorSurfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
