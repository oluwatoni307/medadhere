// ===
// FILE:            _insight_card.dart
// PATH:            lib/features/adherence/screens/_insight_card.dart
// DOMAIN:          adherence
// LAYER:           widget
// RESPONSIBLE FOR: Renders standard insight card or cold start card — conditional on state.isColdStart
// RECEIVES:        state: AdherenceDashboardState, eyebrow: String
// RETURNS:         InsightCardRevealAnimation wrapping insight card — or static cold start card
// CONNECTS TO:     adherence_dashboard_screen.dart
// MUST NEVER:      watch any provider, declare providers, read riskLevel, call routing
// ===

// flutter
import 'package:flutter/material.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/adherence_dashboard_state.dart';
// tokens

// ─── copy constants ────────────────────────────────────────────────────────────
const String _kColdStartEyebrow = 'A beginning';
const String _kColdStartBody =
    'You have already begun. This is the start of something taking shape.';
const String _kColdStartSupporting =
    'You are already building something steady.';

// ─── widget ───────────────────────────────────────────────────────────────────
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.state, required this.eyebrow});

  final AdherenceDashboardState state;
  final String eyebrow;

  @override
  Widget build(BuildContext context) {
    return state.isColdStart
        ? _buildColdStartCard(context)
        : _buildInsightCard(context);
  }

  // ─── standard insight card ───────────────────────────────────────────────────

  Widget _buildInsightCard(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final stateColors = Theme.of(context).extension<MedAdhereStateColors>()!;

    // STATE HOOK POINT:
    // eyebrow colour should reflect live adherence state primary colour
    // Placeholder: AppColors.colorStateConsistent
    // Senior Dev replaces with runtime state primary colour once
    // AdherenceDashboardState exposes adherenceDisplayState or eyebrowLabel
    const Color eyebrowColor = AppColors.colorStateConsistent;

    return InsightCardRevealAnimation(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          // TOKEN GAP: insightCardSurfaceActive — not in Reference Card
          // Visual Director to confirm and add to MedAdhereStateColors
          color: stateColors.insightCardSurfaceActive,
          borderRadius: AppRadius.card,
          border: Border(
            left: BorderSide(
              color: stateColors.insightCardBorderActive,
              width: AppSpacing.insightCardBorderWidth,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.insightCardPaddingVertical,
          horizontal: AppSpacing.insightCardPaddingHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: typography.textInsightCardEyebrow.copyWith(
                color: eyebrowColor,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              state.insightCardText,
              style: typography.textInsightCardBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              state.insightCardAction,
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── cold start card ─────────────────────────────────────────────────────────

  Widget _buildColdStartCard(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.colorStateMorningSurface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorStateMorning,
          width: AppSpacing.observationCardBorderWidth,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ColdStartSymbol(),
          const SizedBox(height: AppSpacing.space12),
          Text(
            _kColdStartEyebrow.toUpperCase(),
            style: typography.textLabel.copyWith(
              color: AppColors.colorStateMorning,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            _kColdStartBody,
            style: typography.textBody.copyWith(
              color: AppColors.colorTextPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Text(
            _kColdStartSupporting,
            style: typography.textBodySmall.copyWith(
              color: AppColors.colorTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── private widgets ──────────────────────────────────────────────────────────

class _ColdStartSymbol extends StatelessWidget {
  const _ColdStartSymbol();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: CustomPaint(
        painter: _ArcPainter(
          color: AppColors.colorStateMorning.withOpacity(
            AppMotion.decorativeSymbolOpacity,
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  const _ArcPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    // Open arc — 180 degrees, starts at left, sweeps bottom half
    canvas.drawArc(rect, 0, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(_ArcPainter oldDelegate) => oldDelegate.color != color;
}

// ─── state injection hooks ────────────────────────────────────────────────────
/*
NOTE FOR SENIOR DEV:
STATE:    eyebrowColor in _buildInsightCard() is placeholder AppColors.colorStateConsistent
          Pending data contract decision — see options below:
          Option A: Add eyebrowLabel: String to AdherenceDashboardState — widget renders directly
          Option B: Add AdherenceDisplayState enum to state — widget maps to colour + string

TOKEN GAP: insightCardSurfaceActive — not present in MedAdhereStateColors in Reference Card
           Visual Director to add alongside insightCardBorderActive
*/
