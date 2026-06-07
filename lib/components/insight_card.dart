import 'package:flutter/material.dart';

import '../core/theme/app_animations.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_radius.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_typography.dart';

/// The two semantic variants of the insight card.
///
/// [pattern]     — "YOUR PATTERN" eyebrow. Consistent state colour family.
/// [worthKnowing] — "WORTH KNOWING" eyebrow. Slipping state colour family.
enum InsightCardVariant { pattern, worthKnowing }

/// A single insight card surface.
///
/// Colour (border + surface wash) is intrinsic to [variant] — it is not
/// driven by any external adherence state. The eyebrow label is always
/// rendered UPPERCASE at widget level per the design reference card.
///
/// The [InsightCardRevealAnimation] is owned here so callers cannot omit it.
///
/// Example:
/// ```dart
/// InsightCard(
///   variant: InsightCardVariant.pattern,
///   body: 'Your mornings are locked in — 14 days without missing a single morning dose.',
/// )
/// ```
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.variant, required this.body});

  final InsightCardVariant variant;
  final String body;

  @override
  Widget build(BuildContext ctx) {
    final typography = Theme.of(ctx).extension<AppTypography>()!;
    final config = _variantConfig(variant);

    return InsightCardRevealAnimation(
      child: Container(
        decoration: BoxDecoration(
          color: config.surface,
          borderRadius: AppRadius.card,
          border: Border(
            left: BorderSide(
              color: config.border,
              width: AppSpacing.insightCardBorderWidth,
            ),
          ),
        ),
        padding: EdgeInsets.symmetric(
          vertical: AppSpacing.insightCardPaddingVertical,
          horizontal: AppSpacing.insightCardPaddingHorizontal,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              // textInsightCardEyebrow is always rendered UPPERCASE at widget level.
              config.eyebrow.toUpperCase(),
              style: typography.textInsightCardEyebrow.copyWith(
                color: config.border,
              ),
            ),
            SizedBox(height: AppSpacing.space8),
            Text(
              body,
              style: typography.textInsightCardBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Variant config ─────────────────────────────────────────────────────────

class _InsightCardConfig {
  const _InsightCardConfig({
    required this.eyebrow,
    required this.border,
    required this.surface,
  });

  final String eyebrow;
  final Color border;
  final Color surface;
}

_InsightCardConfig _variantConfig(InsightCardVariant v) => switch (v) {
  InsightCardVariant.pattern => const _InsightCardConfig(
    eyebrow: 'Your pattern',
    border: AppColors.colorStateConsistent,
    surface: AppColors.colorStateConsistentSurface,
  ),
  InsightCardVariant.worthKnowing => const _InsightCardConfig(
    eyebrow: 'Worth knowing',
    border: AppColors.colorStateSlipping,
    surface: AppColors.colorStateSlippingSurface,
  ),
};
