// ===
// FILE: streak_notifier.dart
// LAYER: state
// DOMAIN: home
// RESPONSIBLE FOR: Derives and exposes a StreakSummary for the home screen
//                  streak display. Aggregates across all medications locally.
//                  No ML service calls. No network dependency.
//                  Also builds the streak card's display copy (headline +
//                  secondary line) from StreakSummary + TodaySummary — pure
//                  functions, no I/O, kept here rather than a separate file
//                  since it's the same domain and directly consumes the
//                  types this file already owns.
// RECEIVES: Ref — reads adherenceFeatureServiceProvider
// RETURNS: AsyncValue<StreakSummary>; StreakCardMessage via
//          buildStreakCardMessage(...)
// CONNECTS TO: AdherenceFeatureService, AdherenceRiskLevel, home_provider.dart
//              (TodaySummary, DueMedicationEntry)
// MUST NEVER: Call repositories directly, import from widget layer,
//             or make network requests
// ===

// packages
import 'package:riverpod_annotation/riverpod_annotation.dart';

// internal — models
import '../../../core/constants/app_constant.dart';
import '../../../shared/models/adherence_feature.dart';
import '../../../shared/models/adherence_risk_score.dart';
import '../../../shared/models/streak.dart';

// internal — services
import '../../../shared/services/adherence/adherence_feature_service_provider.dart';

// internal — state (same domain)
import 'home_provider.dart' show TodaySummary, DueMedicationEntry;

part 'streak_notifier.g.dart';

// ─── View model ───────────────────────────────────────────────────────────────

class StreakSummary {
  const StreakSummary({
    required this.currentStreakDays,
    required this.lastStreakDays,
    required this.streakDisplayState,
    required this.rollingRate7d,
    required this.previousDayAdherence,
    required this.postMissRecoveryRate,
    required this.isColdStart,
    required this.riskLevel,
    required this.showStreakGrowthChip,
  });

  final int currentStreakDays;
  final int lastStreakDays;
  final StreakDisplayState streakDisplayState;
  final double rollingRate7d;
  final double previousDayAdherence;
  final double postMissRecoveryRate;
  final bool isColdStart;
  final AdherenceRiskLevel riskLevel;
  final bool showStreakGrowthChip;

  /// Safe fallback — used when AdherenceFeatureService returns empty list
  /// or throws. Renders as firstTime. No misleading data shown.
  ///
  /// rollingRate7d and previousDayAdherence are 0.0, not 1.0 — this is a
  /// "no doses logged yet" state, not a "fully adherent" state. Displaying
  /// 1.0 here would render as 100% on a cold-start screen, which is the
  /// exact misleading data this fallback exists to avoid.
  static const empty = StreakSummary(
    currentStreakDays: 0,
    lastStreakDays: 0,
    streakDisplayState: StreakDisplayState.firstTime,
    rollingRate7d: 0.0,
    previousDayAdherence: 0.0,
    postMissRecoveryRate: 0.0,
    isColdStart: true,
    riskLevel: AdherenceRiskLevel.onTrack,
    showStreakGrowthChip: false,
  );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

@riverpod
class StreakNotifier extends _$StreakNotifier {
  @override
  AsyncValue<StreakSummary> build() {
    _init();
    return const AsyncValue.loading();
  }

  // FIX: guard against writing to `state` after this provider has been
  // disposed (autodispose can tear this provider down while `_fetchStreak`
  // is still mid-flight — e.g. during a brief watcher gap around
  // navigation). Without this check, resuming after the await throws
  // "Cannot use the Ref of streakProvider after it has been disposed,"
  // the state write never happens, and the streak card silently keeps
  // showing its previous value even though the underlying data changed.
  Future<void> _init() async {
    final result = await AsyncValue.guard(_fetchStreak);
    if (ref.mounted) {
      state = result;
    }
  }

  Future<void> loadStreak() async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(_fetchStreak);
    if (ref.mounted) {
      state = result;
    }
  }

