// ============================================
// FILE: widget.dart
// PATH: lib/features/dose_logs/widgets/widget.dart
// LAYER: widget
// DOMAIN: features/dose_logs
// RESPONSIBLE FOR: All layout building blocks for the Dose Logs screen
// RECEIVES: Token-driven props only — state values passed down from DoseLogsScreen
// CONNECTS TO: lib/theme/, lib/features/log_dose/models/log_dose_ui_enums.dart
// MUST NEVER: Call repositories, services, Firebase SDKs, or implement AnimationController
// ============================================

// flutter
import 'package:flutter/material.dart';

// internal — theme
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/models/log_dose_ui_enums.dart';

// ─────────────────────────────────────────
// COPY CONSTANTS
// ─────────────────────────────────────────

const String _kScreenTitle = "Today's dose";
const String _kBackSemantic = 'Leave without logging today';

const String _kLabelTaken = 'Taken';
const String _kHintTaken = 'I took it today.';
const String _kSemanticTaken = "Record today's dose as taken";

const String _kLabelSkipped = 'Skipped';
const String _kHintSkipped = 'I chose to skip it today.';
const String _kSemanticSkipped = "Record that today's dose was skipped";

const String _kLabelMissed = 'Missed';
const String _kHintMissed = "I didn't get to it today.";
const String _kSemanticMissed = "Record that today's dose was missed";

const String _kLoadingSemantic = 'Saving your update';
const String _kUndoLabel = 'Undo';
const String _kUndoSemantic = 'Reverse the last recorded dose change';

const String _kConfirmTaken = 'You took it. All set.';
const String _kConfirmSkipped = 'You skipped this one. All set.';
const String _kConfirmMissed = "You missed this one. We'll keep going.";

const String _kErrorWriteFailed = "That didn't save. Try again in a moment.";

// ─────────────────────────────────────────
// PRIVATE TOP-LEVEL HELPERS
// ─────────────────────────────────────────

String _confirmationTextFor(LogDoseChoice? choice) {
  switch (choice) {
    case LogDoseChoice.taken:
      return _kConfirmTaken;
    case LogDoseChoice.skipped:
      return _kConfirmSkipped;
    case LogDoseChoice.missed:
      return _kConfirmMissed;
    default:
      return '';
  }
}

// ─────────────────────────────────────────
// BLOCK 1 — NAVIGATION HEADER
// ─────────────────────────────────────────

class NavHeader extends StatelessWidget {
  const NavHeader({super.key, required this.onBack, required this.backBlocked});

  final VoidCallback onBack;
  final bool backBlocked;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return SizedBox(
      // TOKEN GAP A002: AppSpacing.navHeaderHeight (56dp) absent from Reference Card.
      // Approximated as space48 + space8. Visual Director notified. Resolve before next slice.
      height: AppSpacing.space48 + AppSpacing.space8,
      child: Row(
        children: [
          _BackButton(onBack: onBack, blocked: backBlocked),
          Expanded(
            child: Text(
              _kScreenTitle,
              style: typography.textHeading2.copyWith(
                color: AppColors.colorTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Mirror leading slot to keep title visually centred
          const SizedBox(width: AppSpacing.navTouchTarget),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onBack, required this.blocked});

  final VoidCallback onBack;
  final bool blocked;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _kBackSemantic,
      button: true,
      child: GestureDetector(
        onTap: blocked ? null : onBack,
        child: SizedBox(
          width: AppSpacing.navTouchTarget,
          height: AppSpacing.navTouchTarget,
          child: Icon(
            Icons.chevron_left,
            color: blocked
                ? AppColors.colorDisabled
                : AppColors.colorTextPrimary,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// BLOCK 2 — MEDICATION CONTEXT BLOCK
// ─────────────────────────────────────────

class MedicationContextBlock extends StatelessWidget {
  const MedicationContextBlock({
    super.key,
    required this.medicationName,
    required this.dosage,
    required this.scheduledTimeDisplay,
    required this.scheduleLabel,
  });

  final String medicationName;
  final String dosage;
  final String scheduledTimeDisplay;
  final String scheduleLabel;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            medicationName,
            style: typography.textHeading1.copyWith(
              color: AppColors.colorTextPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.clip,
          ),
          const SizedBox(height: AppSpacing.space8),
          _DosageRow(
            dosage: dosage,
            scheduledTimeDisplay: scheduledTimeDisplay,
            typography: typography,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            scheduleLabel,
            style: typography.textCaption.copyWith(
              color: AppColors.colorTextSecondary,
            ),
            maxLines: 2,
            overflow: TextOverflow.clip,
          ),
        ],
      ),
    );
  }
}

class _DosageRow extends StatelessWidget {
  const _DosageRow({
    required this.dosage,
    required this.scheduledTimeDisplay,
    required this.typography,
  });

  final String dosage;
  final String scheduledTimeDisplay;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final combined = '$dosage \u00B7 $scheduledTimeDisplay';
    final stacked = width < 360 && combined.length > 28;
    final style = typography.textBodySmall.copyWith(
      color: AppColors.colorTextSecondary,
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dosage, style: style, overflow: TextOverflow.clip),
          Text(scheduledTimeDisplay, style: style, overflow: TextOverflow.clip),
        ],
      );
    }

    return Text(combined, style: style, overflow: TextOverflow.clip);
  }
}

