// ============================================
// FILE: _adherence_strip_widget.dart
// LAYER: widget
// DOMAIN: adherence
// RESPONSIBLE FOR: Renders the 7-day per-medication dot strip.
//                  Shows top 3 medications by default, expandable to all.
//                  Each row: drug name label + 7 status dots.
//                  Renders the "Your Consistency" section when riskScores
//                  is provided — evidence-first per-medication rows with a
//                  scoped consistency badge (On track / Slipping / At
//                  risk / Still early), not a bare risk label.
// RECEIVES: data: AdherenceStripData,
//           riskScores: List<AdherenceMedicationRisk>? — null hides the
//           consistency section
// RETURNS: Column of medication rows inside a card surface,
//          optional consistency card below
// CONNECTS TO: adherence_visualization_screen.dart,
//              adherence_visualization_models.dart,
//              adherence_dashboard_state.dart
// MUST NEVER: watch any provider, declare providers, call routing,
//             hardcode any value, contain business logic
//
// KNOWN RULE EXCEPTION — flagged, not silent:
//   _isColdStart() below computes "insufficient history" from raw dose
//   statuses — that's a business-logic judgment, not a display decision,
//   and it violates this file's own MUST NEVER clause. Done deliberately,
//   by request, as a temporary measure: AdherenceRiskLevel (see
//   adherence_risk_score.dart) has no coldStart value, so there's no
//   upstream flag to branch on yet. Correct long-term fix is adding
//   isColdStart (or equivalent) to AdherenceMedicationRisk upstream and
//   deleting _isColdStart() entirely — this comment is the marker for
//   that cleanup; search "KNOWN RULE EXCEPTION" to find it later.
// ============================================

// flutter
import 'package:flutter/material.dart';
// models
import '../../../shared/models/adherence_visualization_models.dart';
import '../../../shared/models/adherence_dashboard_state.dart';
import '../../../shared/models/adherence_risk_score.dart';
import '../../../shared/models/dose_log.dart' show DoseStatus;
// theme
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

// ─── constants ────────────────────────────────────────────────────────────────

List<String> _buildDayLabels() {
  final now = DateTime.now();
  final labels = <String>[];
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  for (var i = 4; i >= 1; i--) {
    final day = now.subtract(Duration(days: i));
    labels.add(dayNames[day.weekday - 1]);
  }
  labels.add('Today');
  return labels;
}

// ─── consistency badge model ───────────────────────────────────────────────────
//
// Four states, matching the finalized design: On track / Slipping /
// At risk / Still early (Cold Start). Deliberately not a 1:1 switch on
// AdherenceRiskLevel — that enum only has three values, and the badge
// text is intentionally NOT the same as the raw enum name (see the
// atRisk/highRisk relabeling below — this was already mismatched with
// its own color before this change).

enum _ConsistencyState { consistent, slipping, atRisk, stillEarly }

class _ConsistencyBadgeConfig {
  const _ConsistencyBadgeConfig({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

_ConsistencyBadgeConfig _consistencyBadgeConfig(_ConsistencyState state) =>
    switch (state) {
      _ConsistencyState.consistent => _ConsistencyBadgeConfig(
        label: 'On track',
        background: AppColors.colorStateConsistentSurface,
        foreground: AppColors.colorStateConsistent,
      ),
      // NOTE: this bucket was previously labeled "At Risk" while already
      // using the Slipping color tokens. Label corrected to match the
      // color it's always rendered in — no visual change, text now tells
      // the truth.
      _ConsistencyState.slipping => _ConsistencyBadgeConfig(
        label: 'Slipping',
        background: AppColors.colorStateSlippingSurface,
        foreground: AppColors.colorStateSlipping,
      ),
      // NOTE: this bucket was previously labeled "High Risk" (the enum
      // name is highRisk) — relabeled to "At risk" to match the
      // finalized copy; this is the only genuinely "at risk" state.
      _ConsistencyState.atRisk => _ConsistencyBadgeConfig(
        label: 'At risk',
        background: AppColors.colorStateRiskSurface,
        foreground: AppColors.colorStateRisk,
      ),
      // Cold Start is a real, distinct risk state (early nonadherence
      // risk), not a muted/absent one — gets its own token, not a grey
      // "unknown" treatment. Deliberately drops the word "risk" — see
      // finalized copy decision.
      _ConsistencyState.stillEarly => _ConsistencyBadgeConfig(
        label: 'Still early',
        background: AppColors.colorStateMorningSurface,
        foreground: AppColors.colorStateMorning,
      ),
    };

// ─── widget ───────────────────────────────────────────────────────────────────

class AdherenceStripWidget extends StatefulWidget {
  const AdherenceStripWidget({super.key, required this.data, this.riskScores});

  final AdherenceStripData data;

  /// Per-medication ML risk levels from adherenceProvider.
  /// When null the consistency section is not rendered.
  /// When present, matched to strip rows by medicationId.
  final List<AdherenceMedicationRisk>? riskScores;

  @override
  State<AdherenceStripWidget> createState() => _AdherenceStripWidgetState();
}

class _AdherenceStripWidgetState extends State<AdherenceStripWidget> {
  bool _expanded = false;

  // ─── risk lookup ──────────────────────────────────────────────────────────

  AdherenceRiskLevel? _riskFor(String medicationId) {
    if (widget.riskScores == null) return null;
    try {
      return widget.riskScores!
          .firstWhere((r) => r.medicationId == medicationId)
          .riskLevel;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleMeds = _expanded
        ? widget.data.medications
        : widget.data.topMedications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildCard(context, visibleMeds),
        if (widget.data.hasMore) ...[
          const SizedBox(height: AppSpacing.space8),
          _buildExpandButton(context),
        ],
        if (widget.data.medications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space20),
          _buildObservations(context),
        ],
        if (widget.riskScores != null && widget.riskScores!.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space20),
          _buildConsistencySection(context),
        ],
      ],
    );
  }

