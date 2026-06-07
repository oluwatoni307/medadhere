// ===
// FILE: medication_due_card.dart
// LAYER: widget
// DOMAIN: features/home
// RESPONSIBLE FOR: Single medication due card rendered in the home screen list
// RECEIVES: medicationName (String), dosage (String), scheduledTimeDisplay (String),
//           scheduleLabel (String), categoryLabel (String? — nullable),
//           adherenceRiskLevel (AdherenceRiskLevel? — nullable),
//           onLogDose (VoidCallback)
// RETURNS: onLogDose callback
// CONNECTS TO: AppColors, AppSpacing, AppRadius, AppTypography,
//              AdherenceRiskLevel, DoseLogConfirmationAnimation,
//              MissedDoseStateChangeAnimation
// MUST NEVER: Call repositories, services, Firebase SDKs, or state providers.
//             Hardcode any hex, dp, sp, duration, or radius value.
//             Implement AnimationController.
// ===

// flutter
import 'package:flutter/material.dart';

// packages
// [none]

// internal models
// internal services
// internal core
// [explicitly left blank — never import these layers]

//
// local view layout widgets
//
import 'package:medadhere/core/theme/app_colors.dart';
import 'package:medadhere/core/theme/app_spacing.dart';
import 'package:medadhere/core/theme/app_radius.dart';
import 'package:medadhere/core/theme/app_typography.dart';
import 'package:medadhere/shared/models/adherence_risk_score.dart';

import '../../../core/theme/app_animations.dart';

class MedicationDueCard extends StatefulWidget {
  const MedicationDueCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTimeDisplay,
    required this.scheduleLabel,
    this.categoryLabel,
    this.adherenceRiskLevel,
    required this.onLogDose,
  });

  final String medicationName;
  final String dosage;
  final String scheduledTimeDisplay;
  final String scheduleLabel;
  final String? categoryLabel;
  final AdherenceRiskLevel? adherenceRiskLevel;
  final VoidCallback onLogDose;

  @override
  State<MedicationDueCard> createState() => _MedicationDueCardState();
}

class _MedicationDueCardState extends State<MedicationDueCard> {
  late bool _isMissed;

  @override
  void initState() {
    super.initState();
    _isMissed = widget.adherenceRiskLevel == AdherenceRiskLevel.highRisk;
  }