// ─────────────────────────────────────────
// BLOCK 3 — DOSE CARD ZONE
// ─────────────────────────────────────────

class DoseCardZone extends StatelessWidget {
  const DoseCardZone({
    super.key,
    required this.screenState,
    required this.selectedChoice,
    required this.onLogTaken,
    required this.onLogSkipped,
    required this.onLogMissed,
  });

  final LogDoseScreenState screenState;
  final LogDoseChoice? selectedChoice;
  final VoidCallback onLogTaken;
  final VoidCallback onLogSkipped;
  final VoidCallback onLogMissed;

  bool get _interactive =>
      screenState == LogDoseScreenState.ready ||
      screenState == LogDoseScreenState.error;

  double _opacityFor(LogDoseChoice card) {
    if (screenState == LogDoseScreenState.writeInProgress) return 0.6;
    if (screenState == LogDoseScreenState.confirmed ||
        screenState == LogDoseScreenState.undoAvailable) {
      return selectedChoice == card ? 1.0 : 0.4;
    }
    return 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? AppMotion.durationInstant
        : AppMotion.durationTransition;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: Column(
        children: [
          _AnimatedDoseCard(
            opacity: _opacityFor(LogDoseChoice.taken),
            duration: duration,
            child: DoseCard(
              label: _kLabelTaken,
              hint: _kHintTaken,
              semanticLabel: _kSemanticTaken,
              surfaceColor: AppColors.colorStateConsistentSurface,
              stateColor: AppColors.colorStateConsistent,
              onTap: _interactive ? onLogTaken : null,
            ),
          ),
          const SizedBox(height: AppSpacing.doseOptionVerticalGap),
          _AnimatedDoseCard(
            opacity: _opacityFor(LogDoseChoice.skipped),
            duration: duration,
            child: DoseCard(
              label: _kLabelSkipped,
              hint: _kHintSkipped,
              semanticLabel: _kSemanticSkipped,
              surfaceColor: AppColors.colorStateMorningSurface,
              stateColor: AppColors.colorStateMorning,
              onTap: _interactive ? onLogSkipped : null,
            ),
          ),
          const SizedBox(height: AppSpacing.doseOptionVerticalGap),
          _AnimatedDoseCard(
            opacity: _opacityFor(LogDoseChoice.missed),
            duration: duration,
            child: DoseCard(
              label: _kLabelMissed,
              hint: _kHintMissed,
              semanticLabel: _kSemanticMissed,
              surfaceColor: AppColors.colorStateRiskSurface,
              stateColor: AppColors.colorStateRisk,
              onTap: _interactive ? onLogMissed : null,
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          _ProgressIndicator(
            visible: screenState == LogDoseScreenState.writeInProgress,
            reduceMotion: reduceMotion,
          ),
        ],
      ),
    );
  }
}

class _AnimatedDoseCard extends StatelessWidget {
  const _AnimatedDoseCard({
    required this.opacity,
    required this.duration,
    required this.child,
  });

  final double opacity;
  final Duration duration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: AppMotion.curveStandard,
      child: child,
    );
  }
}