  Future<StreakSummary> _fetchStreak() async {
    final features = await ref
        .read(adherenceFeatureServiceProvider)
        .computeAllFeatures(AppConstants.placeholderUserId);

    // No features at all — user has no medications registered.
    if (features.isEmpty) return StreakSummary.empty;

    // Features exist but none have any real dose history.
    // Guards against orphaned Firestore documents from deleted medications
    // or features computed before any dose has been logged.
    // A feature is considered "never started" when all four signals are zero —
    // no treatment days elapsed, no streak ever built, and no 7d rate recorded.
    final hasAnyHistory = features.any(
      (f) =>
          f.daysSinceTreatmentStart > 0 ||
          f.currentStreakDays > 0 ||
          f.lastStreakDays > 0 ||
          f.rollingRate7d > 0.0,
    );
    if (!hasAnyHistory) return StreakSummary.empty;

    return _deriveStreakSummary(features);
  }
}

// ─── Derivation ───────────────────────────────────────────────────────────────

StreakSummary _deriveStreakSummary(List<AdherenceFeature> features) {
  final streak = _minStreak(features);
  final lastStreak = _minLastStreak(features);
  final rate7d = _avgRollingRate7d(features);
  final prevDay = _avgPreviousDayAdherence(features);
  final recovery = _avgPostMissRecoveryRate(features);
  final coldStart = _anyColdStart(features);
  final riskLevel = _deriveRiskLevel(rate7d, coldStart);
  final displayState = _deriveDisplayState(streak, features);
  final showChip = _deriveShowGrowthChip(
    currentStreakDays: streak,
    previousDayAdherence: prevDay,
    isColdStart: coldStart,
  );

  return StreakSummary(
    currentStreakDays: streak,
    lastStreakDays: lastStreak,
    streakDisplayState: displayState,
    rollingRate7d: rate7d,
    previousDayAdherence: prevDay,
    postMissRecoveryRate: recovery,
    isColdStart: coldStart,
    riskLevel: riskLevel,
    showStreakGrowthChip: showChip,
  );
}

// ─── Aggregation helpers ──────────────────────────────────────────────────────
//
// Streak uses minimum — the streak is only as strong as the weakest medication.
// Last streak uses minimum — same principle, weakest chain.
// Rates use average — a fair cross-medication picture.
// Cold start uses any — one cold-start medication is enough to flag the user
// as early-stage. Avoids false confidence.

int _minStreak(List<AdherenceFeature> features) =>
    features.map((f) => f.currentStreakDays).reduce((a, b) => a < b ? a : b);

int _minLastStreak(List<AdherenceFeature> features) =>
    features.map((f) => f.lastStreakDays).reduce((a, b) => a < b ? a : b);

double _avgRollingRate7d(List<AdherenceFeature> features) =>
    features.map((f) => f.rollingRate7d).reduce((a, b) => a + b) /
    features.length;

double _avgPreviousDayAdherence(List<AdherenceFeature> features) =>
    features.map((f) => f.previousDayAdherence).reduce((a, b) => a + b) /
    features.length;

double _avgPostMissRecoveryRate(List<AdherenceFeature> features) =>
    features.map((f) => f.postMissRecoveryRate).reduce((a, b) => a + b) /
    features.length;

bool _anyColdStart(List<AdherenceFeature> features) =>
    features.any((f) => f.isColdStart);

// ─── Display state derivation ─────────────────────────────────────────────────
//
// firstTime — no medication has any dose history at all
// lapsed    — history exists but current streak is zero
// active    — streak is alive (>= 1)
//
// firstTime and lapsed intentionally produce different layouts and copy
// even though both show no streak number. The emotional context is different.

StreakDisplayState _deriveDisplayState(
  int currentStreakDays,
  List<AdherenceFeature> features,
) {
  // A feature has real history only when treatment has been active for at
  // least one day AND at least one dose has been logged. Checking both fields
  // prevents a medication created today (daysSinceTreatmentStart == 0) or an
  // orphaned document (no logged doses) from being treated as lapsed.
  final allNeverStarted = features.every(
    (f) =>
        f.daysSinceTreatmentStart == 0 &&
        f.currentStreakDays == 0 &&
        f.lastStreakDays == 0 &&
        f.rollingRate7d == 0.0,
  );
  if (allNeverStarted) return StreakDisplayState.firstTime;
  if (currentStreakDays == 0) return StreakDisplayState.lapsed;
  return StreakDisplayState.active;
}

