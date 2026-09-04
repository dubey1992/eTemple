import 'package:flutter/material.dart';

/// Colour tokens for the temple design system — "Rose & Peacock".
///
/// The palette is the deity pair this temple is named for: Radha's rose-gold
/// leads, Krishna's peacock blue answers it, and temple gold carries the
/// devotional accents. Named by role, not by hue, so a later visual revision
/// changes these values without touching any screen. Every colour used by the
/// app must come from here or from the generated [ColorScheme] — never as a
/// literal in a widget.
class AppColors {
  const AppColors._();

  /// Radha's rose — the primary devotional accent.
  static const Color rose = Color(0xFFB5426B);

  /// Deeper rose for headings and emphasis on light surfaces.
  static const Color roseDeep = Color(0xFF8E2F52);

  /// Krishna's peacock blue — the secondary accent (मोरपंख).
  static const Color peacock = Color(0xFF1F6F78);

  /// Temple gold, used for the invocation and small ornamental marks.
  static const Color gold = Color(0xFFC9971F);

  /// Warm ivory background, easier to read than pure white in bright
  /// outdoor light on a phone.
  static const Color ivory = Color(0xFFFFF7F4);

  static const Color ink = Color(0xFF2A1B22);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFB3261E);

  static ColorScheme lightScheme() => ColorScheme.fromSeed(
    seedColor: rose,
    brightness: Brightness.light,
  ).copyWith(secondary: peacock, tertiary: gold, error: danger, surface: ivory);

  static ColorScheme darkScheme() => ColorScheme.fromSeed(
    seedColor: rose,
    brightness: Brightness.dark,
  ).copyWith(secondary: peacock, tertiary: gold, error: danger);
}
