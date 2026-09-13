import 'package:flutter/material.dart';

/// Typography tokens.
///
/// **Poppins**, bundled with the application, since 2026-09-13. Before that no
/// font was shipped at all and both scripts were left to whatever the reader's
/// device had — which kept the download small, and meant the site looked
/// different on every machine.
///
/// Poppins was checked against this site before it was adopted, not after:
/// the Devanagari block is present (94 codepoints, every letter these pages
/// use), GSUB and GPOS both declare `deva` and `dev2` so conjuncts such as
/// ष्ण form properly rather than breaking apart, and ₹ and the danda । are
/// both drawn. A Latin-only face would have turned the Hindi site — which is
/// the default one — into a page of empty boxes.
///
/// It costs about 790 KB across five weights, downloaded once and then cached
/// for a year under a hashed path. That is a real price on a village
/// connection and it was accepted deliberately; the reason the number is not
/// larger is that these files carry Latin and Devanagari and almost nothing
/// else.
class AppTypography {
  const AppTypography._();

  /// The bundled family. Named here rather than written at each call site so
  /// there is one place to change it.
  static const String fontFamily = 'Poppins';

  /// What draws a glyph Poppins does not have.
  ///
  /// Still needed, and not a leftover: the pages use emoji (🙏 📍 ✨) that no
  /// text face carries, and a reader may paste a name in a script this font
  /// has never heard of. Without a fallback those become empty boxes rather
  /// than falling through to something that can draw them.
  static const List<String> fontFallback = [
    'Noto Sans Devanagari',
    'Segoe UI',
    'Arial',
  ];

  /// Extra line height so Devanagari matras are never clipped.
  static const double bodyHeight = 1.55;
  static const double headingHeight = 1.25;

  static TextTheme textTheme(ColorScheme scheme) {
    final base = Typography.material2021().black;

    // The fallback is applied *after* copyWith, not before: copyWith replaces
    // whole TextStyles taken from `base`, which would drop an earlier apply().
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
        .apply(
          bodyColor: scheme.onSurface,
          displayColor: scheme.onSurface,
          fontFamily: fontFamily,
          fontFamilyFallback: fontFallback,
        );
  }
}
