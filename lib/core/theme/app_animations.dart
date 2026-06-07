// ===
// FILE: app_animations.dart
// PATH: lib/theme/app_animations.dart
// RESPONSIBLE FOR: All named animation widgets for MedAdhere's five critical moments
//
// RULES (non-negotiable — encode violations as purity failures):
//   1. No screen or widget file implements an AnimationController directly.
//      All animation behaviour is consumed from this file by widget name.
//   2. All timing and easing values are consumed from app_motion.dart constants.
//      Never hardcode a duration, curve, opacity value, or offset here.
//   3. No colour or typography tokens are used in this file.
//      Animation widgets are structurally agnostic of visual values.
//      Colour is passed in by the caller where required (MissedDoseStateChangeAnimation).
//   4. Every widget checks MediaQuery.of(context).disableAnimations.
//      When true, animations resolve immediately to their end state.
//      No animation is load-bearing — meaning is never carried by motion alone.
// ===

import 'package:flutter/material.dart';
import 'app_motion.dart';
// import 'app_spacing.dart';

// =============================================================================
// WIDGET 01 — DoseLogConfirmationAnimation
// Moment 01: scale press feedback on dose action buttons.
// Wraps any tappable widget in a physical press-and-release scale animation.
// =============================================================================

class DoseLogConfirmationAnimation extends StatefulWidget {
  const DoseLogConfirmationAnimation({
    super.key,
    required this.child,
    this.onTap,
  });

  /// The widget to wrap — typically a dose action button.
  final Widget child;

  /// Called after the press animation completes and haptic fires.
  /// When null: no animation plays, no haptic fires, no callback fires.
  /// Use PrimaryButtonAnimation for non-dose actions — it has no haptic by design.
  final VoidCallback? onTap;

  @override
  State<DoseLogConfirmationAnimation> createState() =>
      _DoseLogConfirmationAnimationState();
}

class _DoseLogConfirmationAnimationState
    extends State<DoseLogConfirmationAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.doseLogConfirmationDuration,
    );
    _scale =
        Tween<double>(
          begin: AppMotion.doseLogConfirmationScaleUp,
          end: AppMotion.doseLogConfirmationScaleDown,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppMotion.doseLogConfirmationCurve,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails _) async {
    // Guard 01: non-interactive card — do nothing.
    if (widget.onTap == null) return;
    // Guard 02: reduced motion — skip animation, tap handler fires in _handleTap.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return;
    await _controller.forward();
  }

  Future<void> _handleTapUp(TapUpDetails _) async {
    // Guard 01: non-interactive card — do nothing.
    if (widget.onTap == null) return;
    // Guard 02: reduced motion — nothing to reverse.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return;
    await _controller.reverse();
  }

  Future<void> _handleTapCancel() async {
    // No null guard needed — cancelling on a non-interactive surface is harmless.
    await _controller.reverse();
  }

  Future<void> _handleTap() async {
    // Guard 01: non-interactive card — no haptic, no animation, no callback.
    if (widget.onTap == null) return;
    // Guard 02: reduced motion — skip animation but still fire haptic and callback.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      await _controller.forward();
      await _controller.reverse();
    }
    await AppMotion.hapticDoseConfirmation();
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

// =============================================================================
// WIDGET 02 — StreakIncrementAnimation
// Moment 02: opacity fade-in of the new streak number after a 200ms breath.
// Trigger flips to true when the counter increments.
// =============================================================================

class StreakIncrementAnimation extends StatefulWidget {
  const StreakIncrementAnimation({
    super.key,
    required this.child,
    required this.trigger,
  });

  /// The new streak value widget to fade in.
  final Widget child;

  /// Flip to true to play the animation. Flip back to reset.
  final bool trigger;

  @override
  State<StreakIncrementAnimation> createState() =>
      _StreakIncrementAnimationState();
}

class _StreakIncrementAnimationState extends State<StreakIncrementAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.streakIncrementDuration,
    );
    _opacity =
        Tween<double>(
          begin: AppMotion.streakIncrementOpacityFrom,
          end: AppMotion.streakIncrementOpacityTo,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppMotion.streakIncrementCurve,
          ),
        );
  }

  @override
  void didUpdateWidget(StreakIncrementAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _playWithDelay();
    }
  }

  Future<void> _playWithDelay() async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      // Reduced motion: snap to full opacity immediately, no delay.
      _controller.value = 1.0;
      await AppMotion.hapticStreakIncrement();
      return;
    }
    // Intentional breath pause before the affirmation.
    await Future.delayed(AppMotion.streakIncrementDelay);
    if (!mounted) return;
    await AppMotion.hapticStreakIncrement();
    await _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

// =============================================================================
// WIDGET 03 — InsightCardRevealAnimation
// Moment 03: combined translateY + opacity entrance on widget mount.
// Plays immediately when the insight card enters the widget tree.
// =============================================================================

class InsightCardRevealAnimation extends StatefulWidget {
  const InsightCardRevealAnimation({super.key, required this.child});

  /// The insight card content to reveal.
  final Widget child;

  @override
  State<InsightCardRevealAnimation> createState() =>
      _InsightCardRevealAnimationState();
}

