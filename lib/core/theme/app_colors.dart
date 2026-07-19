// ===
// FILE: app_colors.dart
// PATH: lib/theme/app_colors.dart
// RESPONSIBLE FOR: All colour constants and MedAdhere adherence state ThemeExtension
//
// COLOUR RULES (non-negotiable — encode violations as purity failures):
//   1. Red is never used in this product. Ember terracotta (#B04E35) is the ceiling of urgency.
//   2. colorStateEmber is never used as a full-saturation background behind small text.
//      Use surface wash (colorStateEmberSurface) with dark text, or at large decorative scale only.
//   3. colorSurface (Warm Parchment) is preferred over pure white for all screen backgrounds.
//   4. Dark mode is deferred. This file is light-mode only.
//   5. Colour is never the sole carrier of meaning. Every state expressed in colour
//      is also expressed in a text label or icon.
//
// AMENDMENT LOG
//   A007 — badgeDueBackground / badgeDueText reassigned. Previously
//          badgeDueBackground pointed at colorStateSlippingSurface — the
//          exact same token as badgeSkippedBackground, so Due and
//          Skipped rendered with an identical background fill in the
//          weekly adherence dot grid and its legend. badgeDueText was
//          also a separate hardcoded value (#7A4E0A) never tied to any
//          named token. Reassigned both to colorStateMorning /
//          colorStateMorningSurface — a token pair already defined in
//          this file and, until now, unused anywhere in the medication
//          card badge set. "Due" is a neutral not-yet-resolved state,
//          not a caution state, so the Cold Start blue fits its meaning
//          better than the borrowed Slipping amber did. See
//          _adherence_strip_widget.dart legend for the affected UI.
// ===

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // CORE PALETTE
  // ---------------------------------------------------------------------------

  /// Deep Forest — primary brand colour. Use onPrimary (white) for text/icons on top.
  static const Color colorPrimary = Color(0xFF1C2B1E);

  /// Aged Gold — accent, highlights, streak elements.
  /// Carries brand accent meaning — distinct from colorStateDusk which signals
  /// adherence caution. These two tokens must never share the same hex.
  static const Color colorAccent = Color(0xFFC4872A);

  /// Warm Parchment — preferred screen background. Use instead of pure white.
  static const Color colorSurface = Color(0xFFF5F1E8);

  /// Card White — card surfaces only.
  static const Color colorCard = Color(0xFFFFFFFF);

  /// Near Black — primary body text.
  static const Color colorTextPrimary = Color(0xFF141710);

  /// Warm Mid — secondary/supporting text.
  static const Color colorTextSecondary = Color(0xFF5A574E);

  /// Warm Grey — tertiary text, inactive nav labels.
  static const Color colorTextTertiary = Color(0xFF9A9690);

  /// Forest Border — rgba(28, 43, 30, 0.10) — subtle container borders.
  static const Color colorBorder = Color.fromRGBO(28, 43, 30, 0.10);

  /// Pale Gold — decorative gold wash, streak chip fills, highlight surfaces.
  static const Color colorGoldLight = Color(0xFFF0DBA0);

  // — Round Two additions — resolved from Round One gap report —

  /// Warm Parchment on Deep Forest surfaces.
  /// Not arbitrary white — carries the same warmth temperature as the rest of the product.
  /// Use for text and icons rendered on top of colorPrimary.
  static const Color colorOnPrimary = Color(0xFFF5F1E8);

  /// Warm desaturated grey — disabled interactive elements only.
  /// Deliberately warm, never cold. A cold grey activates clinical associations
  /// this product explicitly rejects.
  static const Color colorDisabled = Color(0xFFC8C5BF);

  /// Text on colorSurface and colorCard.
  /// Formally aliased to colorTextPrimary. Same value, different semantic role.
  /// Do not collapse — they must be able to diverge in future revisions independently.
  static const Color colorOnSurface = colorTextPrimary;

  // — Round Three addition — resolved from Round Two gap report —

  /// Deep Forest on Aged Gold surfaces.
  /// colorOnAccent is Deep Forest because it is the darkest warm token in the system,
  /// maintains palette coherence, and introduces no new colour.
  /// Aged Gold as a background surface always carries Deep Forest foreground.
  static const Color colorOnAccent = Color(0xFF1C2B1E);

  // — Round Four addition —

  /// Warm Forest wash for skeleton loading states.
  /// Consistent with the parchment base surface. Never cold grey.
  /// Use as the background colour of skeleton placeholder elements
  /// inside LoadingPulseAnimation.
  static const Color colorSkeleton = Color.fromRGBO(28, 43, 30, 0.06);

  // — Amendment A001 —

  /// Muted interactive surface — unselected chips, inline inputs, secondary buttons.
  /// Deep Forest at 10% opacity — rgba(28,43,30,0.10).
  static const Color colorSurfaceMuted = Color(0x1A1C2B1E);

  /// For scheduled time display chips in medication detail only.
  /// Separate token allows this surface to evolve independently from
  /// interactive muted surfaces in future.
  static const Color colorTimeChipSurface = colorSurfaceMuted;

  // ---------------------------------------------------------------------------
  // ADHERENCE ARC STATE TOKENS
  // These are the emotional architecture of the product.
  // Four states map the user's medication journey from cold start to at-risk.
  // ---------------------------------------------------------------------------

  /// Cold Start primary — morning, first-dose-of-day state.
  static const Color colorStateMorning = Color(0xFF7B9EB8);

  /// Cold Start surface wash — backgrounds behind morning-state elements.
  static const Color colorStateMorningSurface = Color(0xFFEBF1F7);

  /// Consistent primary — on-track adherence. The green of success.
  static const Color colorStateDay = Color(0xFF2D6847);

  /// Consistent surface wash — backgrounds behind consistent-state elements.
  static const Color colorStateDaySurface = Color(0xFFE5F0EA);

  /// Slipping primary — caution signal. Distinct from colorAccent (#C4872A)
  /// which carries brand accent meaning. These two tokens must never share the
  /// same hex. One signals achievement. One signals caution.
  static const Color colorStateDusk = Color(0xFFA8711A);

  /// Slipping surface wash — backgrounds behind slipping-state elements.
  static const Color colorStateDuskSurface = Color(0xFFF5E8CC);

  /// At Risk primary — terracotta urgency ceiling. Never full-saturation behind small text.
  static const Color colorStateEmber = Color(0xFFB04E35);

  /// At Risk surface wash — always use this (not colorStateEmber) as a background behind text.
  static const Color colorStateEmberSurface = Color(0xFFF5E5DF);

  // ---------------------------------------------------------------------------
  // SEMANTIC ALIAS TOKENS
  // Widgets reference these names, never the arc tokens above directly.
  // The indirection allows the arc palette to evolve without touching widget code.
  // ---------------------------------------------------------------------------

  static const Color colorStateConsistent = colorStateDay;
  static const Color colorStateConsistentSurface = colorStateDaySurface;

  /// Semantic alias of colorStateDusk. Inherits the value of colorStateDusk automatically.
  /// Do not assign a separate hex — the alias relationship is load-bearing.
  static const Color colorStateSlipping = colorStateDusk;
  static const Color colorStateSlippingSurface = colorStateDuskSurface;
  static const Color colorStateRisk = colorStateEmber;
  static const Color colorStateRiskSurface = colorStateEmberSurface;

  // ---------------------------------------------------------------------------
  // MEDICATION CARD BADGE TOKENS
  // ---------------------------------------------------------------------------

  static const Color badgeTakenBackground = colorStateConsistentSurface;
  static const Color badgeTakenText = colorStateConsistent;

  /// Amendment A007 — was colorStateSlippingSurface, identical to
  /// badgeSkippedBackground below (a real visual collision in the weekly
  /// dot grid). Reassigned to the previously-unused Cold Start blue.
  static const Color badgeDueBackground = colorStateMorningSurface;

  /// Amendment A007 — was a standalone hardcoded #7A4E0A with no named
  /// token backing it. Reassigned to colorStateMorning to pair with the
  /// new badgeDueBackground.
  static const Color badgeDueText = colorStateMorning;

  static const Color badgeMissedBackground = colorStateRiskSurface;
  static const Color badgeMissedText = colorStateRisk;

  static const Color badgeSkippedBackground = colorStateSlippingSurface;
  static const Color badgeSkippedText = colorStateSlipping;

  /// Later badge background — rgba(28, 43, 30, 0.07) — very subtle forest tint.
  static const Color badgeLaterBackground = Color.fromRGBO(28, 43, 30, 0.07);
  static const Color badgeLaterText = colorTextTertiary;

  // ---------------------------------------------------------------------------
  // COMPONENT-SPECIFIC TOKENS
  // ---------------------------------------------------------------------------

  /// Streak chip fill — rgba(196, 135, 42, 0.18) — gold wash at low opacity.
  static const Color streakChipBackground = Color.fromRGBO(196, 135, 42, 0.18);

  /// Streak chip border — rgba(196, 135, 42, 0.32) — gold border at medium opacity.
  static const Color streakChipBorder = Color.fromRGBO(196, 135, 42, 0.32);

  static const Color navActiveBackground = colorStateConsistentSurface;
  static const Color navActiveLabel = colorStateConsistent;
  static const Color navInactiveLabel = colorTextTertiary;

  /// White at 72% opacity — for use on colorPrimary surfaces only.
  /// Passes WCAG AA at 12sp and 15sp.
  /// Apply at widget level — never bake into a TextStyle definition.
  static const Color streakLabelColor = Color.fromRGBO(255, 255, 255, 0.72);
}

