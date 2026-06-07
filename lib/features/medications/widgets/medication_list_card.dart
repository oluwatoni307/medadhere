import 'package:flutter/material.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/adherence_risk_score.dart';

class MedicationListCard extends StatelessWidget {
  const MedicationListCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.frequency,
    this.categoryLabel,
    required this.scheduledTimes,
    this.adherenceRiskLevel,
    required this.onViewDetail,
    required this.onLogDose,
  });

  final String medicationName;
  final String dosage;
  final String frequency;
  final String? categoryLabel;
  final List<String> scheduledTimes;
  final AdherenceRiskLevel? adherenceRiskLevel;
  final void Function() onViewDetail;
  final void Function() onLogDose;

  AppTypography _typography(BuildContext context) {
    return Theme.of(context).extension<AppTypography>()!;
  }

  Color _riskColor() {
    switch (adherenceRiskLevel) {
      case AdherenceRiskLevel.onTrack:
        return AppColors.colorStateConsistent;
      case AdherenceRiskLevel.atRisk:
        return AppColors.colorStateSlipping;
      case AdherenceRiskLevel.highRisk:
        return AppColors.colorStateRisk;
      case null:
        return AppColors.colorBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;
    final bool hasRiskLevel = adherenceRiskLevel != null;
    final Color borderColor = _riskColor();
    final double borderWidth = hasRiskLevel
        ? AppSpacing.medicationCardActiveBorderWidth
        : AppSpacing.medicationCardBorderWidth;
    final AppTypography typography = _typography(context);

    return Semantics(
      label: [
        '$medicationName, $dosage, $frequency',
        if (categoryLabel != null) categoryLabel,
        if (scheduledTimes.isNotEmpty)
          'scheduled at ${scheduledTimes.join(', ')}',
        'Tap to view details.',
      ].join(', '),
      child: GestureDetector(
        onTap: onViewDetail,
        child: _CardContainer(
          borderColor: borderColor,
          borderWidth: borderWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _TopRow(
                medicationName: medicationName,
                categoryLabel: categoryLabel,
                riskColor: borderColor,
                hasRiskLevel: hasRiskLevel,
                adherenceRiskLevel: adherenceRiskLevel,
                typography: typography,
              ),
              // Change 01 — divider removed, spatial gap replaces it
              const SizedBox(height: AppSpacing.space16),
              _BottomRow(
                dosage: dosage,
                frequency: frequency,
                scheduledTimes: scheduledTimes,
                medicationName: medicationName,
                onLogDose: onLogDose,
                disableAnimations: disableAnimations,
                typography: typography,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.borderColor,
    required this.borderWidth,
    required this.child,
  });

  final Color borderColor;
  final double borderWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: BorderRadius.circular(AppRadius.radiusMD),
        border: Border.all(color: borderColor, width: borderWidth),
      ),
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: child,
    );
  }
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.medicationName,
    required this.categoryLabel,
    required this.riskColor,
    required this.hasRiskLevel,
    required this.adherenceRiskLevel,
    required this.typography,
  });

  final String medicationName;
  final String? categoryLabel;
  final Color riskColor;
  final bool hasRiskLevel;
  final AdherenceRiskLevel? adherenceRiskLevel;
  final AppTypography typography;

  // Change 02 — badge colour resolution
  Color _badgeBackground() {
    switch (adherenceRiskLevel) {
      case AdherenceRiskLevel.onTrack:
        return AppColors.badgeTakenBackground;
      case AdherenceRiskLevel.atRisk:
        return AppColors.badgeDueBackground;
      case AdherenceRiskLevel.highRisk:
        return AppColors.badgeMissedBackground;
      case null:
        return AppColors.colorBorder;
    }
  }

  Color _badgeTextColor() {
    switch (adherenceRiskLevel) {
      case AdherenceRiskLevel.onTrack:
        return AppColors.badgeTakenText;
      case AdherenceRiskLevel.atRisk:
        return AppColors.badgeDueText;
      case AdherenceRiskLevel.highRisk:
        return AppColors.badgeMissedText;
      case null:
        return AppColors.colorBorder;
    }
  }

  String _badgeLabel() {
    switch (adherenceRiskLevel) {
      case AdherenceRiskLevel.onTrack:
        return 'Taken';
      case AdherenceRiskLevel.atRisk:
        return 'Due';
      case AdherenceRiskLevel.highRisk:
        return 'Missed';
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Change 02 — restructured as Row: left Expanded column + right badge
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (hasRiskLevel) ...[
                    _LeadingCircle(color: riskColor),
                    const SizedBox(width: AppSpacing.space8),
                  ],
                  Expanded(
                    child: Text(
                      medicationName,
                      style: typography.textHeading2.copyWith(
                        color: AppColors.colorTextPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (categoryLabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space2),
                  child: Text(
                    categoryLabel!,
                    style: typography.textCaption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.colorTextSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        // Badge is absent from the layout tree entirely when adherenceRiskLevel
        // is null — not hidden, not invisible, absent.
        if (adherenceRiskLevel != null) ...[
          const SizedBox(width: AppSpacing.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space8,
              vertical: AppSpacing.space4,
            ),
            decoration: BoxDecoration(
              color: _badgeBackground(),
              borderRadius: AppRadius.badge,
            ),
            child: Text(
              _badgeLabel().toUpperCase(),
              style: typography.textLabel.copyWith(color: _badgeTextColor()),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

class _LeadingCircle extends StatelessWidget {
  const _LeadingCircle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: AppSpacing.doseOptionLeadingCircle,
        height: AppSpacing.doseOptionLeadingCircle,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

// Change 01 — _Divider class removed entirely

class _BottomRow extends StatelessWidget {
  const _BottomRow({
    required this.dosage,
    required this.frequency,
    required this.scheduledTimes,
    required this.medicationName,
    required this.onLogDose,
    required this.disableAnimations,
    required this.typography,
  });

  final String dosage;
  final String frequency;
  final List<String> scheduledTimes;
  final String medicationName;
  final void Function() onLogDose;
  final bool disableAnimations;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: _InfoCluster(
            dosage: dosage,
            frequency: frequency,
            scheduledTimes: scheduledTimes,
            typography: typography,
          ),
        ),
        _LogButtonZone(
          medicationName: medicationName,
          onLogDose: onLogDose,
          disableAnimations: disableAnimations,
          typography: typography,
        ),
      ],
    );
  }
}

class _InfoCluster extends StatelessWidget {
  const _InfoCluster({
    required this.dosage,
    required this.frequency,
    required this.scheduledTimes,
    required this.typography,
  });

  final String dosage;
  final String frequency;
  final List<String> scheduledTimes;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    // Change 04 — merge dosage + frequency when combined string ≤ 32 chars
    final String combined = '$dosage · $frequency';
    final bool mergeLines = combined.length <= 32;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mergeLines)
          Text(
            combined,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else ...[
          Text(
            dosage,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            frequency,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        // Change 04 — scheduled times promoted: textCaption/tertiary →
        // textBodySmall/colorTextPrimary. Time is the action trigger.
        if (scheduledTimes.isNotEmpty)
          Text(
            scheduledTimes.join('  ·  '),
            style: typography.textBodySmall.copyWith(
              color: AppColors.colorTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _LogButtonZone extends StatelessWidget {
  const _LogButtonZone({
    required this.medicationName,
    required this.onLogDose,
    required this.disableAnimations,
    required this.typography,
  });

  final String medicationName;
  final void Function() onLogDose;
  final bool disableAnimations;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.space8),
      child: Semantics(
        label: 'Log a dose for $medicationName',
        child: DoseLogConfirmationAnimation(
          onTap: onLogDose,
          child: _LogButton(typography: typography),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({required this.typography});

  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    // Change 03 — radius: radiusSM → pill
    //             height: ConstrainedBox/touchTargetMin → fixed buttonHeightCard
    //             horizontal padding: space16 → space12
    //             minWidth: space48 + space32 (80dp) — pill needs width to read as capsule
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: AppSpacing.buttonHeightCard,
        minWidth: AppSpacing.space48 + AppSpacing.space32,
      ),
      child: SizedBox(
        height: AppSpacing.buttonHeightCard,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.colorPrimary,
            borderRadius: AppRadius.pill,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space8,
          ),
          child: Center(
            child: Text(
              'Log',
              style: typography.textBody.copyWith(
                color: AppColors.colorOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
