// ============================================
// FILE: medication_due_card.dart
// LAYER: widget
// DOMAIN: features/home
// RESPONSIBLE FOR: Single medication card rendered in the medication list page
// RECEIVES: medicationName (String), dosage (String), scheduledTimeDisplay (String),
//           scheduleLabel (String), categoryLabel (String? — nullable),
//           status (DoseStatus — required),
//           onTap (VoidCallback? — nullable),
//           onLogDose (VoidCallback? — nullable)
// RETURNS: nothing — display only
// CONNECTS TO: AppColors, AppSpacing, AppRadius, AppTypography,
//              DoseStatus, MissedDoseStateChangeAnimation,
//              DoseLogConfirmationAnimation, AppMotion
// MUST NEVER: Call repositories, services, Firebase SDKs, or state providers.
//             Hardcode any hex, dp, duration, or radius value.
//             Implement AnimationController.
// ============================================

import 'package:flutter/material.dart';

import 'package:medadhere/core/theme/app_colors.dart';
import 'package:medadhere/core/theme/app_spacing.dart';
import 'package:medadhere/core/theme/app_radius.dart';
import 'package:medadhere/core/theme/app_typography.dart';
import 'package:medadhere/core/theme/app_motion.dart';
import 'package:medadhere/core/theme/app_animations.dart';

import '../shared/models/dose_log.dart';

class MedicationDueCard extends StatelessWidget {
  const MedicationDueCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTimeDisplay,
    required this.scheduleLabel,
    this.categoryLabel,
    required this.status,
    this.onTap,
    this.onLogDose,
  });

  final String medicationName;
  final String dosage;
  final String scheduledTimeDisplay;
  final String scheduleLabel;
  final String? categoryLabel;
  final DoseStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onLogDose;

  // --- token resolution ---

  // Left accent border — carries ambient status at card level.
  // Full perimeter border removed. Status weight now lives on badge only.
  Color _accentColor() => switch (status) {
    DoseStatus.taken => AppColors.colorStateConsistent,
    DoseStatus.later => AppColors.colorStateMorning,
    DoseStatus.dueNow => AppColors.colorStateSlipping,
    DoseStatus.overdue => AppColors.colorStateRisk,
    DoseStatus.missed => AppColors.colorStateRisk,
    DoseStatus.skipped => AppColors.colorBorder,
  };

  Color _badgeBackground() => switch (status) {
    DoseStatus.taken => AppColors.badgeTakenBackground,
    DoseStatus.later => AppColors.badgeLaterBackground,
    DoseStatus.dueNow => AppColors.badgeDueBackground,
    DoseStatus.overdue => AppColors.badgeMissedBackground,
    DoseStatus.missed => AppColors.badgeMissedBackground,
    DoseStatus.skipped => AppColors.badgeTakenBackground,
  };

  Color _badgeTextColor() => switch (status) {
    DoseStatus.taken => AppColors.badgeTakenText,
    DoseStatus.later => AppColors.badgeLaterText,
    DoseStatus.dueNow => AppColors.badgeDueText,
    DoseStatus.overdue => AppColors.badgeMissedText,
    DoseStatus.missed => AppColors.badgeMissedText,
    DoseStatus.skipped => AppColors.badgeTakenText,
  };

  String _badgeLabel() => switch (status) {
    DoseStatus.taken => 'Taken',
    DoseStatus.later => 'Later',
    DoseStatus.dueNow => 'Due now',
    DoseStatus.overdue => 'Overdue',
    DoseStatus.missed => 'Missed',
    DoseStatus.skipped => 'Skipped',
  };

  /// Accountable Resolution Check: Only active unlogged items that are still
  /// within their actionable therapeutic time window allow direct logging input.
  bool _showLogButton() => switch (status) {
    DoseStatus.dueNow => true,
    DoseStatus.overdue => true,
    DoseStatus.missed => false, // Hard-locked for adherence accountability
    DoseStatus.taken => false,
    DoseStatus.later => false,
    DoseStatus.skipped => false,
  };

  // --- build ---

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: onTap != null,
      label: '$medicationName, $dosage. Tap to view details.',
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: AnimatedContainer(
          duration: reduceMotion
              ? AppMotion.durationInstant
              : AppMotion.missedDoseStateChangeDuration,
          curve: AppMotion.missedDoseStateChangeCurve,
          // Card surface is always white — status is carried by accent
          // border and badge only. Colored surfaces removed per Option B.
          color: AppColors.colorCard,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: AppRadius.card,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.space8),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.card,
                  // Left accent border only — full perimeter border removed.
                  // insightCardBorderWidth (5dp) chosen because it is the
                  // only left-accent border token in the system and was
                  // confirmed visible in screenshot audit.
                  border: Border(
                    left: BorderSide(
                      color: _accentColor(),
                      width: AppSpacing.insightCardBorderWidth,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [_topRow(context), _divider(), _bottomRow(context)],
                ),
              ),
            ),
          ),
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
        SizedBox(width: AppSpacing.space8),
        if (onTap != null) ...[
          Icon(
            Icons.chevron_right,
            size: AppSpacing.iconSizeStandard,
            color: AppColors.colorTextTertiary,
          ),
          SizedBox(width: AppSpacing.space4),
        ],
        _badge(typography),
      ],
    );
  }

  Widget _badge(AppTypography typography) {
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

  Widget _logButton(AppTypography typography) {
    return DoseLogConfirmationAnimation(
      onTap: () {
        AppMotion.hapticDoseConfirmation();
        onLogDose?.call();
      },
      child: Container(
        height: AppSpacing.buttonHeightCard,
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.space16),
        decoration: BoxDecoration(
          color: AppColors.colorPrimary,
          borderRadius: AppRadius.button,
        ),
        alignment: Alignment.center,
        child: Text(
          'Log dose',
          style: typography.textBodySmall.copyWith(
            color: AppColors.colorOnPrimary,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.space8),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
          ),
        ),
        if (_showLogButton()) ...[
          SizedBox(width: AppSpacing.space8),
          _logButton(typography),
        ],
      ],
    );
  }
}