class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({required this.visible, required this.reduceMotion});

  final bool visible;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: reduceMotion
          ? AppMotion.durationInstant
          : AppMotion.durationFast,
      curve: AppMotion.curveStandard,
      child: Semantics(
        label: _kLoadingSemantic,
        child: LinearProgressIndicator(
          minHeight: 2,
          color: AppColors.colorPrimary,
          backgroundColor: AppColors.colorSurface,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// DOSE CARD
// ─────────────────────────────────────────

class DoseCard extends StatelessWidget {
  const DoseCard({
    super.key,
    required this.label,
    required this.hint,
    required this.semanticLabel,
    required this.surfaceColor,
    required this.stateColor,
    required this.onTap,
  });

  final String label;
  final String hint;
  final String semanticLabel;
  final Color surfaceColor;
  final Color stateColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    return Semantics(
      label: semanticLabel,
      button: true,
      child: DoseLogConfirmationAnimation(
        // TOKEN GAP: DoseLogConfirmationAnimation.onTap must accept VoidCallback?
        // Currently substituting empty callback to avoid null assertion.
        // Resolve in app_animations.dart before removing this workaround.
        onTap: onTap ?? () {},
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: AppSpacing.doseOptionMinHeight,
          ),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.cardLarge,
            border: Border.all(color: stateColor, width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space12,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LeadingCircle(color: stateColor),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: _CardBody(
                  label: label,
                  hint: hint,
                  stateColor: stateColor,
                  typography: typography,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingCircle extends StatelessWidget {
  const _LeadingCircle({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.doseOptionLeadingCircle,
      height: AppSpacing.doseOptionLeadingCircle,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({
    required this.label,
    required this.hint,
    required this.stateColor,
    required this.typography,
  });

  final String label;
  final String hint;
  final Color stateColor;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: typography.textBodySmall.copyWith(
            color: stateColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Text(
          hint,
          style: typography.textCaption.copyWith(
            color: AppColors.colorTextSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.clip,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// BLOCK 4 — STATUS ZONE
// ─────────────────────────────────────────

class StatusZone extends StatelessWidget {
  const StatusZone({
    super.key,
    required this.screenState,
    required this.selectedChoice,
    required this.errorMessage,
    required this.onUndo,
  });

  final LogDoseScreenState screenState;
  final LogDoseChoice? selectedChoice;
  final String? errorMessage;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final duration = reduceMotion
        ? AppMotion.durationInstant
        : AppMotion.durationTransition;

    final showConfirm =
        screenState == LogDoseScreenState.confirmed ||
        screenState == LogDoseScreenState.undoAvailable;
    final showError = screenState == LogDoseScreenState.error;
    final showContent = showConfirm || showError;

    return AnimatedSize(
      duration: reduceMotion
          ? AppMotion.durationInstant
          : AppMotion.durationFast,
      curve: AppMotion.curveStandard,
      child: showContent
          ? AnimatedOpacity(
              opacity: 1.0,
              duration: duration,
              curve: AppMotion.curveStandard,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.viewportMarginHorizontal,
                  vertical: AppSpacing.space16,
                ),
                color: AppColors.colorSurface,
                child: showConfirm
                    ? _ConfirmationContent(
                        text: _confirmationTextFor(selectedChoice),
                        onUndo: onUndo,
                        typography: typography,
                      )
                    : _ErrorContent(
                        message: errorMessage ?? _kErrorWriteFailed,
                        typography: typography,
                      ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ConfirmationContent extends StatelessWidget {
  const _ConfirmationContent({
    required this.text,
    required this.onUndo,
    required this.typography,
  });

  final String text;
  final VoidCallback onUndo;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: typography.textHeading2.copyWith(
            color: AppColors.colorTextPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space8),
        Semantics(
          label: _kUndoSemantic,
          button: true,
          child: GestureDetector(
            onTap: onUndo,
            child: Text(
              _kUndoLabel,
              style: typography.textBodySmall.copyWith(
                color: AppColors.colorPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _ErrorContent extends StatelessWidget {
  const _ErrorContent({required this.message, required this.typography});

  final String message;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: typography.textBodySmall.copyWith(color: AppColors.colorStateRisk),
      textAlign: TextAlign.left,
    );
  }
}

// ─────────────────────────────────────────
// BLOCK 5 — NOTES FIELD
// ─────────────────────────────────────────

class NotesField extends StatelessWidget {
  const NotesField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final typography = Theme.of(context).extension<AppTypography>()!;

    final baseStyle = typography.textCaption.copyWith(
      color: AppColors.colorTextTertiary,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.viewportMarginHorizontal,
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        minLines: 1,
        maxLines: 5,
        style: typography.textBody.copyWith(color: AppColors.colorTextPrimary),
        decoration: InputDecoration(
          labelText: 'Anything to note?',
          hintText: 'e.g. Took it with food',
          labelStyle: baseStyle,
          hintStyle: baseStyle,
          contentPadding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space12,
            horizontal: AppSpacing.space16,
          ),
          filled: true,
          fillColor: AppColors.colorSurface,
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.card,
            borderSide: const BorderSide(
              color: AppColors.colorBorder,
              width: 0.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.card,
            borderSide: BorderSide(color: AppColors.colorPrimary, width: 2.0),
          ),
        ),
      ),
    );
  }
}
