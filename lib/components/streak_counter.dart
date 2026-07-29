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
import 'package:medadhere/features/home/state/streak_notifier.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

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
          // ── Headline: lead clause + optional accent detail clause ──
          // textStreakHeadline — Amendment A002. Italic DM Serif Display,
          // the one sanctioned exception to this system's no-italics rule.
          // See app_typography.dart file header for full rationale.
          // Two lines when headlineDetail is present, matching the
          // original mockup (lead plain, detail in accent brass on its
          // own line) — this was previously flattened into one
          // single-color sentence, which read as a dense, undifferentiated
          // wall of text. Single line when detail is null.
          // Milestone renders get colorAccent on the lead line too — the
          // one documented "achievement" token. Rule 5 (colour is never
          // the sole carrier of meaning) is still satisfied — the
          // milestone copy itself, not just the color, signals the
          // moment.
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Column(
              key: ValueKey(
                '${message.headlineLead}|${message.headlineDetail}',
              ),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.headlineLead,
                  style: typography.textStreakHeadline.copyWith(
                    color: message.isMilestone
                        ? AppColors.colorAccent
                        : AppColors.colorOnPrimary,
                    height: 1.4,
                  ),
                ),
                if (message.headlineDetail != null)
                  Text(
                    message.headlineDetail!,
                    style: typography.textStreakHeadline.copyWith(
                      color: AppColors.colorAccent,
                      height: 1.4,
                    ),
                  ),
              ],
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
          // Two-column layout when there's a label ("Next" / value),
          // matching the original mockup's label-left, value-right
          // intent. Falls back to a single right-aligned line for
          // label-less states ("Today's done.") where a label/value
          // split doesn't make sense.
          if (message.secondaryLabel != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  message.secondaryLabel!,
                  style: typography.textCaption.copyWith(
                    color: AppColors.streakLabelColor,
                  ),
                ),
                Flexible(
                  child: Text(
                    message.secondaryValue,
                    style: typography.textCaption.copyWith(
                      color: AppColors.streakLabelColor,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                message.secondaryValue,
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