// ─── Risk level proxy ─────────────────────────────────────────────────────────
//
// Local substitute for ML scoring. Uses 7-day rolling rate as the signal.
// Cold start always resolves to onTrack — not enough data to flag risk.
// Thresholds:
//   >= 0.80 → onTrack
//   >= 0.50 → atRisk
//   <  0.50 → highRisk

AdherenceRiskLevel _deriveRiskLevel(double rate7d, bool isColdStart) {
  if (isColdStart) return AdherenceRiskLevel.onTrack;
  if (rate7d >= 0.80) return AdherenceRiskLevel.onTrack;
  if (rate7d >= 0.50) return AdherenceRiskLevel.atRisk;
  return AdherenceRiskLevel.highRisk;
}

// ─── Growth chip derivation ───────────────────────────────────────────────────
//
// The chip signals "your streak grew today."
// True when all three conditions hold:
//   1. Yesterday was fully adherent (average across medications == 1.0)
//   2. The streak is alive (currentStreakDays > 0)
//   3. The user is not in cold start (enough history to be meaningful)
//
// On day 1 of a rebuilt streak after a miss:
//   previousDayAdherence == 1.0 ✓  streak == 1 ✓  isColdStart == false ✓
// The chip shows — rebuilding after a miss deserves acknowledgement.

