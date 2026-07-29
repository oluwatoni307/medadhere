// ===
// FILE: home_screen.dart
// LAYER: screen
// DOMAIN: features/home
// RESPONSIBLE FOR: Home tab screen — renders greeting header, streak display,
//                  and today's due medication list across all five states
//                  with pull-to-refresh.
// RECEIVES: nothing — all data read from HomeNotifier, StreakNotifier, and
//           TodaySummaryNotifier
// RETURNS: nothing
// CONNECTS TO: AppColors, AppSpacing, AppRadius, AppTypography, AppMotion,
//              HomeNotifier, StreakNotifier, TodaySummaryNotifier,
//              HomeMedicationCard, StreakDisplayWidget,
//              LoadingPulseAnimation, DoseLogConfirmationAnimation
// MUST NEVER: Call repositories, services, or Firebase SDKs directly.
//             Hardcode any hex, dp, sp, duration, or radius value.
//             Implement AnimationController.
//             Derive urgency tier or format time remaining.
//             Build streak card copy directly — that belongs in
//             buildStreakCardMessage (streak_notifier.dart), this file
//             only assembles inputs and hands them off.
// ===

// flutter
import 'package:flutter/material.dart';

// packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// internal — theme
import 'package:medadhere/core/theme/app_colors.dart';
import 'package:medadhere/core/theme/app_spacing.dart';
import 'package:medadhere/core/theme/app_radius.dart';
import 'package:medadhere/core/theme/app_typography.dart';
import 'package:medadhere/core/theme/app_motion.dart';
import 'package:medadhere/core/theme/app_animations.dart';

// internal — state
import 'package:medadhere/features/home/state/home_provider.dart';
import 'package:medadhere/features/home/state/streak_notifier.dart';
import 'package:medadhere/shared/utils/time_parser.dart';

