// ============================================
// FILE: log_dose_screen.dart
// PATH: lib/features/log_dose/screens/log_dose_screen.dart
// LAYER: screen
// DOMAIN: log_dose
// RESPONSIBLE FOR: Orchestrates the Log Dose interaction — maps provider state
//                  to LogDoseScreenState, manages dismiss timer, wires callbacks
//                  to DoseLogNotifier. Renders nothing directly.
// RECEIVES: medicationId, scheduleId, scheduledTimeMs, medicationName,
//           doseAmount, scheduleLabel as constructor params from router
// RETURNS: Pops to previous route after confirmation window or undo
// CONNECTS TO: dose_log_provider.dart, log_dose_widgets.dart
// MUST NEVER: Declare providers, call repositories, use SingleChildScrollView,
//             hardcode colours, spacing, or text styles
// ============================================

// dart
import 'dart:async';

// flutter
import 'package:flutter/material.dart';

// packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// internal — state
import '../state/dose_log_provider.dart';

// internal — models
import '../../../shared/models/dose_log.dart';
import '../../../shared/models/log_dose_ui_enums.dart';

// internal — widgets

// internal — theme
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_motion.dart';
import '../widgets/widget.dart';

// ─────────────────────────────────────────
// SCREEN CONSTANTS
// ─────────────────────────────────────────

const Duration _kDismissDelay = Duration(seconds: 3);

// ─────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────

class LogDoseScreen extends ConsumerStatefulWidget {
  const LogDoseScreen({
    super.key,
    required this.medicationId,
    required this.scheduleId,
    required this.scheduledTimeMs,
    required this.medicationName,
    required this.doseAmount,
    required this.scheduleLabel,
    required this.slotId,
  });

  final String medicationId;
  final String scheduleId;
  final String slotId; // ← added
  final int scheduledTimeMs; // ← kept for display only
  final String medicationName;
  final String doseAmount;
  final String scheduleLabel;
  @override
  ConsumerState<LogDoseScreen> createState() => _LogDoseScreenState();
}

class _LogDoseScreenState extends ConsumerState<LogDoseScreen> {
  Timer? _dismissTimer;
  final _notesController = TextEditingController();

  // ─── lifecycle ───────────────────────────────────────────────────────────

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  // ─── state mapping ───────────────────────────────────────────────────────

  LogDoseScreenState _mapState(DoseLogState s) {
    if (s.isLoading) return LogDoseScreenState.writeInProgress;
    if (s.error != null) return LogDoseScreenState.error;
    if (s.undoAvailable) return LogDoseScreenState.undoAvailable;
    if (s.selectedStatus != null) return LogDoseScreenState.confirmed;
    return LogDoseScreenState.ready;
  }

  LogDoseChoice? _mapChoice(DoseStatus? s) => switch (s) {
    DoseStatus.taken => LogDoseChoice.taken,
    DoseStatus.skipped => LogDoseChoice.skipped,
    DoseStatus.missed => LogDoseChoice.missed,
    null => null,
    // TODO: Handle this case.
    DoseStatus.dueNow => throw UnimplementedError(),
    // TODO: Handle this case.
    DoseStatus.later => throw UnimplementedError(),
    // TODO: Handle this case.
    DoseStatus.overdue => throw UnimplementedError(),
  };

  bool _backBlocked(LogDoseScreenState s) =>
      s == LogDoseScreenState.writeInProgress ||
      s == LogDoseScreenState.confirmed ||
      s == LogDoseScreenState.undoAvailable;

  // ─── timer ───────────────────────────────────────────────────────────────

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(_kDismissDelay, () {
      if (mounted) context.pop();
    });
  }

  // ─── handlers ────────────────────────────────────────────────────────────
  Future<void> _onChoiceTapped(DoseStatus status) async {
    if (ref.read(doseLogProvider).isLoading) return;
    _dismissTimer?.cancel();
    AppMotion.hapticDoseConfirmation();
    final notes = ref.read(doseLogProvider).notesValue;
    final scheduledTime = DateTime.fromMillisecondsSinceEpoch(
      widget.scheduledTimeMs,
    );
    await ref
        .read(doseLogProvider.notifier)
        .logDose(
          widget.medicationId,
          widget.scheduleId,
          scheduledTime,
          status,
          notes,
        );
    if (!mounted) return;
    if (ref.read(doseLogProvider).error != null) return;
    _startDismissTimer();
  }

  void _onUndo() {
    _dismissTimer?.cancel();
    _notesController.clear();
    ref.read(doseLogProvider.notifier).undoLog();
  }

  // ─── helpers ─────────────────────────────────────────────────────────────

  String _formatTime(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final h = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  // ─── build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(doseLogProvider);
    final screenState = _mapState(state);

    return Scaffold(
      backgroundColor: AppColors.colorSurface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: NavHeader(
                onBack: () => context.pop(),
                backBlocked: _backBlocked(screenState),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.space20),
            ),
            SliverToBoxAdapter(
              child: MedicationContextBlock(
                medicationName: widget.medicationName,
                dosage: widget.doseAmount,
                scheduledTimeDisplay: _formatTime(widget.scheduledTimeMs),
                scheduleLabel: widget.scheduleLabel,
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.space32),
            ),
            SliverToBoxAdapter(
              child: DoseCardZone(
                screenState: screenState,
                selectedChoice: _mapChoice(state.selectedStatus),
                onLogTaken: () => _onChoiceTapped(DoseStatus.taken),
                onLogSkipped: () => _onChoiceTapped(DoseStatus.skipped),
                onLogMissed: () => _onChoiceTapped(DoseStatus.missed),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.space24),
            ),
            SliverToBoxAdapter(
              child: NotesField(
                controller: _notesController,
                onChanged: (v) =>
                    ref.read(doseLogProvider.notifier).updateNotes(v),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.space24),
            ),
            SliverToBoxAdapter(
              child: StatusZone(
                screenState: screenState,
                selectedChoice: _mapChoice(state.selectedStatus),
                errorMessage: state.error,
                onUndo: _onUndo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
