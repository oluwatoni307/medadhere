// ============================================
// FILE: _adherence_trend_chart_widget.dart
// LAYER: widget
// DOMAIN: adherence
// RESPONSIBLE FOR: Renders the 90-day aggregate weekly completion rate bar chart.
//                  Two stat cards above. 13-bar chart below — each bar colored
//                  by its weekly rate. Trend sentence. Insight card.
// RECEIVES: data: AdherenceTrendData
// RETURNS: Column — stat cards + chart card + trend sentence + insight card
// CONNECTS TO: adherence_visualization_screen.dart,
//              adherence_visualization_models.dart
// MUST NEVER: watch any provider, declare providers, call routing,
//             hardcode any value, contain business logic
// ============================================

// flutter
import 'package:flutter/material.dart';
// packages
import 'package:fl_chart/fl_chart.dart';
// models
import '../../../shared/models/adherence_visualization_models.dart';
// theme
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_animations.dart';

// ─── thresholds ───────────────────────────────────────────────────────────────

const double _kRateGood = 0.85;
const double _kRateWarning = 0.70;

// ─── widget ───────────────────────────────────────────────────────────────────

class AdherenceTrendChartWidget extends StatelessWidget {
  const AdherenceTrendChartWidget({super.key, required this.data});

  final AdherenceTrendData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatCards(context),
        const SizedBox(height: AppSpacing.space16),
        _buildChartCard(context),
        const SizedBox(height: AppSpacing.space16),
        _buildTrendSentence(context),
        const SizedBox(height: AppSpacing.space20),
        _buildInsightCard(context),
      ],
    );
  }

  // ─── stat cards ───────────────────────────────────────────────────────────

  Widget _buildStatCards(BuildContext context) {
    final rateColor = _rateColor(data.averageRate);
    final avgPct = (data.averageRate * 100).round();
    final trendLabel = _trendLabel(data.trendDirection);
    final trendColor = _trendColor(data.trendDirection);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Avg rate',
            value: '$avgPct',
            unit: '%',
            valueColor: rateColor,
          ),
        ),
        const SizedBox(width: AppSpacing.space10),
        Expanded(
          child: _StatCard(
            label: 'Trend',
            value: trendLabel,
            unit: '',
            valueColor: trendColor,
            valueFontSize: 16,
          ),
        ),
      ],
    );
  }

  // ─── chart card ───────────────────────────────────────────────────────────

  Widget _buildChartCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space12,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space12,
      ),
      // Bug 1 fix: wrap in ClipRect so fl_chart cannot paint outside its box.
      // Height kept at 200 — bar charts do not have dot overflow like line
      // charts but ClipRect is still the correct hard boundary.
      child: ClipRect(
        child: SizedBox(height: 200, child: BarChart(_buildBarChartData())),
      ),
    );
  }

  BarChartData _buildBarChartData() {
    final groups = data.weeklyRates.asMap().entries.map((entry) {
      final pct = (entry.value.rate * 100).roundToDouble();
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(
            toY: pct,
            color: _rateColor(entry.value.rate),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      minY: 0,
      // Bug 1 fix: maxY capped at 100 — adherence cannot exceed 100%.
      // Using 105 was semantically wrong and compressed the canvas,
      // pushing bars toward overflow.
      maxY: 100,
      barGroups: groups,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.colorBorder, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 25,
            reservedSize: 32,
            getTitlesWidget: (value, _) => Text(
              '${value.toInt()}%',
              style: const TextStyle(fontSize: 10, color: Color(0xFF9A9690)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, _) {
              final idx = value.toInt();
              if (idx == 0) return _axisLabel('W1');
              if (idx == 3) return _axisLabel('W4');
              if (idx == 6) return _axisLabel('W7');
              if (idx == 9) return _axisLabel('W10');
              if (idx == 12) return _axisLabel('W13');
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          // Bug 2 fix: duplicate wildcard parameter names replaced with unique
          // names. groupIndex/rodIndex unused but must be distinct identifiers.
          getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
            'W${group.x + 1}\n${rod.toY.toInt()}%',
            TextStyle(
              color: _rateColor(rod.toY / 100),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _axisLabel(String text) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, color: Color(0xFF9A9690)),
    ),
  );

  // ─── trend sentence ───────────────────────────────────────────────────────

  Widget _buildTrendSentence(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Text(
      _trendSentence(),
      style: typography.textBody.copyWith(color: AppColors.colorTextSecondary),
    );
  }

  String _trendSentence() => switch (data.trendDirection) {
    TrendDirection.improving =>
      'You are taking more doses consistently than you were three months ago.',
    TrendDirection.stable =>
      'Your adherence has been steady across the last three months.',
    TrendDirection.declining =>
      'This stretch has been harder — the pattern is worth looking at.',
  };

  // ─── insight card ─────────────────────────────────────────────────────────

  Widget _buildInsightCard(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final isSlipping = data.trendDirection == TrendDirection.declining;
    final borderColor = isSlipping
        ? AppColors.colorStateSlipping
        : AppColors.colorStateConsistent;
    final surfaceColor = isSlipping
        ? AppColors.colorStateSlippingSurface
        : AppColors.colorStateConsistentSurface;
    final eyebrow = isSlipping ? 'Worth knowing' : 'Your pattern';

    return InsightCardRevealAnimation(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: AppRadius.card,
          border: Border(
            left: BorderSide(
              color: borderColor,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              eyebrow.toUpperCase(),
              style: typography.textInsightCardEyebrow.copyWith(
                color: borderColor,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              _insightBody(),
              style: typography.textInsightCardBody.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            Text(
              _insightAction(),
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _insightBody() {
    final pct = (data.averageRate * 100).round();
    final recentWeeks = data.weeklyRates.length >= 4
        ? data.weeklyRates.skip(data.weeklyRates.length - 4).toList()
        : data.weeklyRates;
    final recentAvg = recentWeeks.isEmpty
        ? data.averageRate
        : recentWeeks.map((w) => w.rate).reduce((a, b) => a + b) /
              recentWeeks.length;
    final recentPct = (recentAvg * 100).round();

    return switch (data.trendDirection) {
      TrendDirection.improving =>
        'Your last four weeks averaged $recentPct% — '
            'your strongest stretch in three months.',
      TrendDirection.stable =>
        'You have averaged $pct% over three months. '
            'Consistency at this level is genuinely hard to maintain.',
      TrendDirection.declining =>
        'Your last four weeks averaged $recentPct% — '
            'down from where you were earlier in the period.',
    };
  }

  String _insightAction() => switch (data.trendDirection) {
    TrendDirection.improving =>
      'Keep the morning routine anchored — that is where it started.',
    TrendDirection.stable =>
      'Look at the weeks you scored highest and notice what was different.',
    TrendDirection.declining =>
      'Small recoveries matter. One good week changes the shape of this chart.',
  };

  // ─── helpers ──────────────────────────────────────────────────────────────

  Color _rateColor(double rate) {
    if (rate >= _kRateGood) return AppColors.colorStateConsistent;
    if (rate >= _kRateWarning) return AppColors.colorStateSlipping;
    return AppColors.colorStateRisk;
  }

  String _trendLabel(TrendDirection direction) => switch (direction) {
    TrendDirection.improving => 'Improving',
    TrendDirection.stable => 'Steady',
    TrendDirection.declining => 'Declining',
  };

  Color _trendColor(TrendDirection direction) => switch (direction) {
    TrendDirection.improving => AppColors.colorStateConsistent,
    TrendDirection.stable => AppColors.colorTextPrimary,
    TrendDirection.declining => AppColors.colorStateSlipping,
  };
}

// ─── stat card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.valueColor,
    this.valueFontSize = 22,
  });

  final String label;
  final String value;
  final String unit;
  final Color valueColor;
  final double valueFontSize;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.colorCard,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.space12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: typography.textHeading1.copyWith(
                    color: valueColor,
                    fontSize: valueFontSize,
                  ),
                ),
                if (unit.isNotEmpty)
                  TextSpan(
                    text: unit,
                    style: typography.textCaption.copyWith(
                      color: AppColors.colorTextTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