import '../../../components/Medication_card_variant.dart';
import '../../../components/streak_counter.dart';
// NOTE: this import previously pointed at streak_counter.dart. Flagging,
// not silently resolving — confirm whether StreakDisplayWidget's real
// production file is streak_display_widget.dart (as built) or whether
// streak_counter.dart is the actual filename and should be updated to
// match instead. Left pointing at the path used throughout this redesign
// pending that confirmation.

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  bool _hasLoggedBefore = false;

  // ─── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _onLogTapped(DueMedicationEntry entry) async {
    final providerState = ref.read(homeProvider);
    if (providerState.hasValue) {
      final index = providerState.value!.indexWhere(
        (e) =>
            e.medication.id == entry.medication.id &&
            e.scheduledTime == entry.scheduledTime,
      );
      if (index != -1) {
        _listKey.currentState?.removeItem(
          index,
          (context, animation) => _removingCard(entry, animation),
          duration: AppMotion.durationMedium,
        );
        setState(() => _hasLoggedBefore = true);
      }
    }

    await context.pushNamed(
      'logDose',
      extra: {
        'medicationId': entry.medication.id,
        'medicationName': entry.medication.name,
        'doseAmount': entry.medication.dosage,
        'scheduleLabel': entry.scheduleLabel,
        'scheduleId': entry.medication.id,
        'scheduledTimeMs': entry.scheduledTime.millisecondsSinceEpoch,
        'slotId': TimeParser.buildSlotId(
          entry.medication.id,
          entry.scheduledTime,
        ),
      },
    );

    if (mounted) {
      ref.read(homeProvider.notifier).loadDueMedications();
      ref.read(streakProvider.notifier).loadStreak();
      // Today's tally can change from this single log action (a dose that
      // was due today just moved from pending to logged) — invalidate
      // alongside the other two so the card never shows stale counts.
      ref.invalidate(todaySummaryProvider);
    }
  }

  Future<void> _onRefresh() async {
    ref.invalidate(todaySummaryProvider);
    await Future.wait([
      ref.read(homeProvider.notifier).loadDueMedications(),
      ref.read(streakProvider.notifier).loadStreak(),
      ref.read(todaySummaryProvider.future),
    ]);
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dueState = ref.watch(homeProvider);
    final streakState = ref.watch(streakProvider);
    final todayState = ref.watch(todaySummaryProvider);
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final double width = MediaQuery.of(context).size.width;
    final double horizontalPadding = width < 360
        ? AppSpacing.space12
        : AppSpacing.viewportMarginHorizontal;

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: AppColors.colorPrimary,
          backgroundColor: AppColors.colorCard,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _headerSliver(
                context,
                dueState,
                streakState,
                todayState,
                horizontalPadding,
              ),
              _contentSliver(
                context,
                dueState,
                horizontalPadding,
                reduceMotion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Slivers ─────────────────────────────────────────────────────────────────

  Widget _headerSliver(
    BuildContext context,
    AsyncValue<List<DueMedicationEntry>> dueState,
    AsyncValue<StreakSummary> streakState,
    AsyncValue<TodaySummary> todayState,
    double horizontalPadding,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final medications = dueState.value ?? [];

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.space24,
        horizontalPadding,
        AppSpacing.space20,
      ),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Date
            Text(
              _todayDate(),
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorTextTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.space4),

            // Greeting
            Text(
              _greeting(),
              style: typography.textDisplay.copyWith(
                color: AppColors.colorTextPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),

            // Dose count — only when list is loaded and non-empty
            if (dueState.hasValue && medications.isNotEmpty)
              Text(
                medications.length == 1
                    ? 'You have 1 dose to take today.'
                    : 'You have ${medications.length} doses to take today.',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

            const SizedBox(height: AppSpacing.space24),

            // Streak block — independent loading state
            _streakBlock(context, dueState, streakState, todayState),
          ],
        ),
      ),
    );
  }

  // ─── Streak block ────────────────────────────────────────────────────────────
  //
  // Loading → skeleton pulse sized to match the card's natural content height.
  // Any source still loading with no prior value → skeleton, not a partial
  //   or misleading render — the headline fuses streak + today, so a half-
  //   loaded state would show one true fact stitched to a placeholder.
  // Error   → falls back to each source's own .empty state; card always
  //   renders, never disappears.
  // Data    → all three sources resolved (or safely defaulted), message
  //   built once via buildStreakCardMessage, passed to StreakDisplayWidget.

  Widget _streakBlock(
    BuildContext context,
    AsyncValue<List<DueMedicationEntry>> dueState,
    AsyncValue<StreakSummary> streakState,
    AsyncValue<TodaySummary> todayState,
  ) {
    final streakLoading = streakState.isLoading && !streakState.hasValue;
    final todayLoading = todayState.isLoading && !todayState.hasValue;

    if (streakLoading || todayLoading) {
      return _streakSkeleton();
    }

    final streak = streakState.value ?? StreakSummary.empty;
    final today = todayState.value ?? TodaySummary.empty;
    // dueState may still be loading independently of the streak card's own
    // sources — a null/empty next dose degrades gracefully in the message
    // builder ("Nothing due right now") rather than blocking the card.
    final nextDose = (dueState.value ?? const []).isNotEmpty
        ? dueState.value!.first
        : null;

    final message = buildStreakCardMessage(
      streak: streak,
      today: today,
      nextDose: nextDose,
      now: DateTime.now(),
    );

    return StreakDisplayWidget(message: message);
  }

  // Skeleton uses an IntrinsicHeight-friendly fixed height that matches the
  // card's rendered content height at default text scale to avoid layout jump.
  Widget _streakSkeleton() {
    return LoadingPulseAnimation(
      isLoading: true,
      child: Container(
        width: double.infinity,
        height: AppSpacing.space48 * 2.5,
        decoration: BoxDecoration(
          color: AppColors.colorSkeleton,
          borderRadius: AppRadius.card,
        ),
      ),
    );
  }

  // ─── Content sliver ──────────────────────────────────────────────────────────

  Widget _contentSliver(
    BuildContext context,
    AsyncValue<List<DueMedicationEntry>> state,
    double horizontalPadding,
    bool reduceMotion,
  ) {
    if (state.isLoading) return _loadingSliver(context, horizontalPadding);
    if (state.hasError) return _errorSliver(context, horizontalPadding);

    final medications = state.value ?? [];

    if (medications.isNotEmpty) {
      return _populatedSliver(context, medications, horizontalPadding);
    }
    if (_hasLoggedBefore) {
      return _allLoggedSliver(context, horizontalPadding, reduceMotion);
    }
    return _emptySliver(context, horizontalPadding);
  }

  // ─── State 01: populated ─────────────────────────────────────────────────────

  Widget _populatedSliver(
    BuildContext context,
    List<DueMedicationEntry> medications,
    double horizontalPadding,
  ) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        0,
        horizontalPadding,
        AppSpacing.space40,
      ),
      sliver: SliverAnimatedList(
        key: _listKey,
        initialItemCount: medications.length,
        itemBuilder: (context, index, animation) {
          return _animatedCard(medications[index], animation);
        },
      ),
    );
  }

  Widget _animatedCard(DueMedicationEntry entry, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.curveTransition,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space12),
        child: HomeMedicationCard(
          medicationName: entry.medication.name,
          dosage: entry.medication.dosage,
          timeRemaining: entry.timeRemaining,
          urgencyTier: entry.urgencyTier,
          onLogDose: () => _onLogTapped(entry),
        ),
      ),
    );
  }

  Widget _removingCard(DueMedicationEntry entry, Animation<double> animation) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: ReverseAnimation(animation),
        curve: AppMotion.curveTransition,
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.space12),
        child: HomeMedicationCard(
          medicationName: entry.medication.name,
          dosage: entry.medication.dosage,
          timeRemaining: entry.timeRemaining,
          urgencyTier: entry.urgencyTier,
          onLogDose: () {},
        ),
      ),
    );
  }

  // ─── State 02: all logged ────────────────────────────────────────────────────

  Widget _allLoggedSliver(
    BuildContext context,
    double horizontalPadding,
    bool reduceMotion,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final duration = reduceMotion
        ? AppMotion.durationInstant
        : AppMotion.durationTransition;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: duration,
          curve: AppMotion.curveStandard,
          builder: (context, value, child) =>
              Opacity(opacity: value, child: child),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: AppSpacing.space48,
                color: AppColors.colorStateConsistent,
              ),
              const SizedBox(height: AppSpacing.space16),
              Text(
                'You\'re all done for now.',
                style: typography.textHeading1.copyWith(
                  color: AppColors.colorTextPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.space8),
              Text(
                'Every dose for today has been logged. Well done.',
                style: typography.textBody.copyWith(
                  color: AppColors.colorTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── State 03: loading ───────────────────────────────────────────────────────

  Widget _loadingSliver(BuildContext context, double horizontalPadding) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: SliverToBoxAdapter(
        child: Semantics(
          label: 'Loading your medications. Please wait.',
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (_) => _cardSkeleton()),
          ),
        ),
      ),
    );
  }

  Widget _cardSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space12),
      child: LoadingPulseAnimation(
        isLoading: true,
        child: Container(
          width: double.infinity,
          height: AppSpacing.space48 * 2,
          decoration: BoxDecoration(
            color: AppColors.colorSkeleton,
            borderRadius: AppRadius.card,
          ),
        ),
      ),
    );
  }

  // ─── State 04: error ─────────────────────────────────────────────────────────

  Widget _errorSliver(BuildContext context, double horizontalPadding) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Couldn\'t load your medications.',
              style: typography.textHeading1.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Check your connection and try again.',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space16),
            _primaryButton(
              typography: typography,
              label: 'Try Again',
              onTap: _onRefresh,
            ),
          ],
        ),
      ),
    );
  }

  // ─── State 05: empty ─────────────────────────────────────────────────────────

  Widget _emptySliver(BuildContext context, double horizontalPadding) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Nothing here yet.',
              style: typography.textHeading1.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Add your first medication to start tracking your doses.',
              style: typography.textBody.copyWith(
                color: AppColors.colorTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space16),
            Semantics(
              label: 'Add a new medication',
              child: _primaryButton(
                typography: typography,
                label: 'Add a Medication',
                onTap: () => context.pushNamed('addMedication'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared button ───────────────────────────────────────────────────────────

  Widget _primaryButton({
    required AppTypography typography,
    required String label,
    required VoidCallback onTap,
  }) {
    return DoseLogConfirmationAnimation(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(
          minHeight: AppSpacing.buttonHeightPrimary,
        ),
        decoration: BoxDecoration(
          color: AppColors.colorPrimary,
          borderRadius: AppRadius.button,
        ),
        child: Center(
          child: Text(
            label,
            style: typography.textLabel.copyWith(
              color: AppColors.colorOnPrimary,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Private utils ───────────────────────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning.';
    if (hour < 17) return 'Good afternoon.';
    return 'Good evening.';
  }

  String _todayDate() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}
