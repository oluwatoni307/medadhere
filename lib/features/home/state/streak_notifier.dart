// ===
// FILE: streak_notifier.dart
// LAYER: state
// DOMAIN: home
// RESPONSIBLE FOR: Derives and exposes a StreakSummary for the home screen
//                  streak display. Aggregates across all medications locally.
//                  No ML service calls. No network dependency.
// RECEIVES: Ref — reads adherenceFeatureServiceProvider
// RETURNS: AsyncValue<StreakSummary>
// CONNECTS TO: AdherenceFeatureService, AdherenceRiskLevel
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
  static const empty = StreakSummary(
    currentStreakDays: 0,
    lastStreakDays: 0,
    streakDisplayState: StreakDisplayState.firstTime,
    rollingRate7d: 1.0,
    previousDayAdherence: 1.0,
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

  Future<void> _init() async {
    state = await AsyncValue.guard(_fetchStreak);
  }

  Future<void> loadStreak() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchStreak);
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