bool _deriveShowGrowthChip({
  required int currentStreakDays,
  required double previousDayAdherence,
  required bool isColdStart,
}) {
  if (isColdStart) return false;
  if (currentStreakDays <= 0) return false;
  return previousDayAdherence >= 1.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// STREAK CARD MESSAGE BUILDER
// Pure functions — no I/O, no clock reads (now is always injected). Turns
// StreakSummary + TodaySummary into the home screen card's display copy.
// Kept in this file rather than a separate one: same domain, and it
// consumes StreakSummary directly above.
// ═══════════════════════════════════════════════════════════════════════════

// ─── Output ────────────────────────────────────────────────────────────

class StreakCardMessage {
  const StreakCardMessage({
    required this.headlineLead,
    required this.headlineDetail,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.isMilestone,
  });

  /// The card's primary clause — plain-colored, first line. Never
  /// contains the word "streak" — see tone note below.
  final String headlineLead;

  /// The second clause, rendered in accent color on its own line when
  /// present. Null for genuinely single-clause states — those render
  /// [headlineLead] alone rather than forcing an artificial split.
  final String? headlineDetail;

  /// Left-aligned label for the secondary line — "Next", "Tomorrow", or
  /// null when there's no label/value split (e.g. "Today's done." reads
  /// as one plain sentence, not a label + value pair).
  final String? secondaryLabel;

  /// Right-aligned value for the secondary line when [secondaryLabel] is
  /// present ("Metformin in 2h 50m"). When [secondaryLabel] is null, this
  /// is the entire secondary line's text, rendered alone.
  final String secondaryValue;

  /// True when this render is a one-time milestone moment (3/7/14/30/90
  /// days). The widget uses this to apply the distinct-but-restrained
  /// milestone visual treatment for this render only — never a permanent
  /// fixture, same spirit as [StreakSummary.showStreakGrowthChip].
  final bool isMilestone;
}

// ─── Tone note ────────────────────────────────────────────────────────────
//
// This app is medication adherence, not habit gamification. Research on
// patient attitudes toward gamified adherence apps flags "trivialization"
// as a real, named concern when health routines are framed as games or
// streaks-for-their-own-sake. Two hard rules follow from that, enforced
// here rather than left to whoever edits copy later:
//
//   1. The word "streak" never appears in user-facing text. Continuity is
//      described in plain terms ("days of steady care", "on track for
//      N days") instead of borrowed game vocabulary.
//   2. A missed-dose headline never states the day-count in the same
//      sentence as the miss. Pairing "day 12" with "you missed one" turns
//      a logistics gap into a loss the user is made to feel. The miss is
//      acknowledged on its own, unweighted by the number next to it.

// ─── Milestone thresholds ──────────────────────────────────────────────────

const List<int> _milestoneDays = [3, 7, 14, 30, 90];

bool _isMilestoneDay(int currentStreakDays) =>
    _milestoneDays.contains(currentStreakDays);

({String lead, String? detail}) _milestoneHeadline(int currentStreakDays) {
  switch (currentStreakDays) {
    case 3:
      return (
        lead: "Three days in. It's starting to become routine.",
        detail: null,
      );
    case 7:
      return (lead: 'One full week of steady care.', detail: null);
    case 14:
      return (lead: 'Two weeks — this is holding.', detail: null);
    case 30:
      return (
        lead: 'A month of consistent care.',
        detail: 'Might be worth checking your refill.',
      );
    case 90:
      return (
        lead: 'Three months, steady.',
        detail: "That's real continuity of care.",
      );
    default:
      // Unreachable if _isMilestoneDay gated the call, but never throw
      // over copy — fall back to the ordinary active-streak framing.
      return (lead: 'On track for $currentStreakDays days.', detail: null);
  }
}

// ─── Today-status classification ───────────────────────────────────────────

enum _TodayStatus { notStarted, inProgress, complete, missed }

_TodayStatus _classifyToday(TodaySummary today) {
  if (today.total == 0) return _TodayStatus.notStarted;
  // Overdue is checked alongside missed — an unresolved overdue dose is
  // not the same clinical fact as a finalized miss, but for the card's
  // purposes both mean "something needs attention today," and neither
  // should render as if today hasn't started yet.
  if (today.missed > 0 || today.overdue > 0) return _TodayStatus.missed;
  if (today.logged >= today.total) return _TodayStatus.complete;
  if (today.logged > 0) return _TodayStatus.inProgress;
  return _TodayStatus.notStarted;
}

// ─── Builder ────────────────────────────────────────────────────────────────

StreakCardMessage buildStreakCardMessage({
  required StreakSummary streak,
  required TodaySummary today,
  required DueMedicationEntry? nextDose,
  required DateTime now,
}) {
  final todayStatus = _classifyToday(today);

  // Milestone takes priority over the normal grid, but only on an
  // otherwise-neutral or positive today — a missed dose today should
  // never be masked by celebratory milestone copy.
  final showMilestone =
      streak.showStreakGrowthChip &&
      _isMilestoneDay(streak.currentStreakDays) &&
      todayStatus != _TodayStatus.missed;

  if (showMilestone) {
    final headline = _milestoneHeadline(streak.currentStreakDays);
    final secondary = _secondary(todayStatus, today, nextDose);
    return StreakCardMessage(
      headlineLead: headline.lead,
      headlineDetail: headline.detail,
      secondaryLabel: secondary.label,
      secondaryValue: secondary.value,
      isMilestone: true,
    );
  }

  final headline = _headline(streak, todayStatus, today);
  final secondary = _secondary(todayStatus, today, nextDose);

  return StreakCardMessage(
    headlineLead: headline.lead,
    headlineDetail: headline.detail,
    secondaryLabel: secondary.label,
    secondaryValue: secondary.value,
    isMilestone: false,
  );
}

// ─── Headline grid ──────────────────────────────────────────────────────────
//
// Every headline is a (lead, detail) pair, not one flat sentence. Matches
// the original mockup: lead renders plain, detail renders in accent color
// on its own line. detail is null for genuinely single-clause states —
// those render as one plain line, no forced split.

({String lead, String? detail}) _headline(
  StreakSummary streak,
  _TodayStatus todayStatus,
  TodaySummary today,
) {
  switch (streak.streakDisplayState) {
    case StreakDisplayState.firstTime:
      return _firstTimeHeadline(todayStatus, today);
    case StreakDisplayState.lapsed:
      return _lapsedHeadline(todayStatus, today, streak.lastStreakDays);
    case StreakDisplayState.active:
      return _activeHeadline(todayStatus, today, streak.currentStreakDays);
  }
}

({String lead, String? detail}) _firstTimeHeadline(
  _TodayStatus status,
  TodaySummary today,
) {
  switch (status) {
    case _TodayStatus.notStarted:
      return (
        lead: "Let's get started",
        detail: today.total == 1
            ? 'One dose today.'
            : '${today.total} doses to log today.',
      );
    case _TodayStatus.inProgress:
      return (
        lead: "You're on your way",
        detail: '${today.logged} down, ${today.total - today.logged} to go.',
      );
    case _TodayStatus.complete:
      return (lead: "That's day one done.", detail: null);
    case _TodayStatus.missed:
      return (
        lead: 'Nothing logged yet, and that\'s okay',
        detail: 'Log the next one whenever you\'re ready.',
      );
  }
}

({String lead, String? detail}) _lapsedHeadline(
  _TodayStatus status,
  TodaySummary today,
  int lastStreakDays,
) {
  final bestRun = lastStreakDays > 0
      ? 'Your best run was $lastStreakDays days.'
      : null;

  switch (status) {
    case _TodayStatus.notStarted:
      return (lead: 'Starting fresh today.', detail: bestRun);
    case _TodayStatus.inProgress:
      return (
        lead: 'Back on track',
        detail: '${today.logged} down, ${today.total - today.logged} to go.',
      );
    case _TodayStatus.complete:
      return (lead: "Day one of a new run, done.", detail: bestRun);
    case _TodayStatus.missed:
      return (
        lead: 'One gap doesn\'t erase the rest',
        detail: 'Log the next one when you can.',
      );
  }
}

({String lead, String? detail}) _activeHeadline(
  _TodayStatus status,
  TodaySummary today,
  int currentStreakDays,
) {
  final lead = 'On track for $currentStreakDays days';

  switch (status) {
    case _TodayStatus.notStarted:
      return (lead: lead, detail: null);
    case _TodayStatus.inProgress:
      return (
        lead: lead,
        detail: '${today.logged} down, ${today.total - today.logged} to go.',
      );
    case _TodayStatus.complete:
      return (
        lead: lead,
        detail: today.total == 1
            ? "Today's done."
            : 'That\'s ${today.total} for ${today.total} today.',
      );
    case _TodayStatus.missed:
      // Deliberately drops the day-count pairing — see tone note above.
      // Single clause, no lead/detail split — pairing "this slipped" with
      // its own accent-colored follow-up would visually separate two
      // halves of what should read as one gentle acknowledgment.
      return (
        lead: 'This one slipped — catch it up when you can.',
        detail: null,
      );
  }
}

// ─── Secondary line ─────────────────────────────────────────────────────────

/// Returns the secondary line as a (label, value) pair. label is null for
/// single-sentence states ("Today's done.") — the widget renders those as
/// one plain line, right-aligned, with no label column. label is "Next"
/// for an actual upcoming/overdue dose, matching the two-column mockup:
/// label pinned left, value pinned right.
({String? label, String value}) _secondary(
  _TodayStatus status,
  TodaySummary today,
  DueMedicationEntry? nextDose,
) {
  if (status == _TodayStatus.complete) {
    return (label: null, value: "Today's done.");
  }

  if (nextDose == null) {
    // No due entries left, but not all logged — likely all remaining
    // slots are more than 12h out or already past the overdue cutoff.
    // Avoid implying nothing is scheduled.
    return (
      label: null,
      value: today.missed > 0
          ? 'Catch up when you\'re ready.'
          : 'Nothing due right now.',
    );
  }

  // timeRemaining can be the literal string 'Overdue' (see home_provider.dart
  // _fetchDue) rather than a duration like '2h 50m' — the 'Next: X in Y'
  // template only makes grammatical sense for a duration. Overdue gets its
  // own phrasing instead of silently producing "in Overdue".
  if (nextDose.timeRemaining == 'Overdue') {
    return (label: 'Next', value: '${nextDose.medication.name} — overdue');
  }

  return (
    label: 'Next',
    value: '${nextDose.medication.name} in ${nextDose.timeRemaining}',
  );
}
