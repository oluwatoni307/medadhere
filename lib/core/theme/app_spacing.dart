// ===
// FILE: app_spacing.dart
// PATH: lib/theme/app_spacing.dart
// RESPONSIBLE FOR: All spacing constants on the 8dp baseline grid
//
// SPACING RULES (non-negotiable — encode violations as purity failures):
//   1. No widget hardcodes a padding, margin, height, width, or gap value.
//      Every spatial value in the app references a token from this file.
//   2. The baseline grid is 8dp. Values marked [OFF-GRID] are intentional
//      component exceptions documented in the Visual Direction Document.
//      Do not "correct" them to the nearest 8dp multiple.
//   3. Do not add new spacing values outside this file. If a widget needs
//      a spacing value not present here, escalate to the Visual Director.
// ===

class AppSpacing {
  AppSpacing._();

  // ---------------------------------------------------------------------------
  // BASE GRID
  // ---------------------------------------------------------------------------

  /// The atomic unit. All standard scale values are multiples of this.
  static const double spaceBase = 8.0;

  // ---------------------------------------------------------------------------
  // STANDARD SCALE
  // Values marked [OFF-GRID] are intentional Visual Direction Document exceptions.
  // ---------------------------------------------------------------------------

  /// 2dp — [OFF-GRID] Fine detail spacing: hairline gaps, icon nudges.
  static const double space2 = 2.0;

  /// 4dp — half-base: tight internal spacing within compact components.
  static const double space4 = 4.0;

  /// 8dp — 1× base: standard item gap, icon-to-label spacing.
  static const double space8 = 8.0;

  /// 10dp — [OFF-GRID] Dose option vertical gap exception (see doseOptionVerticalGap).
  static const double space10 = 10.0;

  /// 12dp — 1.5× base: compact card internal spacing.
  static const double space12 = 12.0;

  /// 16dp — 2× base: standard screen margin, card padding baseline.
  static const double space16 = 16.0;

  /// 18dp — [OFF-GRID] Insight card vertical padding exception (see insightCardPaddingVertical).
  static const double space18 = 18.0;

  /// 20dp — 2.5× base: insight card horizontal padding, viewport vertical margin.
  static const double space20 = 20.0;

  /// 24dp — 3× base: section gap, generous card internal spacing.
  static const double space24 = 24.0;

  /// 28dp — [OFF-GRID] Between-section spacer exception.
  static const double space28 = 28.0;

  /// 32dp — 4× base: large section separation.
  static const double space32 = 32.0;

  /// 40dp — 5× base: generous vertical breathing room between major blocks.
  static const double space40 = 40.0;

  /// 48dp — 6× base: minimum touch target height reference.
  static const double space48 = 48.0;

  // ---------------------------------------------------------------------------
  // SEMANTIC COMPONENT TOKENS
  // Widgets reference these names. Never reference raw scale values directly
  // in widget files — always use the semantic name for the component context.
  // ---------------------------------------------------------------------------

  // — Insight Card —

  /// Vertical padding inside the insight card surface.
  static const double insightCardPaddingVertical =
      18.0; // [OFF-GRID] — intentional

  /// Horizontal padding inside the insight card surface.
  static const double insightCardPaddingHorizontal = 20.0;

  /// Thickness of the insight card's active left border stroke.
  /// Rendering correction: 3dp in a hue-adjacent colour on a low-gamut panel
  /// is invisible. Confirmed invisible in screenshot audit. Not a design
  /// preference change.
  static const double insightCardBorderWidth = 5.0; // [OFF-GRID] — intentional

  // — Dose Options —

  /// Minimum tappable height of a single dose option row.
  static const double doseOptionMinHeight = 56.0;

  /// Vertical gap between consecutive dose option rows. [OFF-GRID] — intentional.
  static const double doseOptionVerticalGap = 9.0;

  /// Diameter of the leading selection circle on a dose option row.
  static const double doseOptionLeadingCircle =
      12.0; // [OFF-GRID] — intentional

  // — Medication Card —

  /// Border width of a medication card in its default (non-active) state.
  static const double medicationCardBorderWidth = 0.5; // [OFF-GRID] — hairline

  /// Border width of a medication card in its active/selected state.
  static const double medicationCardActiveBorderWidth =
      1.5; // [OFF-GRID] — intentional

  /// Vertical extent of the divider between medication card sections.
  static const double medicationCardDividerVertical =
      10.0; // [OFF-GRID] — intentional

  /// Border width for pattern observation surfaces and cold start card.
  static const double observationCardBorderWidth =
      1.0; // [OFF-GRID] — intentional

  /// Border width of a focused input field.
  /// Distinct from medicationCardActiveBorderWidth — different component, same value.
  static const double inputFocusBorderWidth = 1.5; // [OFF-GRID] — intentional

  // — Buttons —

  /// Standard height for primary action buttons.
  static const double buttonHeightPrimary = 56.0;

  /// Absolute minimum height for any tappable button element.
  static const double buttonHeightMin = 56.0;

  /// For inline card action buttons only — Log, Done, compact actions.
  /// Not for full-width standalone primary actions which use buttonHeightPrimary at 56.
  /// [OFF-GRID] — intentional. Subordinate to card while meeting touch target requirements.
  static const double buttonHeightCard = 44.0;

  // — Navigation Bar —

  /// Total height of the bottom navigation bar container.
  static const double navBarHeight = 64.0;

  /// Width of the icon container within a nav bar item.
  static const double navIconContainerWidth = 40.0;

  /// Height of the icon container within a nav bar item.
  static const double navIconContainerHeight = 28.0;

  /// Size of the icon glyph within the nav bar icon container.
  static const double navIconSize = 22.0; // [OFF-GRID] — intentional

  /// Minimum touch target size for nav bar items (WCAG 2.5.5 compliance).
  static const double navTouchTarget = 48.0;

  /// Height of NavHeader — custom AppBar equivalent for non-tab screens.
  static const double navHeaderHeight = 56.0;

  // — Touch Targets —

  /// Global minimum touch target dimension for all interactive elements.
  /// Applies to buttons, icons, and any tappable surface.
  static const double touchTargetMin = 48.0;

  // — Icons —

  /// Standard in-content icon size — clock, back arrow, action icons.
  static const double iconSizeStandard = 24.0; // [OFF-GRID] — intentional

  // — Viewport —

  /// Horizontal margin between screen edge and content column.
  /// 20dp establishes a clear outer-to-inner nesting relationship against
  /// 16dp card internal padding. At 16dp both values were equal, making
  /// nesting hierarchy invisible to the eye.
  static const double viewportMarginHorizontal = 20.0;

  /// Vertical margin at top and bottom of scrollable screen content.
  static const double viewportMarginVertical = 20.0;

  // — Multi-step Flows —

  /// Height of the step progress bar in multi-step flows.
  /// Intentionally thin — structural indicator, not a primary visual element.
  static const double progressBarHeight = 4.0;

  // — Colour Picker —

  /// Diameter of a colour picker swatch circle, used in category creation
  /// colour selection only.
  static const double pickerSwatchSize = 24.0;
}
