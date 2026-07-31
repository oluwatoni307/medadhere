// ============================================
// FILE: adherence_visualization_screen.dart
// LAYER: screen
// DOMAIN: adherence
// RESPONSIBLE FOR: Root screen for adherence visualization.
//                  Owns the time range toggle and async state for all three views.
//                  Renders skeleton, error, or the active visualization widget.
// RECEIVES: nothing — top-level nav bar destination
// RETURNS: Scaffold with title, streak chip, toggle, visualization area,
//          trend sentence, insight card, pattern observations
// CONNECTS TO: adherence_visualization_provider.dart,
//              adherence_provider.dart,
//              _adherence_strip_widget.dart,
//              _adherence_line_chart_widget.dart,
//              _adherence_trend_chart_widget.dart,
//              adherence_visualization_models.dart,
//              adherence_dashboard_state.dart
// MUST NEVER: read riskLevel, call services, declare providers,
//             call routing methods, hardcode any value
// ============================================

// flutter
import 'package:flutter/material.dart';
// packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
// state
import '../state/adherence_provider.dart';
import '../state/adherence_visualization_provider.dart';
// models
import '../../../shared/models/adherence_dashboard_state.dart';
// theme
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_motion.dart';
// widgets
import '_adherence_strip_widget.dart';
import '_adherence_line_chart_widget.dart';
import '_adherence_trend_chart_widget.dart';

// ─── constants ────────────────────────────────────────────────────────────────

const String _kScreenTitle = 'Adherence';
const String _kStreakLabel = 'days in a row';
const String _kErrorHeading = "Couldn't load this yet";
const String _kErrorBody = 'Try again in a moment.';
const String _kErrorRetry = 'Try again';

const List<String> _kRangeLabels = ['Recent', 'Monthly', '90-Day'];

// ─── range enum ───────────────────────────────────────────────────────────────

enum _TimeRange { recent, monthly, ninetyDays }

// ─── screen ───────────────────────────────────────────────────────────────────

class AdherenceVisualizationScreen extends ConsumerStatefulWidget {
  const AdherenceVisualizationScreen({super.key});

  @override
  ConsumerState<AdherenceVisualizationScreen> createState() =>
      _AdherenceVisualizationScreenState();
}

