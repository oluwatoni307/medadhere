// ============================================
// FILE: _adherence_line_chart_widget.dart
// LAYER: widget
// DOMAIN: adherence
// RESPONSIBLE FOR: Renders the 30-day aggregate daily completion rate line chart.
//                  Two stat cards above. Line chart below with colored data points.
//                  One quiet trend sentence. Insight card at the bottom.
// RECEIVES: data: AdherenceMonthData
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

class AdherenceLineChartWidget extends StatelessWidget {
  const AdherenceLineChartWidget({super.key, required this.data});

  final AdherenceMonthData data;

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
    // Bug 2 fix: removed unused `typography` variable that was declared
    // but never referenced — _StatCard handles its own typography internally.
    final rateColor = _rateColor(data.averageRate);
    final avgPct = (data.averageRate * 100).round();

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
            label: 'Weakest day',
            value: data.worstDayOfWeek,
            unit: '',
            valueColor: AppColors.colorTextPrimary,
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
      // Bug (overflow) fix: wrap in ClipRect so fl_chart cannot paint outside
      // its box. Height increased to 200 so axis title insets do not compress
      // the drawable canvas and push dots into the overflow zone.
      child: ClipRect(
        child: SizedBox(height: 200, child: LineChart(_buildLineChartData())),
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = data.dailyRates.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        (entry.value.rate * 100).roundToDouble(),
      );
    }).toList();

    return LineChartData(
      // Bug (overflow) fix: maxY capped at 100 — adherence cannot exceed 100%.
      // minY set to 0 for honest scale. clipData ensures nothing renders
      // outside the plot area even if a dot sits exactly at the boundary.
      minY: 0,
      maxY: 100,
      clipData: const FlClipData.all(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: AppColors.colorBorder, strokeWidth: 0.5),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
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
              if (idx == 0) return _axisLabel('Day 1');
              if (idx == 6) return _axisLabel('Wk 2');
              if (idx == 13) return _axisLabel('Wk 3');
              if (idx == 20) return _axisLabel('Wk 4');
              if (idx == 27) return _axisLabel('Wk 5');
              return const SizedBox.shrink();
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: AppColors.colorStateConsistent,
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            // Bug 1 fix: duplicate wildcard parameter names replaced with
            // unique names so this compiles. percent/barData/index unused
            // but must be distinct identifiers in Dart.
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                  radius: 3,
                  color: _rateColor(spot.y / 100),
                  strokeWidth: 0,
                  strokeColor: Colors.transparent,
                ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.colorStateConsistent.withOpacity(0.06),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (spots) => spots.map((s) {
            return LineTooltipItem(
              '${s.y.toInt()}%',
              TextStyle(
                color: _rateColor(s.y / 100),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
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

  String _trendSentence() {
    if (data.worstDayOfWeek.isEmpty) return 'Keep logging to see your pattern.';
    // Bug 3 fix: removed hardcoded "evening" — worst time of day is not
    // known at this layer so the sentence is kept factual only.
    return '${data.worstDayOfWeek}s account for most of your misses.';
  }

  // ─── insight card ─────────────────────────────────────────────────────────

  Widget _buildInsightCard(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final isSlipping = data.averageRate < _kRateWarning;
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
    if (data.averageRate >= _kRateGood) {
      return 'You averaged $pct% this month — '
          'your consistency is building into a reliable habit.';
    }
    if (data.averageRate >= _kRateWarning) {
      return 'You averaged $pct% this month. '
          '${data.worstDayOfWeek}s are where the pattern slips most.';
    }
    return 'This month averaged $pct%. '
        'A few small changes on ${data.worstDayOfWeek}s '
        'could move that number meaningfully.';
  }

  String _insightAction() {
    if (data.averageRate >= _kRateGood) {
      return '${data.bestDayOfWeek} is your strongest day. '
          'Keep anchoring your routine there.';
    }
    // Bug 3 fix: removed hardcoded "evening" — the data model does not
    // expose time-of-day context at this layer so we keep the action
    // factual without assuming when the miss occurs.
    return 'Try setting a ${data.worstDayOfWeek} reminder to close the gap.';
  }

  // ─── helpers ──────────────────────────────────────────────────────────────

  Color _rateColor(double rate) {
    if (rate >= _kRateGood) return AppColors.colorStateConsistent;
    if (rate >= _kRateWarning) return AppColors.colorStateSlipping;
    return AppColors.colorStateRisk;
  }
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