class _InsightCardRevealAnimationState extends State<InsightCardRevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _offsetY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.insightCardRevealDuration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.insightCardRevealCurve,
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(curved);

    // Offset: starts below by insightCardRevealOffsetDp, rises to zero.
    _offsetY = Tween<double>(
      begin: AppMotion.insightCardRevealOffsetDp,
      end: 0.0,
    ).animate(curved);

    final reduceMotion = WidgetsBinding
        .instance
        .platformDispatcher
        .accessibilityFeatures
        .disableAnimations;

    if (reduceMotion) {
      // Snap to end state instantly — no animation.
      _controller.value = 1.0;
    } else {
      // Plays immediately on mount — no delay per spec.
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.translate(
          offset: Offset(0, _offsetY.value),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

// =============================================================================
// WIDGET 04 — MissedDoseStateChangeAnimation
// Moment 04: colour crossfade of a medication card background.
// No positional animation — form stays in place, only warmth temperature changes.
// =============================================================================

class MissedDoseStateChangeAnimation extends StatefulWidget {
  const MissedDoseStateChangeAnimation({
    super.key,
    required this.child,
    required this.isMissed,
    required this.missedSurfaceColor,
    required this.defaultSurfaceColor,
  });

  /// The card content. Position never changes.
  final Widget child;

  /// When true, crossfades to missedSurfaceColor. When false, crossfades back.
  final bool isMissed;

  /// The at-risk surface colour — typically AppColors.colorStateRiskSurface.
  /// Passed by the caller to keep this widget colour-agnostic.
  final Color missedSurfaceColor;

  /// The default surface colour for this card's current adherence state.
  final Color defaultSurfaceColor;

  @override
  State<MissedDoseStateChangeAnimation> createState() =>
      _MissedDoseStateChangeAnimationState();
}

class _MissedDoseStateChangeAnimationState
    extends State<MissedDoseStateChangeAnimation> {
  @override
  Widget build(BuildContext context) {
    // → STATE HOOK: isMissed is driven by the Senior Dev's state layer.
    // AnimatedContainer handles the colour interpolation natively.
    // No AnimationController needed — this is the correct implicit pattern.
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return AnimatedContainer(
      duration: reduceMotion
          ? AppMotion.durationInstant
          : AppMotion.missedDoseStateChangeDuration,
      curve: AppMotion.missedDoseStateChangeCurve,
      color: widget.isMissed
          ? widget.missedSurfaceColor
          : widget.defaultSurfaceColor,
      child: widget.child,
    );
    // Haptic: AppMotion.hapticMissedDose() is a no-op by design.
    // The Senior Dev calls it at the state change site for structural consistency.
  }
}

// =============================================================================
// WIDGET 05 — LoadingPulseAnimation
// Moment 05: slow opacity cycle on skeleton content during async loading.
// When isLoading flips to false, animation stops and child resolves to full opacity.
// =============================================================================
class LoadingPulseAnimation extends StatefulWidget {
  const LoadingPulseAnimation({
    super.key,
    required this.child,
    required this.isLoading,
  });

  /// The skeleton or placeholder content to pulse.
  final Widget child;

  /// While true, opacity cycles. When false, resolves to full opacity.
  final bool isLoading;

  @override
  State<LoadingPulseAnimation> createState() => _LoadingPulseAnimationState();
}

class _LoadingPulseAnimationState extends State<LoadingPulseAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.loadingPulseDuration,
    );

    _opacity =
        Tween<double>(
          begin: AppMotion.loadingPulseOpacityMin,
          end: AppMotion.loadingPulseOpacityMax,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppMotion.loadingPulseCurve,
          ),
        );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isLoading && !_controller.isAnimating) {
      _startPulse();
    }
  }

  @override
  void didUpdateWidget(LoadingPulseAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _startPulse();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      // Let current cycle complete — no abrupt cut.
      _controller.forward().then((_) {
        if (mounted) _controller.stop();
      });
    }
  }

  void _startPulse() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      // Reduced motion: static opacity — no animation.
      _controller.value = 1.0;
      return;
    }
    // repeat(reverse: true) cycles min → max → min organically.
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

// =============================================================================
// WIDGET 06 — PrimaryButtonAnimation
// For all primary actions that are NOT dose logging — retry buttons, navigation,
// form submissions, add and edit confirmations.
// Identical scale mechanics to DoseLogConfirmationAnimation.
// CRITICAL: No haptic of any kind. Haptics are reserved exclusively for
// dose-logging moments. This widget must never call any haptic method.
// =============================================================================

class PrimaryButtonAnimation extends StatefulWidget {
  const PrimaryButtonAnimation({
    super.key,
    required this.child,
    required this.onTap,
  });

  /// The widget to wrap — any non-dose primary action button.
  final Widget child;

  /// Called after the press animation completes.
  final VoidCallback onTap;

  @override
  State<PrimaryButtonAnimation> createState() => _PrimaryButtonAnimationState();
}

class _PrimaryButtonAnimationState extends State<PrimaryButtonAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.doseLogConfirmationDuration,
    );
    _scale =
        Tween<double>(
          begin: AppMotion.doseLogConfirmationScaleUp,
          end: AppMotion.doseLogConfirmationScaleDown,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: AppMotion.doseLogConfirmationCurve,
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTapDown(TapDownDetails _) async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return;
    await _controller.forward();
  }

  Future<void> _handleTapUp(TapUpDetails _) async {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) return;
    await _controller.reverse();
  }

  Future<void> _handleTapCancel() async {
    await _controller.reverse();
  }

  Future<void> _handleTap() async {
    // Reduced motion: skip animation, always fire callback.
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      widget.onTap();
      return;
    }
    // No haptic — ever. Haptics belong to DoseLogConfirmationAnimation only.
    await _controller.forward();
    await _controller.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
