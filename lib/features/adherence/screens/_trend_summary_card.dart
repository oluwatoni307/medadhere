// ===
// FILE:            _trend_summary_card.dart
// PATH:            lib/features/adherence/screens/_trend_summary_card.dart
// DOMAIN:          adherence
// LAYER:           widget
// RESPONSIBLE FOR: Renders weekly trend headline and supporting dose rate line — colour driven by TrendDirection
// RECEIVES:        trend: TrendDirection, weeklyRate: double
// RETURNS:         full-width Container — surface colour, headline, supporting line
// CONNECTS TO:     adherence_dashboard_screen.dart
// MUST NEVER:      watch any provider, declare providers, call routing, access BuildContext above its own tree
// ===

// flutter
import 'package:flutter/material.dart';
// tokens
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/adherence_dashboard_state.dart';

// ─── copy constants ────────────────────────────────────────────────────────────
const String _kTrendImproving = "You're finding your rhythm.";
const String _kTrendStable = "You've been steady.";
const String _kTrendDeclining = 'This week asked more of you.';

// ─── widget ───────────────────────────────────────────────────────────────────
// ignore: unused_element
class TrendSummaryCard extends StatelessWidget {
  const TrendSummaryCard({
    super.key,
    required this.trend,
    required this.weeklyRate,
  });

  final TrendDirection trend;
  final double weeklyRate;

  Color _surfaceColor() => switch (trend) {
    TrendDirection.improving => AppColors.colorStateConsistentSurface,
    TrendDirection.stable => AppColors.colorCard,
    TrendDirection.declining => AppColors.colorStateSlippingSurface,
  };

  Color _headlineColor() => switch (trend) {
    TrendDirection.improving => AppColors.colorStateConsistent,
    TrendDirection.stable => AppColors.colorTextPrimary,
    TrendDirection.declining => AppColors.colorStateSlipping,
  };

  String _headlineCopy() => switch (trend) {
    TrendDirection.improving => _kTrendImproving,
    TrendDirection.stable => _kTrendStable,
    TrendDirection.declining => _kTrendDeclining,
  };

  String _supportingLine() =>
      'You kept up with ${(weeklyRate * 100).round()}% of your doses this week.';

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surfaceColor(),
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.colorBorder, width: 0.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _headlineCopy(),
            style: typography.textHeading2.copyWith(color: _headlineColor()),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            _supportingLine(),
            style: typography.textBody.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
