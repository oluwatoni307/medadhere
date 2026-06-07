// ============================================
// FILE: streak_display_widget.dart
// LAYER: UI
// DOMAIN: home
// RESPONSIBLE FOR: Renders the streak display surface across three distinct
//                  emotional states — firstTime, lapsed, active.
//                  Fixed card dimensions. Both columns always carry weight.
// RECEIVES: currentStreakDays, lastStreakDays, streakDisplayState, riskLevel,
//           showStreakGrowthChip, rollingRate7d, previousDayAdherence,
//           postMissRecoveryRate
// RETURNS: Widget
// CONNECTS TO: app_colors.dart, app_typography.dart, app_spacing.dart,
//              app_radius.dart, app_motion.dart, streak_display_state.dart
// MUST NEVER: call any service, fetch from Firestore, hold business logic
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_motion.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../shared/models/adherence_risk_score.dart';
import 'shared/models/streak.dart';

// ─── Card dimensions ──────────────────────────────────────────────────────────
//
// Fixed. Every state fills this surface intentionally.
// No shrink-wrapping. No mainAxisSize.min at the card level.

const double _kCardWidth = 320;
const double _kCardHeight = 148;

class StreakDisplayWidget extends StatefulWidget {
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
  State<StreakDisplayWidget> createState() => _StreakDisplayWidgetState();
}