  @override
  void didUpdateWidget(MedicationDueCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adherenceRiskLevel != widget.adherenceRiskLevel) {
      setState(() {
        _isMissed = widget.adherenceRiskLevel == AdherenceRiskLevel.highRisk;
      });
    }
  }

  // --- state token resolution ---

  Color _borderColor() {
    switch (widget.adherenceRiskLevel) {
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

  double _borderWidth() {
    if (widget.adherenceRiskLevel == null) {
      return AppSpacing.medicationCardBorderWidth;
    }
    return AppSpacing.medicationCardActiveBorderWidth;
  }

  Color _circleColor() {
    switch (widget.adherenceRiskLevel) {
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

  Color _badgeBackground() {
    switch (widget.adherenceRiskLevel) {
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
    switch (widget.adherenceRiskLevel) {
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
    switch (widget.adherenceRiskLevel) {
      case AdherenceRiskLevel.onTrack:
        return 'On Track';
      case AdherenceRiskLevel.atRisk:
        return 'At Risk';
      case AdherenceRiskLevel.highRisk:
        return 'High Risk';
      case null:
        return '';
    }
  }

  // --- build ---

  @override
  Widget build(BuildContext context) {
    return MissedDoseStateChangeAnimation(
      isMissed: _isMissed,
      missedSurfaceColor: AppColors.colorStateRiskSurface,
      defaultSurfaceColor: AppColors.colorCard,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.space16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _topRow(context),
            // Change 10 — divider removed, spatial gap replaces it
            const SizedBox(height: AppSpacing.space16),
            _bottomRow(context),
          ],
        ),
      ),
    );
  }

  // --- private builders ---

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.colorCard,
      borderRadius: AppRadius.card,
      border: Border.all(color: _borderColor(), width: _borderWidth()),
    );
  }

  Widget _topRow(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: _leftCluster(typography)),
        if (widget.adherenceRiskLevel != null) ...[
          SizedBox(width: AppSpacing.space8),
          _statusBadge(typography),
        ],
      ],
    );
  }

  Widget _leftCluster(AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.adherenceRiskLevel != null) ...[
              _leadingCircle(),
              SizedBox(width: AppSpacing.space8),
            ],
            Flexible(
              child: Text(
                widget.medicationName,
                style: typography.textHeading2.copyWith(
                  color: AppColors.colorTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.space2),
        Text(
          widget.dosage,
          style: typography.textCaption.copyWith(
            color: AppColors.colorTextSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _leadingCircle() {
    return SizedBox(
      width: AppSpacing.doseOptionLeadingCircle,
      height: AppSpacing.doseOptionLeadingCircle,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _circleColor(),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _statusBadge(AppTypography typography) {
    return Container(
      padding: EdgeInsets.symmetric(
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
    );
  }

  // Change 10 — _divider() method removed entirely

  Widget _bottomRow(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _infoCluster(typography)),
        SizedBox(width: AppSpacing.space8),
        _logDoseButton(typography),
      ],
    );
  }

  Widget _infoCluster(AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Change 12 — scheduledTimeDisplay promoted: textCaption/tertiary →
        // textBodySmall/colorTextPrimary. Scheduled time is the action trigger.
        Text(
          widget.scheduledTimeDisplay,
          style: typography.textBodySmall.copyWith(
            color: AppColors.colorTextPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Change 13 — DATA CONTRACT NOTE: scheduleLabel currently includes the
        // scheduled time which duplicates scheduledTimeDisplay above. Senior Dev
        // to refactor scheduleLabel to carry frequency label only, e.g. "Once a day".
        // Until resolved, the time will appear twice in this layout.
        Text(
          widget.scheduleLabel,
          // Change 12 — scheduleLabel: textCaption/tertiary → textCaption/secondary
          style: typography.textCaption.copyWith(
            color: AppColors.colorTextSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (widget.categoryLabel != null)
          Text(
            widget.categoryLabel!,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _logDoseButton(AppTypography typography) {
    // Change 02 — radius: chip → pill
    //             height: ConstrainedBox/touchTargetMin → fixed buttonHeightCard
    //             minWidth: space48 + space32 (80dp) — pill needs width to read as capsule
    //             horizontal padding: space16 → space12
    return DoseLogConfirmationAnimation(
      onTap: widget.onLogDose,
      child: Semantics(
        label: 'Log dose for ${widget.medicationName}',
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSpacing.buttonHeightCard,
            minWidth: AppSpacing.space48 + AppSpacing.space32,
          ),
          child: SizedBox(
            height: AppSpacing.buttonHeightCard,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.space12,
                vertical: AppSpacing.space8,
              ),
              decoration: BoxDecoration(
                color: AppColors.colorPrimary,
                borderRadius: AppRadius.pill,
              ),
              child: Center(
                child: Text(
                  'Log Dose',
                  style: typography.textLabel.copyWith(
                    color: AppColors.colorOnPrimary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//
// state injection placeholders & hooks
//

/*
NOTE FOR SENIOR DEV ARCHITECT:
- StatefulWidget used for didUpdateWidget only. No AnimationController
  lives in this file. MissedDoseStateChangeAnimation owns its own
  controller internally — card simply passes _isMissed bool down.
- _isMissed is initialised in initState and updated in didUpdateWidget
  when adherenceRiskLevel changes between builds. setState triggers
  a rebuild which passes the updated bool to MissedDoseStateChangeAnimation.
- adherenceRiskLevel sourced from DueMedicationEntry per card instance.
  When null: leading circle absent, badge absent, default border treatment.
- categoryLabel: when null, category line removed from layout tree entirely.
- scheduledTimeDisplay: formatted String from DueMedicationEntry.
  Never formatted at widget layer.
- AdherenceRiskLevel imported from shared/models/adherence_risk_score.dart.
  Confirm this path matches file location on disk before merge.
- doseOptionLeadingCircle token used for leading circle diameter.
  Escalate to Visual Director if a dedicated token is required.
*/
