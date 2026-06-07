// ===
// FILE: app_theme.dart
// PATH: lib/theme/app_theme.dart
// RESPONSIBLE FOR: Master ThemeData assembly — the single file registered in MaterialApp
//
// USAGE:
//   MaterialApp(theme: AppTheme.light, ...)
//
// DARK THEME: Deferred. Light mode only per Visual Direction Document v1.0.
//   static ThemeData get dark — not implemented. Do not stub or scaffold.
//
// IMPORT CHAIN:
//   This file imports all five token files. No other file in the app imports
//   more than one or two token files. This is the single assembly point.
//
// RULES:
//   1. This file declares no values of its own.
//      Every colour, size, radius, duration, and curve traces to a named token.
//   2. insightCardBorderActive defaults to AppColors.colorStateDay (Consistent).
//      The Senior Dev overrides this at the widget tree level via
//      Theme.of(context).extension<MedAdhereStateColors>()!.copyWith(...)
//      based on the user's live adherence state. The theme default is never
//      shown in production — it is a safe construction fallback only.
//   3. Slide, scale, and hero page transitions are never used in this product.
//      Low-end hardware is the primary environment. Fade only.
// ===

import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_motion.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    // -----------------------------------------------------------------------
    // COLOUR SCHEME
    // Built explicitly from named tokens — ColorScheme.fromSeed() is not used
    // because it would generate values outside the approved token system.
    // -----------------------------------------------------------------------
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.colorPrimary,
      onPrimary: AppColors.colorOnPrimary,
      secondary: AppColors.colorAccent,
      onSecondary: AppColors.colorOnAccent,
      surface: AppColors.colorSurface,
      onSurface: AppColors.colorOnSurface,
      error: AppColors.colorStateEmber,
      onError: AppColors.colorOnPrimary,
      outline: AppColors.colorBorder,
      // Tonal container roles — not specified in VDD, mapped to nearest
      // warm token to avoid M3 defaults injecting cold system colours.
      primaryContainer: AppColors.colorStateDaySurface,
      onPrimaryContainer: AppColors.colorPrimary,
      secondaryContainer: AppColors.colorStateDuskSurface,
      onSecondaryContainer: AppColors.colorTextPrimary,
      tertiaryContainer: AppColors.colorStateMorningSurface,
      onTertiaryContainer: AppColors.colorTextPrimary,
      // Deprecated roles intentionally omitted: background, onBackground,
      // surfaceVariant. These were removed in Flutter 3.22+.
    ),

    // -----------------------------------------------------------------------
    // SCAFFOLD BACKGROUND
    // Warm Parchment — never pure white. Every screen starts here.
    // -----------------------------------------------------------------------
    scaffoldBackgroundColor: AppColors.colorSurface,

    // -----------------------------------------------------------------------
    // TEXT THEME
    // Maps the named scale styles to M3 TextTheme slots.
    // Special surface styles (insightCard, streak) are accessed via
    // Theme.of(context).extension<AppTypography>()! — not mapped here.
    // -----------------------------------------------------------------------
    textTheme: TextTheme(
      displayLarge: AppTypographyStyles.light.textDisplay,
      titleLarge: AppTypographyStyles.light.textScreenTitle,
      // titleLarge is the closest available unused M3 slot for a 26sp w600
      // page-level screen title. Visual Director to confirm or reassign slot.
      headlineMedium: AppTypographyStyles.light.textHeading1,
      headlineSmall: AppTypographyStyles.light.textHeading2,
      bodyLarge: AppTypographyStyles.light.textBody,
      bodyMedium: AppTypographyStyles.light.textBodySmall,
      bodySmall: AppTypographyStyles.light.textCaption,
      labelSmall: AppTypographyStyles.light.textLabel,
    ),

    // -----------------------------------------------------------------------
    // THEME EXTENSIONS
    // Runtime access points for dynamic and domain-specific tokens.
    // -----------------------------------------------------------------------
    extensions: [
      MedAdhereStateColors(
        // Defaults: Consistent state. Senior Dev overrides at widget tree level
        // based on the user's live adherence state.
        insightCardBorderActive: AppColors.colorStateDay,
        insightCardSurfaceActive: AppColors.colorStateDaySurface,
      ),
      AppTypographyStyles.light,
    ],

    // -----------------------------------------------------------------------
    // ELEVATED BUTTON
    // -----------------------------------------------------------------------
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: AppColors.colorOnPrimary,
        minimumSize: const Size(
          double.infinity,
          AppSpacing.buttonHeightPrimary,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.button),
        textStyle: AppTypographyStyles.light.textBody.copyWith(
          fontWeight: FontWeight.w500,
        ),
        elevation: 0,
      ),
    ),

    // -----------------------------------------------------------------------
    // CARD
    // -----------------------------------------------------------------------
    cardTheme: CardThemeData(
      color: AppColors.colorCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: const BorderSide(
          width: AppSpacing.medicationCardBorderWidth,
          color: AppColors.colorBorder,
        ),
      ),
    ),

    // -----------------------------------------------------------------------
    // NAVIGATION BAR
    // Labels are permanently visible — NavigationDestinationLabelBehavior.alwaysShow.
    // This is a hard rule from the Visual Direction Document.
    // Never hide navigation labels. Visibility is a trust signal for Mama Ngozi.
    // -----------------------------------------------------------------------
    navigationBarTheme: NavigationBarThemeData(
      height: AppSpacing.navBarHeight,
      backgroundColor: AppColors.colorCard,
      indicatorColor: AppColors.navActiveBackground,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppTypographyStyles.light.textNavLabel.copyWith(
                color: AppColors.navActiveLabel,
              )
            : AppTypographyStyles.light.textNavLabel.copyWith(
                color: AppColors.navInactiveLabel,
              ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? const IconThemeData(
                color: AppColors.colorStateConsistent,
                size: AppSpacing.navIconSize,
              )
            : const IconThemeData(
                color: AppColors.colorTextTertiary,
                size: AppSpacing.navIconSize,
              ),
      ),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),

    // -----------------------------------------------------------------------
    // BOTTOM SHEET
    // Top corners only — bottom corners are flush to screen edge.
    // -----------------------------------------------------------------------
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.colorCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadius.radiusXL),
          topRight: Radius.circular(AppRadius.radiusXL),
        ),
      ),
    ),

    // -----------------------------------------------------------------------
    // INPUT DECORATION
    // -----------------------------------------------------------------------
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.colorCard,
      border: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(
          color: AppColors.colorBorder,
          width: AppSpacing.medicationCardBorderWidth,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.card,
        borderSide: const BorderSide(
          color: AppColors.colorPrimary,
          width: AppSpacing.inputFocusBorderWidth,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space16,
        horizontal: AppSpacing.space20,
      ),
    ),

    // -----------------------------------------------------------------------
    // PAGE TRANSITIONS
    // Fade only. No slide, scale, or hero. Low-end hardware is the target.
    // FadeUpwardsPageTransitionsBuilder is the closest built-in Flutter
    // approximation. Duration and curve are set via the transition wrapper.
    // -----------------------------------------------------------------------
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _MedAdhereFadeTransitionBuilder(),
        TargetPlatform.iOS: _MedAdhereFadeTransitionBuilder(),
      },
    ),

    // -----------------------------------------------------------------------
    // DIALOG
    // Uses DialogThemeData — ThemeData.dialogBackgroundColor is deprecated.
    // -----------------------------------------------------------------------
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.colorCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.card),
    ),
  );
}

// ---------------------------------------------------------------------------
// CUSTOM FADE PAGE TRANSITION
// Applies AppMotion.durationTransition and AppMotion.curveTransition.
// No slide, scale, or hero component. Low-end hardware safe.
// ---------------------------------------------------------------------------

class _MedAdhereFadeTransitionBuilder extends PageTransitionsBuilder {
  const _MedAdhereFadeTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: AppMotion.curveTransition,
      ),
      child: child,
    );
    // Note: duration is set on the route itself, not the builder.
    // The Senior Dev sets transitionDuration: AppMotion.screenTransitionDuration
    // on any custom PageRoute. MaterialPageRoute uses its own default duration.
    // For full control, wrap screens in a custom PageRoute subclass.
  }
}