class _AdherenceVisualizationScreenState
    extends ConsumerState<AdherenceVisualizationScreen> {
  _TimeRange _activeRange = _TimeRange.recent;

  @override
  Widget build(BuildContext context) {
    // adherenceProvider — streak + ML risk scores
    // adherenceStripProvider — dot grid (watched inside _buildStripView)
    // adherenceMonthProvider — monthly chart (watched inside _buildMonthView)
    // adherenceTrendProvider — 90-day chart (watched inside _buildTrendView)
    final dashboardAsync = ref.watch(adherenceProvider);

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.viewportMarginVertical),
            ),
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space8)),
            SliverToBoxAdapter(
              child: _buildStreakChip(context, dashboardAsync),
            ),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space20)),
            SliverToBoxAdapter(child: _buildToggle(context)),
            SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space24)),
            SliverToBoxAdapter(
              child: _buildActiveView(context, dashboardAsync),
            ),
            SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.viewportMarginVertical),
            ),
          ],
        ),
      ),
    );
  }

  // ─── header ───────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Text(
        _kScreenTitle,
        style: typography.textScreenTitle.copyWith(
          color: AppColors.colorTextPrimary,
        ),
      ),
    );
  }

  // ─── streak chip ──────────────────────────────────────────────────────────
  // Reads currentStreakDays from adherenceProvider — the correct field.
  // Falls back to 0 while loading or on error.

  Widget _buildStreakChip(
    BuildContext context,
    AsyncValue<AdherenceDashboardState> dashboardAsync,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final streakDays = dashboardAsync.maybeWhen(
      data: (state) => state.currentStreakDays,
      orElse: () => 0,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space8,
            horizontal: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: AppColors.streakChipBackground,
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.streakChipBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$streakDays',
                style: typography.textStreakChipNumber.copyWith(
                  color: AppColors.colorAccent,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Text(
                _kStreakLabel,
                style: typography.textStreakChipLabel.copyWith(
                  color: AppColors.streakLabelColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── toggle ───────────────────────────────────────────────────────────────

  Widget _buildToggle(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.colorSurfaceMuted,
          borderRadius: AppRadius.chip,
        ),
        padding: const EdgeInsets.all(AppSpacing.space4),
        child: Row(
          children: _TimeRange.values.map((range) {
            final isActive = range == _activeRange;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _activeRange = range),
                child: AnimatedContainer(
                  duration: AppMotion.durationMedium,
                  curve: AppMotion.curveTransition,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.space8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.colorCard : Colors.transparent,
                    borderRadius: AppRadius.chip,
                  ),
                  child: Text(
                    _kRangeLabels[range.index],
                    textAlign: TextAlign.center,
                    style: typography.textBodySmall.copyWith(
                      color: isActive
                          ? AppColors.colorTextPrimary
                          : AppColors.colorTextSecondary,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ─── active view ──────────────────────────────────────────────────────────
  // AnimatedSwitcher fades between views at durationMedium (240ms).
  // Each child carries a ValueKey so Flutter detects the swap correctly.

  Widget _buildActiveView(
    BuildContext context,
    AsyncValue<AdherenceDashboardState> dashboardAsync,
  ) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return AnimatedSwitcher(
      duration: disableAnimations
          ? AppMotion.durationInstant
          : AppMotion.durationMedium,
      switchInCurve: AppMotion.curveTransition,
      switchOutCurve: AppMotion.curveTransition,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey(_activeRange),
        child: switch (_activeRange) {
          _TimeRange.recent => _buildStripView(context, dashboardAsync),
          _TimeRange.monthly => _buildMonthView(context),
          _TimeRange.ninetyDays => _buildTrendView(context),
        },
      ),
    );
  }
  // ─── strip view ───────────────────────────────────────────────────────────
  // Passes riskScores from adherenceProvider to AdherenceStripWidget as a
  // real AsyncValue (via whenData) instead of collapsing loading/error into
  // a single nullable list — the widget can now show a skeleton while
  // loading and a distinct retry state on genuine failure, instead of both
  // cases silently rendering as "section absent."

  Widget _buildStripView(
    BuildContext context,
    AsyncValue<AdherenceDashboardState> dashboardAsync,
  ) {
    final stripAsync = ref.watch(adherenceStripProvider);
    return stripAsync.when(
      loading: () => _buildSkeleton(context, height: 280),
      error: (e, st) => _buildError(context, adherenceStripProvider),
      data: (data) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.viewportMarginHorizontal,
          ),
          child: AdherenceStripWidget(
            data: data,
            riskScoresAsync: dashboardAsync.whenData(
              (state) => state.medicationRiskScores,
            ),
            onRetryRiskScores: () => ref.invalidate(adherenceProvider),
          ),
        );
      },
    );
  }
  // ─── month view ───────────────────────────────────────────────────────────

  Widget _buildMonthView(BuildContext context) {
    final async = ref.watch(adherenceMonthProvider);
    return async.when(
      loading: () => _buildSkeleton(context, height: 320),
      error: (e, st) => _buildError(context, adherenceMonthProvider),
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.viewportMarginHorizontal,
        ),
        child: AdherenceLineChartWidget(data: data),
      ),
    );
  }

  // ─── trend view ───────────────────────────────────────────────────────────

  Widget _buildTrendView(BuildContext context) {
    final async = ref.watch(adherenceTrendProvider);
    return async.when(
      loading: () => _buildSkeleton(context, height: 320),
      error: (e, st) => _buildError(context, adherenceTrendProvider),
      data: (data) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.viewportMarginHorizontal,
        ),
        child: AdherenceTrendChartWidget(data: data),
      ),
    );
  }

  // ─── skeleton ─────────────────────────────────────────────────────────────

  Widget _buildSkeleton(BuildContext context, {required double height}) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: LoadingPulseAnimation(
        isLoading: !disableAnimations,
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.colorSkeleton,
            borderRadius: AppRadius.card,
          ),
        ),
      ),
    );
  }

  // ─── error ────────────────────────────────────────────────────────────────

  Widget _buildError(BuildContext context, ProviderBase provider) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _kErrorHeading,
            style: typography.textHeading2.copyWith(
              color: AppColors.colorTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.space8),
          Text(
            _kErrorBody,
            style: typography.textBody.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.space24),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.buttonHeightPrimary,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.colorPrimary,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
              ),
              onPressed: () => ref.invalidate(provider),
              child: Text(
                _kErrorRetry.toUpperCase(),
                style: typography.textLabel.copyWith(
                  color: AppColors.colorOnPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
