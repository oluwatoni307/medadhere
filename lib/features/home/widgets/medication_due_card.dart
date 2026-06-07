// ===
// FILE: medication_due_card.dart
// LAYER: widget
// DOMAIN: features/home
// RESPONSIBLE FOR: Single medication due card rendered in the home screen list
// RECEIVES: medicationName (String), dosage (String), scheduledTimeDisplay (String),
//           scheduleLabel (String), categoryLabel (String? — nullable),
//           doseStatus (DoseStatus? — nullable),
//           onLogDose (VoidCallback)
// RETURNS: onLogDose callback
// CONNECTS TO: AppColors, AppSpacing, AppRadius, AppTypography,
//              DoseStatus, MissedDoseStateChangeAnimation
// MUST NEVER: Call repositories, services, Firebase SDKs, or state providers.
//             Hardcode any hex, dp, sp, duration, or radius value.
//             Implement AnimationController.
// ===

// flutter
import 'package:flutter/material.dart';

// internal — theme
import 'package:medadhere/core/theme/app_colors.dart';
import 'package:medadhere/core/theme/app_spacing.dart';
import 'package:medadhere/core/theme/app_radius.dart';
import 'package:medadhere/core/theme/app_typography.dart';

// internal — models

// internal — animations
import 'package:medadhere/core/theme/app_animations.dart';

import '../../../shared/models/dose_log.dart';

class MedicationDueCard extends StatelessWidget {
  const MedicationDueCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTimeDisplay,
    required this.scheduleLabel,
    this.categoryLabel,
    this.doseStatus,
    required this.onLogDose,
    required Null Function() onTap,
  });

  final String medicationName;
  final String dosage;
  final String scheduledTimeDisplay;
  final String scheduleLabel;
  final String? categoryLabel;
  final DoseStatus? doseStatus;
  final VoidCallback onLogDose;

  // --- token resolution ---

  Color _borderColor() {
    switch (doseStatus) {
      case DoseStatus.taken:
        return AppColors.colorStateConsistent;
      case DoseStatus.dueNow:
        return AppColors.colorStateSlipping;
      case DoseStatus.missed:
        return AppColors.colorStateRisk;
      case DoseStatus.later:
      case null:
        return AppColors.colorBorder;
      case DoseStatus.skipped:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DoseStatus.overdue:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  double _borderWidth() {
    switch (doseStatus) {
      case DoseStatus.taken:
      case DoseStatus.dueNow:
      case DoseStatus.missed:
        return AppSpacing.medicationCardActiveBorderWidth;
      case DoseStatus.later:
      case null:
        return AppSpacing.medicationCardBorderWidth;
      case DoseStatus.skipped:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DoseStatus.overdue:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Color _badgeBackground() {
    switch (doseStatus) {
      case DoseStatus.taken:
        return AppColors.badgeTakenBackground;
      case DoseStatus.dueNow:
        return AppColors.badgeDueBackground;
      case DoseStatus.missed:
        return AppColors.badgeMissedBackground;
      case DoseStatus.later:
        return AppColors.badgeLaterBackground;
      case DoseStatus.skipped:
        // TODO: Handle this case.
        throw UnimplementedError();
      case null:
        return AppColors.colorSurfaceMuted;
      case DoseStatus.overdue:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  Color _badgeTextColor() {
    switch (doseStatus) {
      case DoseStatus.taken:
        return AppColors.badgeTakenText;
      case DoseStatus.dueNow:
        return AppColors.badgeDueText;
      case DoseStatus.missed:
        return AppColors.badgeMissedText;
      case DoseStatus.later:
        return AppColors.badgeLaterText;
      case DoseStatus.skipped:
        // TODO: Handle this case.
        throw UnimplementedError();
      case null:
        return AppColors.colorTextTertiary;
      case DoseStatus.overdue:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  String _badgeLabel() {
    switch (doseStatus) {
      case DoseStatus.taken:
        return 'Taken';
      case DoseStatus.dueNow:
        return 'Due now';
      case DoseStatus.missed:
        return 'Missed';
      case DoseStatus.later:
        return 'Later';
      case null:
        return '';
      case DoseStatus.skipped:
        // TODO: Handle this case.
        throw UnimplementedError();
      case DoseStatus.overdue:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  // --- build ---

  @override
  Widget build(BuildContext context) {
    return MissedDoseStateChangeAnimation(
      isMissed: doseStatus == DoseStatus.missed,
      missedSurfaceColor: AppColors.colorStateRiskSurface,
      defaultSurfaceColor: AppColors.colorCard,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.colorCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: _borderColor(), width: _borderWidth()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [_topRow(context), _divider(), _bottomRow(context)],
        ),
      ),
    );
  }

  // --- private builders ---

  Widget _topRow(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                medicationName,
                style: typography.textHeading2.copyWith(
                  color: AppColors.colorTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: AppSpacing.space2),
              Text(
                dosage,
                style: typography.textCaption.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (doseStatus != null) ...[
          SizedBox(width: AppSpacing.space8),
          _statusBadge(typography),
        ],
      ],
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: AppSpacing.medicationCardDividerVertical,
      ),
      child: SizedBox(
        height: 0.5,
        child: DecoratedBox(
          decoration: BoxDecoration(color: AppColors.colorBorder),
        ),
      ),
    );
  }

  Widget _bottomRow(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          scheduledTimeDisplay,
          style: typography.textCaption.copyWith(
            color: AppColors.colorTextTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          scheduleLabel,
          style: typography.textCaption.copyWith(
            color: AppColors.colorTextTertiary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (categoryLabel != null) ...[
          SizedBox(height: AppSpacing.space2),
          Text(
            categoryLabel!,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextTertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

//
// state injection placeholders & hooks
//

/*
NOTE FOR SENIOR DEV ARCHITECT:
- DoseStatus replaces AdherenceRiskLevel as the badge driver. AdherenceRiskLevel
  is a risk scoring concept; DoseStatus is a dose event concept. They must not
  share a type. Create shared/models/dose_status.dart with:
    enum DoseStatus { taken, dueNow, missed, later }
  Source this from DueMedicationEntry in HomeNotifier._filterDue().

- State Variable Hook: doseStatus — nullable DoseStatus. When null, badge is
  removed from layout tree entirely via if() guard. Card renders with neutral
  border (colorBorder, medicationCardBorderWidth). No surface wash. No circle.

- State Variable Hook: categoryLabel — nullable String. When null, the category
  line is removed from the layout tree entirely. No empty space reserved.

- State Variable Hook: scheduledTimeDisplay — formatted String sourced from
  DueMedicationEntry.scheduledTimeDisplay, derived in HomeNotifier via
  TimeParser. Never formatted at widget layer.

- Animation Hook: MissedDoseStateChangeAnimation fires when
  doseStatus == DoseStatus.missed. Background crossfades to colorStateRiskSurface
  per Motion Moment 04 spec (240ms, easeInOut, colour crossfade only, no
  positional movement).

- REMOVED: DoseLogConfirmationAnimation. The Log Dose action lives in the
  dose logging bottom sheet, not inline on the card. This card is read-only
  from a tap-action perspective. onLogDose callback retained for the parent
  to wire a tap on the card itself if product requires it — confirm with PD.

- REMOVED: _leadingCircle(). No coloured dot in the design. Token
  doseOptionLeadingCircle is scoped to the dose option rows in the logging
  sheet, not the medication card.

- border: Both active border width (1.5dp) and colour are driven by doseStatus.
  Later and null states revert to hairline (0.5dp) colorBorder.
*/
