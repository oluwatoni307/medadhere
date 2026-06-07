// ===
// FILE: app_radius.dart
// PATH: lib/theme/app_radius.dart
// RESPONSIBLE FOR: Full corner radius language for MedAdhere
//
// RADIUS RULES (non-negotiable — encode violations as purity failures):
//   1. Sharp corners (0dp) are never used. Anything below 4dp activates
//      clinical and institutional associations that contradict the product's
//      warmth and trust values.
//   2. Do not interpolate values outside this six-step scale.
//      No component may use a radius not present here.
//   3. No widget hardcodes a BorderRadius value. Every corner radius
//      references a token from this file.
//   4. Use the double constant (e.g. AppRadius.radiusMD) when you need
//      the raw value (e.g. inside a Radius.circular() or custom painter).
//      Use the BorderRadius convenience getter (e.g. AppRadius.card) when
//      wrapping a standard rectangular widget.
// ===

import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  // ---------------------------------------------------------------------------
  // RADIUS SCALE — six steps, nothing outside this range
  // ---------------------------------------------------------------------------

  /// 4dp — Badges, status pills, inline tags.
  /// Minimum radius in the product. Anything below this reads as institutional.
  static const double radiusXS = 4.0;

  /// 10dp — Chips, small inline elements.
  static const double radiusSM = 10.0;

  /// 16dp — Standard cards, containers.
  static const double radiusMD = 16.0;

  /// 20dp — Large cards, dose option rows.
  static const double radiusLG = 20.0;

  /// 28dp — Primary buttons, bottom sheet drag handles.
  static const double radiusXL = 28.0;

  /// 100dp — Streak chips, any fully-pill-shaped element.
  /// Use when the element should read as a capsule regardless of its width.
  static const double radiusPill = 100.0;

  // ---------------------------------------------------------------------------
  // BORDERRADIUS CONVENIENCE GETTERS
  // Pre-built BorderRadius.circular() values for each scale step.
  // Use these in widget decoration — never call BorderRadius.circular() inline.
  // ---------------------------------------------------------------------------

  /// Badges, status pills, inline tags.
  static final BorderRadius badge = BorderRadius.circular(radiusXS);

  /// Chips, small inline elements.
  static final BorderRadius chip = BorderRadius.circular(radiusSM);

  /// Standard cards, containers.
  static final BorderRadius card = BorderRadius.circular(radiusMD);

  /// Large cards, dose option rows.
  static final BorderRadius cardLarge = BorderRadius.circular(radiusLG);

  /// Primary buttons, bottom sheet drag handles.
  static final BorderRadius button = BorderRadius.circular(radiusXL);

  /// Streak chips, full-pill elements.
  /// Most-reached-for pill convenience getter in the product.
  static final BorderRadius pill = BorderRadius.circular(radiusPill);
}
