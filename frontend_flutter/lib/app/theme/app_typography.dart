import 'package:flutter/material.dart';

/// Typography tokens.
///
/// No font file is bundled on purpose: Devanagari and Latin are both rendered
/// with the platform/browser font stack, which keeps the web bundle small on the
/// low-bandwidth connections this site is built for. Sizes are tuned so Hindi
/// (which has taller glyph clusters) stays legible at the same scale as English.
class AppTypography {
  const AppTypography._();

  /// Extra line height so Devanagari matras are never clipped.
  static const double bodyHeight = 1.55;
  static const double headingHeight = 1.25;

  static TextTheme textTheme(ColorScheme scheme) {
    final base = Typography.material2021().black;

    return base
        .copyWith(
          displaySmall: base.displaySmall?.copyWith(
            height: headingHeight,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: base.headlineMedium?.copyWith(
            height: headingHeight,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: base.headlineSmall?.copyWith(
            height: headingHeight,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.titleLarge?.copyWith(
            height: headingHeight,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: base.bodyLarge?.copyWith(height: bodyHeight),
          bodyMedium: base.bodyMedium?.copyWith(height: bodyHeight),
          bodySmall: base.bodySmall?.copyWith(height: bodyHeight),
        )
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
  }
}
