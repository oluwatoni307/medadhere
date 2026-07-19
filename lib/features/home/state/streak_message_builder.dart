// ===
// FILE: streak_message_builder.dart
// LAYER: state (pure helper — no widget, no service, no provider)
// DOMAIN: home
// RESPONSIBLE FOR: Maps StreakSummary + TodaySummary onto the card's
//                  headline sentence + secondary "Next" line. Milestone
//                  copy overrides the normal sentence for one render when
//                  a threshold is crossed. Pure function — same inputs,
//                  same output, always. No randomness, no I/O, no clock
//                  reads (now is passed in).
// RECEIVES: StreakSummary, TodaySummary, DueMedicationEntry? (next dose,
//           nullable — no due entries left today), DateTime now
// RETURNS: StreakCardMessage { headline, secondaryLine, isMilestone }
// CONNECTS TO: streak.dart (StreakDisplayState), home_provider.dart
//              (TodaySummary, DueMedicationEntry)
// MUST NEVER: Call a service, read a provider, touch widget/layout code,
//             or use DateTime.now() internally — now is always injected
// ===

import '../../../shared/models/streak.dart';
import 'home_provider.dart' show TodaySummary, DueMedicationEntry;
import 'streak_notifier.dart';

// ─── Output ────────────────────────────────────────────────────────────────

class StreakCardMessage {
  const StreakCardMessage({
    required this.headline,
    required this.secondaryLine,
    required this.isMilestone,
  });

  /// The card's primary sentence — carries both the streak framing and
  /// today's status in one line. Never contains the word "streak" —
  /// see tone note below.
  final String headline;

  /// The quiet, secondary line — "Next: <med> in <time>",
  /// "Tomorrow: first dose at <time>", or "Today's done." Smaller,
  /// muted styling in the widget — never competes with the headline.
  final String secondaryLine;

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

String _milestoneHeadline(int currentStreakDays) {
  switch (currentStreakDays) {
    case 3:
      return "Three days in. It's starting to become routine.";
    case 7:
      return 'One full week of steady care.';
    case 14:
      return 'Two weeks — this is holding.';
    case 30:
      return 'A month of consistent care. Might be worth checking your refill.';
    case 90:
      return 'Three months, steady. That\'s real continuity of care.';
    default:
      // Unreachable if _isMilestoneDay gated the call, but never throw
      // over copy — fall back to the ordinary active-streak framing.
      return 'On track for $currentStreakDays days.';
  }
}

// ─── Today-status classification ───────────────────────────────────────────

enum _TodayStatus { notStarted, inProgress, complete, missed }

_TodayStatus _classifyToday(TodaySummary today) {
  if (today.total == 0) return _TodayStatus.notStarted;
  if (today.missed > 0) return _TodayStatus.missed;
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
    return StreakCardMessage(
      headline: _milestoneHeadline(streak.currentStreakDays),
      secondaryLine: _secondaryLine(todayStatus, today, nextDose),
      isMilestone: true,
    );
  }

  final headline = _headline(streak, todayStatus, today);
  final secondary = _secondaryLine(todayStatus, today, nextDose);

  return StreakCardMessage(
    headline: headline,
    secondaryLine: secondary,
    isMilestone: false,
  );
}

// ─── Headline grid ──────────────────────────────────────────────────────────

String _headline(
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

String _firstTimeHeadline(_TodayStatus status, TodaySummary today) {
  switch (status) {
    case _TodayStatus.notStarted:
      return today.total == 1
          ? "Let's get started — one dose today."
          : "Let's get started — ${today.total} doses to log today.";
    case _TodayStatus.inProgress:
      return "You're on your way — ${today.logged} down, "
          '${today.total - today.logged} to go.';
    case _TodayStatus.complete:
      return "That's day one done.";
    case _TodayStatus.missed:
      return 'Nothing logged yet, and that\'s okay — '
          'log the next one whenever you\'re ready.';
  }
}

String _lapsedHeadline(
  _TodayStatus status,
  TodaySummary today,
  int lastStreakDays,
) {
  final bestRun = lastStreakDays > 0
      ? ' Your best run was $lastStreakDays days.'
      : '';

  switch (status) {
    case _TodayStatus.notStarted:
      return 'Starting fresh today.$bestRun';
    case _TodayStatus.inProgress:
      return 'Back on track — ${today.logged} down, '
          '${today.total - today.logged} to go.';
    case _TodayStatus.complete:
      return "Day one of a new run, done.$bestRun";
    case _TodayStatus.missed:
      return 'One gap doesn\'t erase the rest — '
          'log the next one when you can.';
  }
}

String _activeHeadline(
  _TodayStatus status,
  TodaySummary today,
  int currentStreakDays,
) {
  final base = 'On track for $currentStreakDays days';

  switch (status) {
    case _TodayStatus.notStarted:
      return '$base.';
    case _TodayStatus.inProgress:
      return '$base — ${today.logged} down, '
          '${today.total - today.logged} to go.';
    case _TodayStatus.complete:
      return today.total == 1
          ? '$base — today\'s done.'
          : '$base — that\'s ${today.total} for ${today.total} today.';
    case _TodayStatus.missed:
      // Deliberately drops the day-count pairing — see tone note above.
      return 'This one slipped — catch it up when you can.';
  }
}

// ─── Secondary line ─────────────────────────────────────────────────────────

String _secondaryLine(
  _TodayStatus status,
  TodaySummary today,
  DueMedicationEntry? nextDose,
) {
  if (status == _TodayStatus.complete) {
    return "Today's done.";
  }

  if (nextDose == null) {
    // No due entries left, but not all logged — likely all remaining
    // slots are more than 12h out or already past the overdue cutoff.
    // Avoid implying nothing is scheduled.
    return today.missed > 0
        ? 'Catch up when you\'re ready.'
        : 'Nothing due right now.';
  }

  return 'Next: ${nextDose.medication.name} in ${nextDose.timeRemaining}';
}