class _StreakDisplayWidgetState extends State<StreakDisplayWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _growthChipController;
  late final Animation<double> _growthChipOpacity;

  @override
  void initState() {
    super.initState();

    _growthChipController = AnimationController(
      vsync: this,
      duration: AppMotion.durationStreak,
    );

    _growthChipOpacity = CurvedAnimation(
      parent: _growthChipController,
      curve: AppMotion.curveStandard,
    );

    if (widget.showStreakGrowthChip) {
      _triggerGrowthChipEntrance();
    }
  }

  @override
  void didUpdateWidget(covariant StreakDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.showStreakGrowthChip && !oldWidget.showStreakGrowthChip) {
      _triggerGrowthChipEntrance();
    }

    if (!widget.showStreakGrowthChip && oldWidget.showStreakGrowthChip) {
      _growthChipController.reset();
    }
  }

  void _triggerGrowthChipEntrance() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      final bool reduceMotion = MediaQuery.of(context).disableAnimations;

      if (reduceMotion) {
        _growthChipController.value = 1.0;
      } else {
        if (_growthChipController.status != AnimationStatus.completed) {
          _growthChipController.forward();
          HapticFeedback.lightImpact();
        }
      }
    });
  }

  @override
  void dispose() {
    _growthChipController.dispose();
    super.dispose();
  }

  // ─── Surface color ───────────────────────────────────────────────────────────
  //
  // firstTime → always primary. No risk data yet — never flag risk.
  // lapsed    → always ember. The streak broke. Acknowledge it honestly.
  // active    → driven by riskLevel.

  Color get _surfaceColor {
    return switch (widget.streakDisplayState) {
      StreakDisplayState.firstTime => AppColors.colorPrimary,
      StreakDisplayState.lapsed => AppColors.colorStateEmber,
      StreakDisplayState.active => switch (widget.riskLevel) {
        AdherenceRiskLevel.onTrack => AppColors.colorPrimary,
        AdherenceRiskLevel.atRisk => AppColors.colorStateDusk,
        AdherenceRiskLevel.highRisk => AppColors.colorStateEmber,
      },
    };
  }

  // ─── Qualitative read ────────────────────────────────────────────────────────
  //
  // Four tiers. No binary fallthrough.
  //   1.0       → perfect yesterday
  //   >= 0.75   → close yesterday
  //   > 0.0     → partial yesterday
  //   0.0       → missed yesterday

  String get _qualitativeRead {
    if (widget.previousDayAdherence >= 1.0) return 'perfect yesterday';
    if (widget.previousDayAdherence >= 0.75) return 'close yesterday';
    if (widget.previousDayAdherence > 0.0) return 'partial yesterday';
    return 'missed yesterday';
  }

  // ─── Recovery line ───────────────────────────────────────────────────────────
  //
  // Only meaningful after a confirmed miss with enough history to pattern-match.
  // Suppressed on streaks < 3 — too early to claim a recovery pattern.

  bool get _showRecovery =>
      widget.streakDisplayState == StreakDisplayState.active &&
      widget.postMissRecoveryRate >= 0.75 &&
      widget.currentStreakDays >= 3;

  // ─── Rate block guard ────────────────────────────────────────────────────────
  //
  // Never show 0% on an active streak — day 1 edge case.

  bool get _showRateBlock =>
      widget.streakDisplayState == StreakDisplayState.active &&
      widget.rollingRate7d > 0.0;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedContainer(
        duration: AppMotion.durationMedium,
        curve: AppMotion.curveTransition,
        width: _kCardWidth,
        height: _kCardHeight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space32,
          vertical: AppSpacing.space20,
        ),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: AppRadius.card,
        ),
        child: switch (widget.streakDisplayState) {
          StreakDisplayState.firstTime => _FirstTimeLayout(
            typography: typography,
          ),
          StreakDisplayState.lapsed => _LapsedLayout(
            lastStreakDays: widget.lastStreakDays,
            qualitativeRead: _qualitativeRead,
            typography: typography,
          ),
          StreakDisplayState.active => _ActiveLayout(
            days: widget.currentStreakDays,
            rollingRate7d: widget.rollingRate7d,
            showRateBlock: _showRateBlock,
            qualitativeRead: _qualitativeRead,
            showRecovery: _showRecovery,
            showGrowthChip: widget.showStreakGrowthChip,
            growthChipOpacity: _growthChipOpacity,
            typography: typography,
          ),
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE — First time layout
// ─────────────────────────────────────────────────────────────────────────────

class _FirstTimeLayout extends StatelessWidget {
  const _FirstTimeLayout({required this.typography});

  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '—',
                      style: typography.textStreakNumber.copyWith(
                        color: AppColors.colorAccent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'first dose',
                      style: typography.textStreakLabel.copyWith(
                        color: AppColors.streakLabelColor,
                      ),
                    ),
                  ],
                ),
              ),
              _EmptyRing(),
            ],
          ),
        ),
        Text(
          'your streak starts today',
          style: typography.textBodySmall.copyWith(
            color: AppColors.streakLabelColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE — Lapsed layout
// ─────────────────────────────────────────────────────────────────────────────

class _LapsedLayout extends StatelessWidget {
  const _LapsedLayout({
    required this.lastStreakDays,
    required this.qualitativeRead,
    required this.typography,
  });

  final int lastStreakDays;
  final String qualitativeRead;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '—',
                      style: typography.textStreakNumber.copyWith(
                        color: AppColors.colorAccent,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Text(
                      'streak broken',
                      style: typography.textStreakLabel.copyWith(
                        color: AppColors.streakLabelColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (lastStreakDays > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'last streak',
                      style: typography.textCaption.copyWith(
                        color: AppColors.streakLabelColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      '$lastStreakDays days',
                      style: typography.textHeading2.copyWith(
                        color: AppColors.colorAccent,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Text(
          '$qualitativeRead · today resets everything',
          style: typography.textBodySmall.copyWith(
            color: AppColors.streakLabelColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE — Active layout
//
// Two fixes applied:
//   1. "of doses taken" restored below the rate percentage.
//   2. Spacer() replaced with fixed SizedBox — footer sits close to hero row,
//      no dead air at the bottom of the card.
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveLayout extends StatelessWidget {
  const _ActiveLayout({
    required this.days,
    required this.rollingRate7d,
    required this.showRateBlock,
    required this.qualitativeRead,
    required this.showRecovery,
    required this.showGrowthChip,
    required this.growthChipOpacity,
    required this.typography,
  });

  final int days;
  final double rollingRate7d;
  final bool showRateBlock;
  final String qualitativeRead;
  final bool showRecovery;
  final bool showGrowthChip;
  final Animation<double> growthChipOpacity;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final ratePercent = '${(rollingRate7d * 100).round()}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Hero row ──────────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left — streak number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$days',
                  style: typography.textStreakNumber.copyWith(
                    color: AppColors.colorAccent,
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

            const Spacer(),

            // Right — weekly rate block, visually subordinate
            if (showRateBlock)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.space8),
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
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space2),
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

        // ── Growth chip ───────────────────────────────────────────────────────
        if (showGrowthChip) ...[
          const SizedBox(height: AppSpacing.space8),
          FadeTransition(
            opacity: growthChipOpacity,
            child: _GrowthChipRow(typography: typography),
          ),
        ],

        // ── Footer ───────────────────────────────────────────────────────────
        const SizedBox(height: AppSpacing.space16),
        Text(
          qualitativeRead,
          style: typography.textBodySmall.copyWith(
            color: AppColors.streakLabelColor,
          ),
        ),

        if (showRecovery) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            'you always bounce back',
            style: typography.textCaption.copyWith(
              color: AppColors.streakLabelColor,
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE — Empty ring
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyRing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.streakChipBorder, width: 2.0),
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.streakChipBackground,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE — Growth chip row
// ─────────────────────────────────────────────────────────────────────────────

class _GrowthChipRow extends StatelessWidget {
  const _GrowthChipRow({required this.typography});

  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space12,
          vertical: AppSpacing.space4,
        ),
        decoration: BoxDecoration(
          color: AppColors.streakChipBackground,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.streakChipBorder, width: 1.0),
        ),
        child: Text(
          '+1 day ↗',
          style: typography.textStreakChipLabel.copyWith(
            color: AppColors.colorAccent,
          ),
        ),
      ),
    );
  }
}
