// ============================================
// FILE: streak_display_widget.dart
// LAYER: UI
// DOMAIN: home
// RESPONSIBLE FOR: Renders the streak card — streak count left, weekly
//                  adherence rate right. Single layout, no state switching.
//                  Contract unchanged — all fields received, only the two
//                  needed for the current layout are consumed.
// RECEIVES: currentStreakDays, lastStreakDays, streakDisplayState, riskLevel,
//           showStreakGrowthChip, rollingRate7d, previousDayAdherence,
//           postMissRecoveryRate
// RETURNS: Widget
// CONNECTS TO: app_colors.dart, app_typography.dart, app_spacing.dart,
//              app_radius.dart, streak_display_state.dart
// MUST NEVER: call any service, fetch from Firestore, hold business logic
// ============================================

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../shared/models/adherence_risk_score.dart';
import '../shared/models/streak.dart';

class StreakDisplayWidget extends StatelessWidget {
  const StreakDisplayWidget({
    super.key,
    required this.currentStreakDays,
    required this.lastStreakDays,
    required this.streakDisplayState,
    required this.riskLevel,
    required this.showStreakGrowthChip,
    required this.rollingRate7d,
    required this.previousDayAdherence,
    required this.postMissRecoveryRate,
  });

  final int currentStreakDays;
  final int lastStreakDays;
  final StreakDisplayState streakDisplayState;
  final AdherenceRiskLevel riskLevel;
  final bool showStreakGrowthChip;
  final double rollingRate7d;
  final double previousDayAdherence;
  final double postMissRecoveryRate;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final ratePercent = '${(rollingRate7d * 100).round()}%';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space20,
        vertical: AppSpacing.space24,
      ),
      decoration: BoxDecoration(
        color: AppColors.colorPrimary,
        borderRadius: AppRadius.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // ── Left: streak count ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$currentStreakDays',
                style: typography.textStreakNumber.copyWith(
                  color: AppColors.colorAccent,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'days in a row',
                style: typography.textStreakLabel.copyWith(
                  color: AppColors.streakLabelColor,
                ),
              ),
            ],
          ),

          // ── Right: weekly rate ──
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'This week',
                style: typography.textCaption.copyWith(
                  color: AppColors.streakLabelColor,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                ratePercent,
                style: typography.textHeading2.copyWith(
                  color: AppColors.colorAccent,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              Text(
                'of doses taken',
                style: typography.textCaption.copyWith(
                  color: AppColors.streakLabelColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