// -----------------------------------------------------------------------------
// MEDADHERE STATE COLORS — ThemeExtension
//
// Accessed via: Theme.of(context).extension<MedAdhereStateColors>()!
//
// Carries the runtime-variable tokens that cannot be static constants:
//   - insightCardBorderActive: receives the active adherence state primary colour
//     at runtime. The Senior Dev sets this when constructing the extension instance
//     based on the user's current adherence state. It is not a fixed value.
//   - insightCardSurfaceActive: receives the active adherence state surface wash
//     at runtime. Paired with insightCardBorderActive. Values per state:
//       Cold Start  → AppColors.colorStateMorningSurface
//       Consistent  → AppColors.colorStateConsistentSurface
//       Slipping    → AppColors.colorStateSlippingSurface
//       At Risk     → AppColors.colorStateRiskSurface
// -----------------------------------------------------------------------------

class MedAdhereStateColors extends ThemeExtension<MedAdhereStateColors> {
  const MedAdhereStateColors({
    required this.insightCardBorderActive,
    required this.insightCardSurfaceActive,
  });

  /// The active adherence state primary colour applied to the insight card border.
  /// Set at runtime to one of: AppColors.colorStateMorning, colorStateConsistent,
  /// colorStateSlipping, or colorStateRisk — depending on the user's current arc state.
  final Color insightCardBorderActive;

  /// The active adherence state surface wash behind the insight card.
  /// Set at runtime to one of: AppColors.colorStateMorningSurface,
  /// colorStateConsistentSurface, colorStateSlippingSurface, or colorStateRiskSurface.
  final Color insightCardSurfaceActive;

  @override
  MedAdhereStateColors copyWith({
    Color? insightCardBorderActive,
    Color? insightCardSurfaceActive,
  }) => MedAdhereStateColors(
    insightCardBorderActive:
        insightCardBorderActive ?? this.insightCardBorderActive,
    insightCardSurfaceActive:
        insightCardSurfaceActive ?? this.insightCardSurfaceActive,
  );

  @override
  MedAdhereStateColors lerp(MedAdhereStateColors? other, double t) {
    if (other is! MedAdhereStateColors) return this;
    return MedAdhereStateColors(
      insightCardBorderActive: Color.lerp(
        insightCardBorderActive,
        other.insightCardBorderActive,
        t,
      )!,
      insightCardSurfaceActive: Color.lerp(
        insightCardSurfaceActive,
        other.insightCardSurfaceActive,
        t,
      )!,
    );
  }
}
