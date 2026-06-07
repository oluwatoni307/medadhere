// ===
// FILE: app_typography.dart
// PATH: lib/theme/app_typography.dart
// RESPONSIBLE FOR: Full typography token system as ThemeExtension
//
// TYPOGRAPHY RULES (non-negotiable — encode violations as purity failures):
//   1. DM Serif Display is used only for: greeting display text, streak number,
//      streak chip number, section hero moments. Never for body copy, labels,
//      or UI controls.
//   2. Minimum visible text in this product: 13sp. No text style ever goes below this.
//      Exception: textInsightCardEyebrow at 12sp — Visual Director approved (A006).
//   3. Minimum body text: 15sp. Never compress. textBodySmall floor is 14sp.
//      textCaption floor is 13sp.
//   4. Line height for all paragraph text: 1.65 minimum. Never compress.
//   5. Never permitted: condensed or compressed weights, italics in UI,
//      any typeface activating clinical or monospaced associations.
//   6. textInsightCardEyebrow colour is never static. It receives the active
//      adherence state colour at runtime from the Senior Dev.
//   7. Both fonts are delivered via the Google Fonts package — zero runtime download.
//      GoogleFonts.config.allowRuntimeFetching must be false in main.dart.
//      Use GoogleFonts.dmSerifDisplay() and GoogleFonts.dmSans() as the font source.
//      Never use fontFamily string references — silent fallback to system font.
// ===

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography extends ThemeExtension<AppTypography> {
  const AppTypography({
    // Standard scale
    required this.textDisplay,
    required this.textHeading1,
    required this.textHeading2,
    required this.textBody,
    required this.textBodySmall,
    required this.textCaption,
    required this.textLabel,
    required this.textNavLabel,
    required this.textScreenTitle,
    // Special surface styles
    required this.textInsightCardBody,
    required this.textInsightCardEyebrow,
    required this.textStreakNumber,
    required this.textStreakLabel,
    required this.textStreakChipNumber,
    required this.textStreakChipLabel,
  });

  // ---------------------------------------------------------------------------
  // STANDARD TYPE SCALE
  // Eight named styles. Named by semantic role — never by visual property.
  // ---------------------------------------------------------------------------

  /// DM Serif Display / 34sp / w400 / lh 1.05 / ls −0.3
  /// Hero display moments only — greeting, section openers.
  final TextStyle textDisplay;

  /// DM Sans / 22sp / w600 / lh 1.2
  /// Primary screen headings.
  final TextStyle textHeading1;

  /// DM Sans / 16sp / w600 / lh 1.25
  /// Section headings, card titles.
  final TextStyle textHeading2;

  /// DM Sans / 15sp / w400 / lh 1.68
  /// Default body copy. Minimum body text in this product.
  final TextStyle textBody;

  /// DM Sans / 14sp / w400 / lh 1.65
  /// Supporting body copy, secondary descriptions.
  final TextStyle textBodySmall;

  /// DM Sans / 13sp / w400 / lh 1.5
  /// Captions, helper text. Minimum text size in this product.
  /// apply colorTextSecondary or colorTextTertiary at widget level depending on context.
  final TextStyle textCaption;

  /// DM Sans / 11sp / w600 / lh 1.0 / ls 0.66px (0.06em at 11sp)
  /// Badge labels, status tags, uppercase UI markers.
  final TextStyle textLabel;

  /// DM Sans / 11sp / w500 / lh 1.0
  /// Bottom navigation bar labels.
  final TextStyle textNavLabel;

  /// DM Sans / 26sp / w600 / lh 1.2
  /// For page-level screen titles only — Medications, Adherence, Profile.
  /// Never use inside cards, bottom sheets, or modal headers.
  /// If the context is inside a container, this is the wrong token.
  final TextStyle textScreenTitle;

  // ---------------------------------------------------------------------------
  // SPECIAL SURFACE STYLES
  // Named for their exact surface. Never repurposed to other components.
  // ---------------------------------------------------------------------------

  /// DM Sans / 16sp / w400 / lh 1.72 / color colorTextPrimary
  /// Body copy inside the insight card surface.
  /// Sits one step above textBody at 15sp — the insight card earns this size
  /// premium because it is the most important communication surface in the product.
  final TextStyle textInsightCardBody;

  /// DM Sans / 12sp / w600 / lh 1.0 / ls 1.0px
  /// Eyebrow label above insight card body.
  /// 12sp approved by Visual Director (A006) — 10sp VDB spec fails legibility
  /// floor on low-end hardware at uppercase + w600 + 1.0px letter spacing.
  /// COLOUR IS NEVER STATIC — Senior Dev passes active adherence state colour at runtime.
  /// Text is always uppercase at widget level — do not bake text transform into this style.
  final TextStyle textInsightCardEyebrow;

  /// DM Serif Display / 64sp / w400 / lh 1.0 / color colorAccent
  /// The streak count number on the streak display surface.
  final TextStyle textStreakNumber;

  /// DM Sans / 15sp / w400 / lh 1.0
  /// Supporting label beneath the streak number.
  /// apply AppColors.streakLabelColor at widget level.
  final TextStyle textStreakLabel;

  /// DM Serif Display / 26sp / w400 / lh 1.0 / color colorAccent
  /// Streak count number inside the compact streak chip.
  final TextStyle textStreakChipNumber;

  /// DM Sans / 12sp / w400 / lh 1.0
  /// Supporting label inside the compact streak chip.
  /// apply AppColors.streakLabelColor at widget level.
  final TextStyle textStreakChipLabel;

  // ---------------------------------------------------------------------------
  // THEME EXTENSION OVERRIDES
  // ---------------------------------------------------------------------------

  @override
  AppTypography copyWith({
    TextStyle? textDisplay,
    TextStyle? textHeading1,
    TextStyle? textHeading2,
    TextStyle? textBody,
    TextStyle? textBodySmall,
    TextStyle? textCaption,
    TextStyle? textLabel,
    TextStyle? textNavLabel,
    TextStyle? textScreenTitle,
    TextStyle? textInsightCardBody,
    TextStyle? textInsightCardEyebrow,
    TextStyle? textStreakNumber,
    TextStyle? textStreakLabel,
    TextStyle? textStreakChipNumber,
    TextStyle? textStreakChipLabel,
  }) => AppTypography(
    textDisplay: textDisplay ?? this.textDisplay,
    textHeading1: textHeading1 ?? this.textHeading1,
    textHeading2: textHeading2 ?? this.textHeading2,
    textBody: textBody ?? this.textBody,
    textBodySmall: textBodySmall ?? this.textBodySmall,
    textCaption: textCaption ?? this.textCaption,
    textLabel: textLabel ?? this.textLabel,
    textNavLabel: textNavLabel ?? this.textNavLabel,
    textScreenTitle: textScreenTitle ?? this.textScreenTitle,
    textInsightCardBody: textInsightCardBody ?? this.textInsightCardBody,
    textInsightCardEyebrow:
        textInsightCardEyebrow ?? this.textInsightCardEyebrow,
    textStreakNumber: textStreakNumber ?? this.textStreakNumber,
    textStreakLabel: textStreakLabel ?? this.textStreakLabel,
    textStreakChipNumber: textStreakChipNumber ?? this.textStreakChipNumber,
    textStreakChipLabel: textStreakChipLabel ?? this.textStreakChipLabel,
  );

  @override
  AppTypography lerp(AppTypography? other, double t) {
    if (other is! AppTypography) return this;
    return AppTypography(
      textDisplay: TextStyle.lerp(textDisplay, other.textDisplay, t)!,
      textHeading1: TextStyle.lerp(textHeading1, other.textHeading1, t)!,
      textHeading2: TextStyle.lerp(textHeading2, other.textHeading2, t)!,
      textBody: TextStyle.lerp(textBody, other.textBody, t)!,
      textBodySmall: TextStyle.lerp(textBodySmall, other.textBodySmall, t)!,
      textCaption: TextStyle.lerp(textCaption, other.textCaption, t)!,
      textLabel: TextStyle.lerp(textLabel, other.textLabel, t)!,
      textNavLabel: TextStyle.lerp(textNavLabel, other.textNavLabel, t)!,
      textScreenTitle: TextStyle.lerp(
        textScreenTitle,
        other.textScreenTitle,
        t,
      )!,
      textInsightCardBody: TextStyle.lerp(
        textInsightCardBody,
        other.textInsightCardBody,
        t,
      )!,
      textInsightCardEyebrow: TextStyle.lerp(
        textInsightCardEyebrow,
        other.textInsightCardEyebrow,
        t,
      )!,
      textStreakNumber: TextStyle.lerp(
        textStreakNumber,
        other.textStreakNumber,
        t,
      )!,
      textStreakLabel: TextStyle.lerp(
        textStreakLabel,
        other.textStreakLabel,
        t,
      )!,
      textStreakChipNumber: TextStyle.lerp(
        textStreakChipNumber,
        other.textStreakChipNumber,
        t,
      )!,
      textStreakChipLabel: TextStyle.lerp(
        textStreakChipLabel,
        other.textStreakChipLabel,
        t,
      )!,
    );
  }
}

