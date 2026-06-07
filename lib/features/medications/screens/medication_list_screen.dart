// ============================================
// FILE: medication_list_screen.dart
// PATH: lib/features/medications/screens/medication_list_screen.dart
// DOMAIN: features
// LAYER: screen
// RESPONSIBLE FOR: Renders the medication list screen across four states
//                  with live MedicationNotifier wiring
// RECEIVES: No constructor parameters — all state via providers
// CONNECTS TO: lib/core/theme/app_colors.dart
//              lib/core/theme/app_spacing.dart
//              lib/core/theme/app_radius.dart
//              lib/core/theme/app_motion.dart
//              lib/core/theme/app_typography.dart
//              lib/shared/animations/app_animations.dart
//              lib/features/medications/widgets/medication_due_card.dart
//              lib/features/medications/state/medication_provider.dart
// MUST NEVER: Call repositories, services, Firebase SDKs, declare providers
// ============================================

// flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:medadhere/shared/utils/time_parser.dart';

// design tokens
import '../../../components/medication_card.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_typography.dart';

// feature state
import '../state/medication_provider.dart';

// internal — services
import '../../../shared/services/dose_log_service.dart';

// shared models
import '../../../shared/models/dose_log.dart';

// ─── constants ────────────────────────────────────────────────────────────────

const List<String> _kGroupOrder = [
  'Morning',
  'Afternoon',
  'Evening',
  'Night',
  'As needed',
];

// ─── screen view model ────────────────────────────────────────────────────────

class MedicationEntry {
  const MedicationEntry({
    required this.id,
    required this.medicationId,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.categoryLabel,
    required this.scheduledTimeDisplay,
    required this.scheduleLabel,
    required this.status,
    required this.scheduledTimeMs, // ← added
  });

  final String id;
  final String medicationId;
  final String name;
  final String dosage;
  final String frequency;
  final String? categoryLabel;
  final String scheduledTimeDisplay;
  final String scheduleLabel;
  final DoseStatus status;
  final int scheduledTimeMs; // ← added
}

// ─── mapping helpers ──────────────────────────────────────────────────────────

Map<String, List<MedicationEntry>> _groupToMap(List<MedicationGroup> groups) {
  return {
    for (final group in groups)
      group.label: [
        for (final enriched in group.medications)
          for (final timeStr
              in enriched.medication.times.isNotEmpty
                  ? enriched.medication.times
                  : [''])
            MedicationEntry(
              id: '${enriched.medication.id}_$timeStr',
              medicationId: enriched.medication.id,
              name: enriched.medication.name,
              dosage: enriched.medication.dosage,
              frequency: enriched.medication.frequency,
              categoryLabel: enriched.medication.categoryId,
              scheduledTimeDisplay: timeStr,
              scheduleLabel: enriched.medication.frequency,
              status:
                  enriched.statusByTime[timeStr]?.status ?? DoseStatus.later,
              // Pull scheduledTime directly from ResolvedDoseStatus —
              // single authoritative source, no recomputation.
              scheduledTimeMs:
                  enriched
                      .statusByTime[timeStr]
                      ?.scheduledTime
                      .millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch,
            ),
      ],
  };
}

AsyncValue<Map<String, List<MedicationEntry>>> _toAsync(MedicationState s) {
  if (s.isLoading) return const AsyncValue.loading();
  if (s.error != null) return AsyncValue.error(s.error!, StackTrace.empty);
  return AsyncValue.data(_groupToMap(s.groupedMedications));
}

// ─── widget ───────────────────────────────────────────────────────────────────

