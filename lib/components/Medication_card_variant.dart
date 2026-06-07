import 'package:flutter/material.dart';

import 'package:medadhere/core/theme/app_colors.dart';
import 'package:medadhere/core/theme/app_spacing.dart';
import 'package:medadhere/core/theme/app_radius.dart';
import 'package:medadhere/core/theme/app_typography.dart';
import 'package:medadhere/core/theme/app_motion.dart';
import 'package:medadhere/core/theme/app_animations.dart';
// ADD this import alongside the existing ones
import 'package:medadhere/features/home/state/home_provider.dart';

/// Urgency tier derived upstream in HomeNotifier from time remaining.
/// Never computed inside this widget.
///
/// Tier 1 — 12h–6h   → cold start colour  (on the radar, no urgency)
/// Tier 2 — 6h–2h    → consistent colour  (approaching)
/// Tier 3 — 2h–30min → slipping colour    (getting close)
/// Tier 4 — <30min or overdue → risk colour (act now)
///
/// Cards with >12h remaining are filtered out upstream — never reach this widget.

/// Compact medication card for the home screen due list.
///
/// Single-row layout — medication name + dosage on the left,
/// time badge + log button stacked on the right.
/// Border colour reflects [urgencyTier].
/// No divider, no bottom row — this card does not take centre stage.
///
/// [timeRemaining] is a pre-formatted string produced upstream.
/// Examples: "8h 20m", "45m", "Overdue".
/// No date/time formatting happens here.
class HomeMedicationCard extends StatelessWidget {
  const HomeMedicationCard({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.timeRemaining,
    required this.urgencyTier,
    this.onTap,
    this.onLogDose,
  });

  final String medicationName;
  final String dosage;
  final String timeRemaining;
  final MedicationUrgencyTier urgencyTier;
  final VoidCallback? onTap;
  final VoidCallback? onLogDose;

  // --- token resolution ---

  Color _borderColor() => switch (urgencyTier) {
    MedicationUrgencyTier.tier1 => AppColors.colorStateMorning,
    MedicationUrgencyTier.tier2 => AppColors.colorStateConsistent,
    MedicationUrgencyTier.tier3 => AppColors.colorStateSlipping,
    MedicationUrgencyTier.tier4 => AppColors.colorStateRisk,
  };

  Color _badgeBackground() => switch (urgencyTier) {
    MedicationUrgencyTier.tier1 => AppColors.colorStateMorningSurface,
    MedicationUrgencyTier.tier2 => AppColors.colorStateConsistentSurface,
    MedicationUrgencyTier.tier3 => AppColors.colorStateSlippingSurface,
    MedicationUrgencyTier.tier4 => AppColors.colorStateRiskSurface,
  };

  Color _badgeTextColor() => switch (urgencyTier) {
    MedicationUrgencyTier.tier1 => AppColors.colorStateMorning,
    MedicationUrgencyTier.tier2 => AppColors.colorStateConsistent,
    MedicationUrgencyTier.tier3 => AppColors.colorStateSlipping,
    MedicationUrgencyTier.tier4 => AppColors.colorStateRisk,
  };

  double _borderWidth() => switch (urgencyTier) {
    MedicationUrgencyTier.tier1 => AppSpacing.medicationCardBorderWidth,
    MedicationUrgencyTier.tier2 => AppSpacing.medicationCardBorderWidth,
    MedicationUrgencyTier.tier3 => AppSpacing.medicationCardActiveBorderWidth,
    MedicationUrgencyTier.tier4 => AppSpacing.medicationCardActiveBorderWidth,
  };

  // --- build ---

  @override
  Widget build(BuildContext ctx) {
    final typography = Theme.of(ctx).extension<AppTypography>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.space12),
        decoration: BoxDecoration(
          color: AppColors.colorCard,
          borderRadius: AppRadius.card,
          border: Border.all(color: _borderColor(), width: _borderWidth()),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left — name + dosage
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
            // Right — time badge + log button stacked
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimeBadge(
                  label: timeRemaining,
                  background: _badgeBackground(),
                  textColor: _badgeTextColor(),
                  typography: typography,
                ),
                SizedBox(height: AppSpacing.space4),
                _LogButton(onLogDose: onLogDose, typography: typography),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Private sub-widgets ────────────────────────────────────────────────────

class _TimeBadge extends StatelessWidget {
  const _TimeBadge({
    required this.label,
    required this.background,
    required this.textColor,
    required this.typography,
  });

  final String label;
  final Color background;
  final Color textColor;
  final AppTypography typography;

  @override
  Widget build(BuildContext ctx) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.badge,
      ),
      child: Text(
        label,
        style: typography.textLabel.copyWith(color: textColor),
        maxLines: 1,
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({required this.onLogDose, required this.typography});

  final VoidCallback? onLogDose;
  final AppTypography typography;

  @override
  Widget build(BuildContext ctx) {
    return DoseLogConfirmationAnimation(
      onTap: () {
        AppMotion.hapticDoseConfirmation();
        onLogDose?.call();
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.colorPrimary,
          borderRadius: AppRadius.button,
        ),
        child: Text(
          'Log',
          style: typography.textLabel.copyWith(color: AppColors.colorOnPrimary),
          maxLines: 1,
        ),
      ),
    );
  }
}