  // ─── card ─────────────────────────────────────────────────────────────────

  Widget _buildCard(
    BuildContext context,
    List<MedicationStripRow> medications,
  ) {
    return Container(
      width: double.infinity,
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
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDayHeaders(context),
          const SizedBox(height: AppSpacing.space12),
          ...medications.asMap().entries.map((entry) {
            final isLast = entry.key == medications.length - 1;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMedicationRow(context, entry.value),
                if (!isLast) const SizedBox(height: AppSpacing.space12),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.space12),
          _buildLegend(context),
        ],
      ),
    );
  }

  // ─── day headers ──────────────────────────────────────────────────────────

  Widget _buildDayHeaders(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Row(
      children: [
        const SizedBox(width: 64),
        ..._buildDayLabels().map(
          (label) => Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: typography.textCaption.copyWith(
                color: AppColors.colorTextTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── medication row ───────────────────────────────────────────────────────

  Widget _buildMedicationRow(BuildContext context, MedicationStripRow row) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: Text(
            row.name,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextSecondary,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ...row.statuses.map(
          (entry) => Expanded(child: _buildDot(context, entry)),
        ),
      ],
    );
  }

  // ─── dot ──────────────────────────────────────────────────────────────────

  Widget _buildDot(BuildContext context, DayStatusEntry entry) {
    final config = _dotConfig(entry.status);
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Center(
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: config.background,
          borderRadius: AppRadius.chip,
          border: Border.all(color: config.border, width: 0.5),
        ),
        child: Center(
          child: Text(
            config.symbol,
            style: typography.textCaption.copyWith(
              color: config.foreground,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // ─── legend ───────────────────────────────────────────────────────────────

  Widget _buildLegend(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final items = [
      (DoseStatus.taken, 'Taken'),
      (DoseStatus.missed, 'Missed'),
      (DoseStatus.skipped, 'Skipped'),
      (DoseStatus.dueNow, 'Due'),
      (DoseStatus.later, 'Later'),
    ];

    return Wrap(
      spacing: AppSpacing.space12,
      runSpacing: AppSpacing.space8,
      children: items.map((item) {
        final config = _dotConfig(item.$1);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: config.background,
                borderRadius: const BorderRadius.all(Radius.circular(3)),
                border: Border.all(color: config.border, width: 0.5),
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            Text(
              item.$2,
              style: typography.textCaption.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── observations ─────────────────────────────────────────────────────────
  // Unchanged — this block already does evidence-first copy well and isn't
  // part of what we're redesigning.

  Widget _buildObservations(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final meds = widget.data.medications;

    final worst = meds.first;
    final worstMisses = worst.statuses
        .where((s) => s.status == DoseStatus.missed)
        .length;
    final worstSkips = worst.statuses
        .where((s) => s.status == DoseStatus.skipped)
        .length;

    final bestOrNull = meds.length > 1
        ? meds.lastWhereOrNull(
            (m) =>
                m.medicationId != worst.medicationId &&
                m.statuses.every(
                  (s) =>
                      s.status != DoseStatus.missed &&
                      s.status != DoseStatus.skipped,
                ),
          )
        : null;

    final showWorst = worstMisses > 0 || worstSkips > 0;
    final showBest = bestOrNull != null;

    if (!showWorst && !showBest) return const SizedBox.shrink();

    final dayWindow = worst.statuses.length;

    String worstText;
    if (worstMisses > 0 && worstSkips > 0) {
      worstText =
          '${worst.name} — missed $worstMisses and skipped $worstSkips of the last $dayWindow days.';
    } else if (worstMisses > 0) {
      worstText =
          '${worst.name} — missed $worstMisses of the last $dayWindow days.';
    } else {
      worstText =
          '${worst.name} — skipped $worstSkips of the last $dayWindow days.';
    }

    final worstColor = worstMisses >= 3
        ? AppColors.colorStateRisk
        : worstMisses > 0
        ? AppColors.colorStateSlipping
        : AppColors.colorStateMorning;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBest)
            _buildObservationRow(
              context,
              typography,
              color: AppColors.colorStateConsistent,
              text:
                  '${bestOrNull.name} — no misses in the last $dayWindow days.',
              isLast: !showWorst,
            ),
          if (showWorst)
            _buildObservationRow(
              context,
              typography,
              color: worstColor,
              text: worstText,
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildObservationRow(
    BuildContext context,
    AppTypography typography, {
    required Color color,
    required String text,
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.colorBorder,
                  width: AppSpacing.medicationCardBorderWidth,
                ),
              ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.insightCardBorderWidth,
            height: 20,
            color: color,
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Text(
              text,
              style: typography.textBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── consistency section (formerly "ML risk rating") ─────────────────────

  Widget _buildConsistencySection(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final allMeds = widget.data.medications;

    final rows = widget.riskScores!
        .map((risk) {
          try {
            final stripRow = allMeds.firstWhere(
              (m) => m.medicationId == risk.medicationId,
            );
            return (stripRow: stripRow, riskLevel: risk.riskLevel);
          } catch (_) {
            return null;
          }
        })
        .where((r) => r != null)
        .map((r) => r!)
        .toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space8),
          child: Text(
            'YOUR CONSISTENCY',
            style: typography.textLabel.copyWith(
              color: AppColors.colorTextTertiary,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.colorCard,
            borderRadius: AppRadius.card,
            border: Border.all(
              color: AppColors.colorBorder,
              width: AppSpacing.medicationCardBorderWidth,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows.asMap().entries.map((entry) {
              final isLast = entry.key == rows.length - 1;
              final row = entry.value;
              return _buildConsistencyRow(
                context,
                typography,
                stripRow: row.stripRow,
                riskLevel: row.riskLevel,
                isLast: isLast,
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.space8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.colorDisabled,
                borderRadius: AppRadius.pill,
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            Text(
              'Estimated from your recent logs. Improves as more doses are recorded.',
              style: typography.textCaption.copyWith(
                color: AppColors.colorTextTertiary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConsistencyRow(
    BuildContext context,
    AppTypography typography, {
    required MedicationStripRow stripRow,
    required AdherenceRiskLevel riskLevel,
    required bool isLast,
  }) {
    final coldStart = _isColdStart(stripRow);
    final state = coldStart
        ? _ConsistencyState.stillEarly
        : switch (riskLevel) {
            AdherenceRiskLevel.onTrack => _ConsistencyState.consistent,
            AdherenceRiskLevel.atRisk => _ConsistencyState.slipping,
            AdherenceRiskLevel.highRisk => _ConsistencyState.atRisk,
          };
    final config = _consistencyBadgeConfig(state);
    final evidence = _evidenceText(stripRow, coldStart);

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: AppColors.colorBorder,
                  width: AppSpacing.medicationCardBorderWidth,
                ),
              ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stripRow.name,
                  style: typography.textBody.copyWith(
                    color: AppColors.colorTextPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  evidence,
                  style: typography.textCaption.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space10,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: config.background,
              borderRadius: AppRadius.pill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: config.foreground,
                    borderRadius: AppRadius.pill,
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Text(
                  config.label,
                  style: typography.textLabel.copyWith(
                    color: config.foreground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── temporary widget-local heuristics ─────────────────────────────────
  // See "KNOWN RULE EXCEPTION" in the file header. Both functions below
  // are business logic living where the file's own rules say it shouldn't.
  // Kept intentionally simple and isolated so they're easy to delete once
  // AdherenceMedicationRisk carries this upstream instead.

  /// True when a medication has no resolved dose history at all in the
  /// visible window (every status is `later` or `dueNow` — nothing has
  /// actually been taken, missed, or skipped yet). A coarse heuristic,
  /// not a real data-sufficiency calculation — flagged as temporary.
  bool _isColdStart(MedicationStripRow row) {
    return row.statuses.every(
      (s) => s.status == DoseStatus.later || s.status == DoseStatus.dueNow,
    );
  }

  /// Builds the per-row evidence sentence. Mirrors the logic already in
  /// _buildObservations but scoped to a single row instead of best/worst
  /// across all medications, plus a same-day "taken today" lead-in when
  /// applicable so a resolved outcome is never buried under stale framing.
  String _evidenceText(MedicationStripRow row, bool coldStart) {
    if (coldStart) {
      return 'New — not enough history to judge a pattern yet.';
    }

    final dayWindow = row.statuses.length;
    final misses = row.statuses
        .where((s) => s.status == DoseStatus.missed)
        .length;
    final skips = row.statuses
        .where((s) => s.status == DoseStatus.skipped)
        .length;
    final takenToday =
        row.statuses.isNotEmpty && row.statuses.last.status == DoseStatus.taken;

    if (misses == 0 && skips == 0) {
      return takenToday
          ? 'Taken today. No misses in the last $dayWindow days.'
          : 'No misses in the last $dayWindow days.';
    }

    final String pattern;
    if (misses > 0 && skips > 0) {
      pattern =
          'Missed $misses and skipped $skips of the last $dayWindow days.';
    } else if (misses > 0) {
      pattern = 'Missed $misses of the last $dayWindow days.';
    } else {
      pattern = 'Skipped $skips of the last $dayWindow days.';
    }

    return takenToday ? 'Taken today. $pattern' : pattern;
  }

  // ─── expand button ────────────────────────────────────────────────────────

  Widget _buildExpandButton(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final remaining = widget.data.medications.length - 3;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.colorCard,
          borderRadius: AppRadius.card,
          border: Border.all(
            color: AppColors.colorBorder,
            width: AppSpacing.medicationCardBorderWidth,
          ),
        ),
        child: Text(
          _expanded
              ? 'Show less'
              : '+ $remaining more medication${remaining > 1 ? 's' : ''}',
          textAlign: TextAlign.center,
          style: typography.textBodySmall.copyWith(
            color: AppColors.colorStateConsistent,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── dot config ───────────────────────────────────────────────────────────────

class _DotConfig {
  const _DotConfig({
    required this.background,
    required this.border,
    required this.foreground,
    required this.symbol,
  });

  final Color background;
  final Color border;
  final Color foreground;
  final String symbol;
}

_DotConfig _dotConfig(DoseStatus status) => switch (status) {
  DoseStatus.taken => _DotConfig(
    background: AppColors.badgeTakenBackground,
    border: AppColors.badgeTakenText,
    foreground: AppColors.badgeTakenText,
    symbol: '✓',
  ),
  DoseStatus.missed => _DotConfig(
    background: AppColors.badgeMissedBackground,
    border: AppColors.badgeMissedText,
    foreground: AppColors.badgeMissedText,
    symbol: '✗',
  ),
  DoseStatus.skipped => _DotConfig(
    background: AppColors.badgeSkippedBackground,
    border: AppColors.badgeSkippedText,
    foreground: AppColors.badgeSkippedText,
    symbol: '○',
  ),
  DoseStatus.dueNow => _DotConfig(
    background: AppColors.badgeDueBackground,
    border: AppColors.badgeDueText,
    foreground: AppColors.badgeDueText,
    symbol: '→',
  ),
  DoseStatus.later => _DotConfig(
    background: AppColors.badgeLaterBackground,
    border: AppColors.badgeLaterText,
    foreground: AppColors.badgeLaterText,
    symbol: '–',
  ),
  DoseStatus.overdue => _DotConfig(
    background: const Color(
      0xFFE8DDE3,
    ), // plum surface wash — deliberately distinct hue, not in AppColors
    border: const Color(
      0xFF6B3D52,
    ), // deep plum — hardcoded, visually separate from all arc state tokens
    foreground: const Color(0xFF6B3D52),
    symbol: '!',
  ),
};

// ─── list extension ───────────────────────────────────────────────────────────

extension _ListExtension<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    T? result;
    for (final element in this) {
      if (test(element)) result = element;
    }
    return result;
  }
}