class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicationProvider.notifier).loadMedications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final medicationState = ref.watch(medicationProvider);
    final medicationsAsync = _toAsync(medicationState);

    final double screenWidth = MediaQuery.of(context).size.width;
    final double hPadding = screenWidth < 360
        ? AppSpacing.space12
        : AppSpacing.viewportMarginHorizontal;

    void onAddMedication() => context.pushNamed('addMedication');
    void onRetry() => ref.read(medicationProvider.notifier).loadMedications();

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      body: SafeArea(
        child: medicationsAsync.when(
          loading: () => _buildLoading(context, hPadding, onAddMedication),
          error: (e, st) => _buildError(context, hPadding, onRetry),
          data: (medications) => medications.isEmpty
              ? _buildEmpty(context, hPadding, onAddMedication)
              : _buildPopulated(
                  context,
                  hPadding,
                  medications,
                  onAddMedication,
                ),
        ),
      ),
    );
  }

  // ─── private builders ───────────────────────────────────────────────────────

  Widget _buildPopulated(
    BuildContext context,
    double hPadding,
    Map<String, List<MedicationEntry>> medications,
    VoidCallback onAddMedication,
  ) {
    final orderedGroups = _kGroupOrder
        .where((g) => medications.containsKey(g) && medications[g]!.isNotEmpty)
        .toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            context,
            hPadding: hPadding,
            showAddAction: true,
            onAddMedication: onAddMedication,
          ),
        ),
        for (final groupKey in orderedGroups) ...[
          SliverToBoxAdapter(
            child: _buildGroupHeader(context, groupKey, hPadding),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = medications[groupKey]![index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space16),
                  child: MedicationDueCard(
                    key: ValueKey(item.id),
                    medicationName: item.name,
                    dosage: item.dosage,
                    scheduledTimeDisplay: item.scheduledTimeDisplay,
                    scheduleLabel: item.scheduleLabel,
                    categoryLabel: item.categoryLabel,
                    status: item.status,
                    onTap: () => context.pushNamed(
                      'medicationDetail',
                      pathParameters: {'id': item.medicationId},
                    ),
                    onLogDose: () => context.pushNamed(
                      'logDose',
                      extra: {
                        'medicationId': item.medicationId,
                        'medicationName': item.name,
                        'doseAmount': item.dosage,
                        'scheduleLabel': item.scheduleLabel,
                        'scheduleId': item.medicationId,
                        'scheduledTimeMs': item.scheduledTimeMs, // ← fixed
                        'slotId': TimeParser.buildSlotId(
                          // ← added
                          item.medicationId,
                          DateTime.fromMillisecondsSinceEpoch(
                            item.scheduledTimeMs,
                          ),
                        ),
                      },
                    ),
                  ),
                );
              }, childCount: medications[groupKey]!.length),
            ),
          ),
        ],
        SliverToBoxAdapter(child: SizedBox(height: AppSpacing.space40)),
      ],
    );
  }

  Widget _buildLoading(
    BuildContext context,
    double hPadding,
    VoidCallback onAddMedication,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            context,
            hPadding: hPadding,
            showAddAction: false,
            onAddMedication: onAddMedication,
          ),
        ),
        SliverToBoxAdapter(
          child: Semantics(
            label: 'Loading your medications. Please wait.',
            child: ExcludeSemantics(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSkeletonGroup(context),
                    SizedBox(height: AppSpacing.space32),
                    _buildSkeletonGroup(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(
    BuildContext context,
    double hPadding,
    VoidCallback onRetry,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            context,
            hPadding: hPadding,
            showAddAction: false,
            onAddMedication: () {},
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: AppSpacing.space48 + AppSpacing.space16,
                  height: AppSpacing.space48 + AppSpacing.space16,
                  decoration: BoxDecoration(
                    color: AppColors.colorSurfaceMuted,
                    borderRadius: AppRadius.cardLarge,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.wifi_off_outlined,
                    size: AppSpacing.space32,
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.space24),
                Text(
                  'Couldn\'t load your medications.',
                  style: typography.textHeading1.copyWith(
                    color: AppColors.colorTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space8),
                Text(
                  'Check your connection and try again.',
                  style: typography.textBody.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space32),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButtonAnimation(
                    onTap: onRetry,
                    child: _PrimaryButton(
                      label: 'Try Again',
                      semanticsLabel: 'Retry loading medications',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmpty(
    BuildContext context,
    double hPadding,
    VoidCallback onAddMedication,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(
            context,
            hPadding: hPadding,
            showAddAction: true,
            onAddMedication: onAddMedication,
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: AppSpacing.space48 + AppSpacing.space16,
                  height: AppSpacing.space48 + AppSpacing.space16,
                  decoration: BoxDecoration(
                    color: AppColors.colorSurfaceMuted,
                    borderRadius: AppRadius.cardLarge,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.medication_outlined,
                    size: AppSpacing.space32,
                    color: AppColors.colorTextSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.space24),
                Text(
                  'Nothing here yet.',
                  style: typography.textHeading1.copyWith(
                    color: AppColors.colorTextPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space8),
                Text(
                  'Add your first medication to start tracking your doses.',
                  style: typography.textBody.copyWith(
                    color: AppColors.colorTextSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.space32),
                SizedBox(
                  width: double.infinity,
                  child: Semantics(
                    label: 'Add a new medication',
                    button: true,
                    excludeSemantics: true,
                    child: PrimaryButtonAnimation(
                      onTap: onAddMedication,
                      child: const _PrimaryButton(
                        label: 'Add Medication',
                        semanticsLabel: 'Add a new medication',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context, {
    required double hPadding,
    required bool showAddAction,
    required VoidCallback onAddMedication,
  }) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPadding,
        AppSpacing.space24,
        hPadding,
        AppSpacing.space20,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Medications',
                    style: typography.textScreenTitle.copyWith(
                      color: AppColors.colorTextPrimary,
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.space4),
                Text(
                  'Tap any card to view full details.',
                  style: typography.textCaption.copyWith(
                    color: AppColors.colorTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (showAddAction)
            Semantics(
              label: 'Add a new medication',
              button: true,
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onAddMedication,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: AppSpacing.touchTargetMin,
                  height: AppSpacing.touchTargetMin,
                  alignment: Alignment.center,
                  child: Container(
                    width: AppSpacing.space32,
                    height: AppSpacing.space32,
                    decoration: BoxDecoration(
                      color: AppColors.colorPrimary,
                      borderRadius: BorderRadius.circular(AppSpacing.space16),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.add,
                      color: AppColors.colorOnPrimary,
                      size: AppSpacing.iconSizeStandard,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(
    BuildContext context,
    String groupLabel,
    double hPadding,
  ) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        hPadding,
        AppSpacing.space28,
        hPadding,
        AppSpacing.space8,
      ),
      child: Semantics(
        header: true,
        child: Text(
          groupLabel.toUpperCase(),
          style: typography.textLabel.copyWith(
            color: AppColors.colorTextSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonGroup(BuildContext context) {
    const double skeletonCardHeight =
        AppSpacing.space48 + AppSpacing.space16 + AppSpacing.buttonHeightCard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LoadingPulseAnimation(
          isLoading: true,
          child: Container(
            width: 80,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.colorSkeleton,
              borderRadius: AppRadius.badge,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.space12),
        LoadingPulseAnimation(
          isLoading: true,
          child: Container(
            width: double.infinity,
            height: skeletonCardHeight,
            decoration: BoxDecoration(
              color: AppColors.colorSkeleton,
              borderRadius: AppRadius.card,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.space12),
        LoadingPulseAnimation(
          isLoading: true,
          child: Container(
            width: double.infinity,
            height: skeletonCardHeight,
            decoration: BoxDecoration(
              color: AppColors.colorSkeleton,
              borderRadius: AppRadius.card,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── private widgets ──────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.semanticsLabel});

  final String label;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    return Container(
      constraints: BoxConstraints(minHeight: AppSpacing.buttonHeightPrimary),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.colorPrimary,
        borderRadius: AppRadius.button,
      ),
      child: Text(
        label,
        style: typography.textBodySmall.copyWith(
          color: AppColors.colorOnPrimary,
        ),
      ),
    );
  }
}
