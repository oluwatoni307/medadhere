// ============================================
// FILE: streak_display_widget.dart
// LAYER: UI
// DOMAIN: home
// RESPONSIBLE FOR: Renders the home screen's streak/today card — a single
//                  headline sentence fusing streak continuity with today's
//                  status, plus a quiet secondary line ("Next: <med> in
//                  <time>" or "Today's done"). Pure render — all copy
//                  decisions happen upstream in buildStreakCardMessage
//                  (streak_notifier.dart); this widget never branches on
//                  state itself beyond the milestone visual treatment.
// RECEIVES: StreakCardMessage (built)
// RETURNS: Widget
// CONNECTS TO: app_colors.dart, app_typography.dart, app_spacing.dart,
//              app_radius.dart, streak_notifier.dart
// MUST NEVER: call any service, fetch from Firestore, hold business logic,
//             or branch on StreakDisplayState/DoseStatus directly — that
//             belongs in buildStreakCardMessage (streak_notifier.dart)
// ============================================

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';
import '../features/home/state/streak_notifier.dart';

class StreakDisplayWidget extends StatelessWidget {
  const StreakDisplayWidget({super.key, required this.message});

  final StreakCardMessage message;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space20,
        vertical: AppSpacing.space24,
      ),
      decoration: BoxDecoration(
        // Deep Forest — the same flat colorPrimary token used everywhere
        // else on-dark. Matches the sampled production color almost
        // exactly (#1C2B1E vs sampled #1D2B1E). No gradient — this file's
        // own rules defer dark-mode/multi-stop surfaces; every other
        // on-dark surface in the app is flat, this card stays consistent
        // with that rather than introducing a one-off treatment.
        color: AppColors.colorPrimary,
        borderRadius: AppRadius.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Headline: fused streak + today sentence ──
          // textStreakHeadline — Amendment A002. Italic DM Serif Display,
          // the one sanctioned exception to this system's no-italics rule.
          // See app_typography.dart file header for full rationale.
          // Milestone renders get colorAccent (Aged Gold) — the one
          // documented "achievement" token. Every other render uses
          // colorOnPrimary (Warm Parchment), same as any other text on
          // a colorPrimary surface elsewhere in the app. Rule 5 (colour
          // is never the sole carrier of meaning) is still satisfied —
          // the milestone copy itself, not just the color, signals the
          // moment.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              message.headline,
              key: ValueKey(message.headline),
              style: typography.textStreakHeadline.copyWith(
                color: message.isMilestone
                    ? AppColors.colorAccent
                    : AppColors.colorOnPrimary,
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.space20),

          // ── Divider ──
          // No dedicated on-dark divider token exists yet. Derived from
          // colorOnPrimary at low opacity, following the same pattern
          // colorBorder already uses (colorPrimary at 0.10) for its
          // light-surface equivalent — consistent method, inverted base.
          Container(
            height: 1,
            color: AppColors.colorOnPrimary.withOpacity(0.10),
          ),

          const SizedBox(height: AppSpacing.space16),

          // ── Secondary line: quiet, never competes with the headline ──
          // Right-aligned to match the original mockup's two-column
          // intent (label left, value right). message.secondaryLine is
          // a single combined string, not two separate values, so this
          // is a simple right-align rather than a true two-column split —
          // see chat note if the fuller "Next" / value split is wanted
          // later instead.
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              message.secondaryLine,
              style: typography.textCaption.copyWith(
                color: AppColors.streakLabelColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
