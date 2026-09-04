import 'package:flutter/material.dart';

/// Colour tokens for the temple design system — "Maroon & Gold".
///
/// Taken from the approved prototype: a deep devotional maroon leads, temple
/// gold carries the call-to-action and the ornaments, and everything sits on a
/// warm cream ground rather than white — easier to read on a phone in bright
/// outdoor light, which is how most of this village will see the site.
///
/// Named by role, not by hue, so a later visual revision changes these values
/// without touching any screen. Every colour used by the app must come from
/// here or from the generated [ColorScheme] — never as a literal in a widget.
class AppColors {
  const AppColors._();

  /// The primary devotional maroon (prototype `--primary`).
  static const Color maroon = Color(0xFF8B1E3F);

  /// Deeper maroon for emphasis and gradient ends (`--primary-dark`).
  static const Color maroonDeep = Color(0xFF65142D);

  /// The near-black maroon of the information strip above the header.
  static const Color maroonInk = Color(0xFF38101C);

  /// Footer ground — darker still, so the page ends deliberately.
  static const Color maroonFooter = Color(0xFF2D0D17);

  /// Bright temple gold (`--accent`). High-impact, but only legible as a
  /// *background* — never as small text on cream.
  static const Color gold = Color(0xFFF4B942);

  /// Text and icons that sit on [gold].
  static const Color onGold = Color(0xFF3B2300);

  /// A darkened gold that keeps contrast when used for icons and small accents
  /// on the cream ground.
  static const Color bronze = Color(0xFFA9761A);

  /// Page ground (`--cream`).
  static const Color cream = Color(0xFFFFF8EC);

  /// The alternating section band — a shade warmer than [cream].
  static const Color creamBand = Color(0xFFFFFAF2);

  /// Card and panel ground. The prototype keeps cards white so they lift off
  /// the cream page without needing a heavy shadow.
  static const Color panel = Color(0xFFFFFFFF);

  /// Hairline around cards (`border:1px solid #f1e2d8`).
  static const Color panelBorder = Color(0xFFF1E2D8);

  static const Color ink = Color(0xFF2F2926);
  static const Color muted = Color(0xFF6F655F);

  /// Footer body text on the dark ground.
  static const Color onFooter = Color(0xFFCDBCC1);

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB26A00);
  static const Color danger = Color(0xFFB3261E);

  /// The hero gradient: maroon washed with gold at the top right.
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [maroon, maroonDeep, Color(0xFF4A1225)],
    stops: [0, 0.55, 1],
  );

  /// The soft shadow the prototype puts under every card.
  static const List<BoxShadow> panelShadow = [
    BoxShadow(color: Color(0x1F502319), blurRadius: 30, offset: Offset(0, 10)),
  ];

  static ColorScheme lightScheme() =>
      ColorScheme.fromSeed(
        seedColor: maroon,
        brightness: Brightness.light,
      ).copyWith(
        primary: maroon,
        onPrimary: Colors.white,
        // Bronze rather than the bright gold: `secondary` colours icons and
        // small accent text on cream, where bright gold fails contrast.
        secondary: bronze,
        onSecondary: Colors.white,
        // Kept distinct from secondary so the admin status chips stay
        // distinguishable — "published" and "repeats weekly" must not look
        // like the same chip.
        tertiary: warning,
        onTertiary: Colors.white,
        error: danger,
        surface: cream,
        onSurface: ink,
        onSurfaceVariant: muted,
        outlineVariant: panelBorder,
      );

  static ColorScheme darkScheme() => ColorScheme.fromSeed(
    seedColor: maroon,
    brightness: Brightness.dark,
  ).copyWith(secondary: gold, tertiary: warning, error: danger);
}
