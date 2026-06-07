// ===
// FILE: app_motion.dart
// PATH: lib/theme/app_motion.dart
// RESPONSIBLE FOR: All motion duration constants, easing curves, and haptic wrappers
//
// MOTION PERSONALITY:
// Slow. Warm. Certain.
// Every animation in MedAdhere answers one question Mama Ngozi's
// brain is already asking: did that work?
// If a motion does not confirm or reveal, it does not exist.
//
// MOTION RULES (non-negotiable — encode violations as purity failures):
//   1. Curves.bounceOut is never used in this product.
//   2. Spring physics are never used in this product.
//   3. Curves.easeIn is never used in this product.
//   4. No animation exceeds durationStreak (320ms).
//   5. No slide, scale, or hero transitions between screens. Ever.
//   6. Low-end hardware is not an edge case. It is the target environment.
//      All animation logic must be budget-conscious by default.
//   7. Motion never implies urgency. No pulse, shake, or flash for
//      any adherence state — ever.
//   8. Haptic feedback respects system accessibility settings.
//      Never force haptics when the user has disabled them at OS level.
//
// REDUCED MOTION:
// All animations in this product degrade gracefully to instant state
// changes when Android ANIMATOR_DURATION_SCALE = 0.
// Use durationInstant (0ms) as the fallback duration.
// No animation is load-bearing — meaning is never carried by motion alone.
// Check MediaQuery.of(context).disableAnimations before triggering any
// animation. If true, substitute durationInstant.
// ===

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppMotion {
  AppMotion._();

  // ---------------------------------------------------------------------------
  // DURATION TOKENS
  // ---------------------------------------------------------------------------

  /// 0ms — Reduced motion fallback. Use when MediaQuery.disableAnimations is true.
  /// Also used for state changes that must feel instantaneous.
  static const Duration durationInstant = Duration(milliseconds: 0);

  /// 180ms — Moment 01: dose log confirmation press response.
  static const Duration durationFast = Duration(milliseconds: 180);

  /// 240ms — Moment 04: missed dose state colour crossfade.
  static const Duration durationMedium = Duration(milliseconds: 240);

  /// 200ms — All screen-to-screen fade transitions.
  static const Duration durationTransition = Duration(milliseconds: 200);

  /// 280ms — Moment 03: insight card entrance (translateY + opacity).
  static const Duration durationReveal = Duration(milliseconds: 280);

  /// 320ms — Moment 02: streak increment fade. The longest animation in the product.
  /// No animation may exceed this value.
  static const Duration durationStreak = Duration(milliseconds: 320);

  /// 1200ms — Moment 05: loading pulse cycle duration.
  /// One full opacity cycle (min → max → min). Feels like a slow breath.
  static const Duration durationLoadingPulse = Duration(milliseconds: 1200);

  // ---------------------------------------------------------------------------
  // EASING CURVE TOKENS
  // ---------------------------------------------------------------------------

  /// All confirmations, reveals, and entrances.
  /// Starts with energy, settles with certainty.
  static const Curve curveStandard = Curves.easeOut;

  /// State transitions and crossfades.
  /// Symmetric — neither urgency entering nor abruptness leaving.
  static const Curve curveTransition = Curves.easeInOut;

  // ---------------------------------------------------------------------------
  // SCREEN TRANSITION SPECIFICATION
  // Consumed by app_theme.dart to configure PageTransitionsTheme.
  // Screen transitions are fade only — no slide, scale, or hero. Ever.
  // ---------------------------------------------------------------------------

  /// Fade only. Low-end hardware safe.
  static const Duration screenTransitionDuration = durationTransition;

  /// Symmetric fade — neither entrance nor exit dominates.
  static const Curve screenTransitionCurve = curveTransition;

  // ---------------------------------------------------------------------------
  // CRITICAL MOTION MOMENT SPECIFICATIONS
  //
  // These are named specification blocks for the four interaction moments.
  // They are not implemented here — app_animations.dart consumes these
  // constants to build the animation widgets in Round Three.
  //
  // Moment 01 — doseLogConfirmation
  //   Type:         scale
  //   From:         1.0
  //   To:           0.97 (press down) → 1.0 (release up)
  //   Duration:     durationFast (180ms)
  //   Curve:        curveStandard
  //   Delay:        none
  //   Feel:         Pressing something real with your thumb and feeling it respond.
  //                 Immediate. Certain.
  //
  // Moment 02 — streakIncrement
  //   Type:         opacity
  //   From:         0.0 → 1.0 (new number value fades in)
  //   Duration:     durationStreak (320ms)
  //   Curve:        curveStandard
  //   Delay:        200ms — intentional breath before animation begins
  //   Feel:         A breath before the affirmation. Quiet satisfaction.
  //                 No bounce. No explosion. No fanfare.
  //
  // Moment 03 — insightCardReveal
  //   Type:         translateY + opacity combined
  //   translateY:   +8dp → 0
  //   opacity:      0.0 → 1.0
  //   Duration:     durationReveal (280ms)
  //   Curve:        curveStandard
  //   Delay:        none
  //   Feel:         A message arriving, not a data refresh. Considered and personal.
  //
  // Moment 04 — missedDoseStateChange
  //   Type:         colour crossfade
  //   From:         current state surface colour
  //   To:           colorStateRiskSurface
  //   Duration:     durationMedium (240ms)
  //   Curve:        curveTransition
  //   Delay:        none
  //   Positional:   none — form stays in place, only warmth temperature changes
  //   Feel:         A soft flag. Not an alarm.
  //
  // Moment 05 — loadingPulse
  //   Type:         opacity cycle
  //   From:         0.40 → 1.0 → 0.40 (repeating)
  //   Duration:     durationLoadingPulse (1200ms per full cycle)
  //   Curve:        curveTransition (easeInOut — symmetrical, warm)
  //   Delay:        none
  //   Repeat:       true — cycles until loading resolves
  //   Reduced motion: static opacity 0.70 (loadingPulseOpacityMax used as fallback)
  //   Rules:        Loading pulse never uses translate or scale. Opacity only.
  //                 Pulse must feel slow and organic — not a rapid technical indicator.
  //                 Degrades to static opacity 0.70 when ANIMATOR_DURATION_SCALE = 0.
  //   Feel:         A slow, quiet breath. Content that is on its way, not absent.
  //                 Never mechanical. Never flickering.
  // ---------------------------------------------------------------------------

  // Moment 01 — doseLogConfirmation
  static const Duration doseLogConfirmationDuration = durationFast;
  static const Curve doseLogConfirmationCurve = curveStandard;
  static const double doseLogConfirmationScaleDown = 0.97;
  static const double doseLogConfirmationScaleUp = 1.0;

  // Moment 02 — streakIncrement
  static const Duration streakIncrementDuration = durationStreak;
  static const Curve streakIncrementCurve = curveStandard;
  static const Duration streakIncrementDelay = Duration(milliseconds: 200);
  static const double streakIncrementOpacityFrom = 0.0;
  static const double streakIncrementOpacityTo = 1.0;

  // Moment 03 — insightCardReveal
  static const Duration insightCardRevealDuration = durationReveal;
  static const Curve insightCardRevealCurve = curveStandard;
  static const double insightCardRevealOffsetDp =
      8.0; // translateY start offset

  // Moment 04 — missedDoseStateChange
  static const Duration missedDoseStateChangeDuration = durationMedium;
  static const Curve missedDoseStateChangeCurve = curveTransition;

  // Moment 05 — loadingPulse
  static const Duration loadingPulseDuration = durationLoadingPulse;
  static const Curve loadingPulseCurve = curveTransition;
  static const double loadingPulseOpacityMin = 0.40;
  static const double loadingPulseOpacityMax = 1.0;

  /// Reduced motion fallback: render at this opacity, no animation.
  static const double loadingPulseReducedOpacity = 0.70;

  // — Amendment A004 —

  /// Opacity for decorative symbolic elements — cold start arc, error broken line.
  /// Not an animation value — a static visual constant for decorative UI only.
  static const double decorativeSymbolOpacity = 0.24;

  // ---------------------------------------------------------------------------
  // HAPTIC WRAPPERS
  // Named for their semantic trigger moment — not for their Flutter primitive.
  // Respect system accessibility settings automatically via HapticFeedback.
  // ---------------------------------------------------------------------------

  /// Moment 01 — User taps taken, skipped, or missed.
  /// Sensation: Solid. Confirming. Like pressing a real button.
  static Future<void> hapticDoseConfirmation() => HapticFeedback.mediumImpact();

  /// Moment 02 — All doses logged, streak counter grows.
  /// Sensation: Light. Celebratory. Not startling.
  static Future<void> hapticStreakIncrement() => HapticFeedback.lightImpact();

  /// Moment 04 — Missed dose state change.
  /// Sensation: Silent. The form changes warmth temperature.
  /// No physical interrupt. No alarm sensation.
  /// This method is intentionally a no-op. It exists so call sites
  /// are consistent — the Senior Dev calls hapticMissedDose() and
  /// the silence is intentional, not an omission.
  static Future<void> hapticMissedDose() async {}
}