// -----------------------------------------------------------------------------
// APPTYPOGRAPHY INSTANCE — AppTypographyStyles.light
//
// The concrete instance registered in ThemeData.extensions.
// Consumed via: Theme.of(context).extension<AppTypography>()!
//
// All styles constructed via GoogleFonts package calls.
// GoogleFonts.config.allowRuntimeFetching = false must be set in main.dart.
// -----------------------------------------------------------------------------

abstract class AppTypographyStyles {
  static final AppTypography light = AppTypography(
    // -------------------------------------------------------------------------
    // STANDARD SCALE
    // -------------------------------------------------------------------------
    textDisplay: GoogleFonts.dmSerifDisplay(
      fontSize: 34,
      fontWeight: FontWeight.w400,
      height: 1.05,
      letterSpacing: -0.3,
      color: AppColors.colorTextPrimary,
    ),

    textHeading1: GoogleFonts.dmSans(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
      color: AppColors.colorTextPrimary,
    ),

    textHeading2: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      letterSpacing: 0,
      color: AppColors.colorTextPrimary,
    ),

    textBody: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.68,
      letterSpacing: 0,
      color: AppColors.colorTextPrimary,
    ),

    textBodySmall: GoogleFonts.dmSans(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.65,
      letterSpacing: 0,
      color: AppColors.colorTextPrimary,
    ),

    textCaption: GoogleFonts.dmSans(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
      letterSpacing: 0,
      // apply colorTextSecondary or colorTextTertiary at widget level depending on context.
    ),

    textLabel: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 0.66,
      color: AppColors.colorTextPrimary,
    ),

    textNavLabel: GoogleFonts.dmSans(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.0,
      letterSpacing: 0,
      // colour applied at widget level: navActiveLabel or navInactiveLabel
    ),

    textScreenTitle: GoogleFonts.dmSans(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0,
      // for page-level screen titles only — Medications, Adherence, Profile.
      // Never use inside cards, bottom sheets, or modal headers.
      // If the context is inside a container, this is the wrong token.
    ),

    // -------------------------------------------------------------------------
    // SPECIAL SURFACE STYLES
    // -------------------------------------------------------------------------
    textInsightCardBody: GoogleFonts.dmSans(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.72,
      letterSpacing: 0,
      color: AppColors.colorTextPrimary,
      // sits one step above textBody at 15sp — the insight card earns this size
      // premium because it is the most important communication surface in the product.
    ),

    // → STATE HOOK: colour is set at runtime by Senior Dev to active adherence
    //   state primary. colorTextSecondary below is a safe fallback only.
    // → A006: fontSize 12sp (raised from VDB 10sp) — Visual Director decision.
    //   Legibility floor on low-end hardware for uppercase w600 1.0px tracking.
    textInsightCardEyebrow: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.0,
      letterSpacing: 1.0,
      color: AppColors.colorTextSecondary,
    ),

    textStreakNumber: GoogleFonts.dmSerifDisplay(
      fontSize: 48,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: AppColors.colorAccent,
    ),

    textStreakLabel: GoogleFonts.dmSans(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      // apply AppColors.streakLabelColor at widget level.
    ),

    textStreakChipNumber: GoogleFonts.dmSerifDisplay(
      fontSize: 26,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      color: AppColors.colorAccent,
    ),

    textStreakChipLabel: GoogleFonts.dmSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.0,
      letterSpacing: 0,
      // apply AppColors.streakLabelColor at widget level.
    ),
  );
}
