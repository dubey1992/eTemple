import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/theme/app_colors.dart';
import 'package:rkt_web/app/theme/app_spacing.dart';
import 'package:rkt_web/app/theme/app_theme.dart';

/// Pins the design system to the approved prototype.
///
/// These are the values the committee signed off on, so a change to any of them
/// should be a deliberate act with this test updated in the same commit — not
/// something that drifts in while somebody is adjusting a screen.
void main() {
  group('the Maroon & Gold palette', () {
    test('uses the prototype\'s colours', () {
      final scheme = AppColors.lightScheme();

      expect(scheme.primary, const Color(0xFF8B1E3F));
      expect(scheme.surface, const Color(0xFFFFF8EC));
      expect(AppColors.gold, const Color(0xFFF4B942));
      expect(AppColors.maroonFooter, const Color(0xFF2D0D17));
    });

    test('every status tone is a different colour', () {
      // These used to be borrowed from the scheme's containers, and the seed
      // generator produced the same colour for primaryContainer and
      // secondaryContainer — "published" and the event type chip became
      // indistinguishable the moment the palette changed.
      final scheme = AppColors.lightScheme();
      final tones = {
        scheme.surfaceContainerHighest,
        AppColors.positiveSurface,
        AppColors.warningSurface,
        AppColors.infoSurface,
        scheme.errorContainer,
      };

      expect(tones, hasLength(5));
    });

    test('small accent text is bronze, not the bright gold', () {
      // Bright gold on cream fails contrast at body sizes; it is a background
      // colour here, never a text colour on the page ground.
      expect(AppColors.lightScheme().secondary, AppColors.bronze);
      expect(AppColors.lightScheme().secondary, isNot(AppColors.gold));
    });
  });

  group('the built theme', () {
    test('gives cards the prototype corner and a hairline border', () {
      final theme = AppTheme.light();
      final shape = theme.cardTheme.shape! as RoundedRectangleBorder;

      expect(theme.cardTheme.elevation, 0);
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.lg));
      expect(AppRadius.lg, 18, reason: "the prototype's --radius");
      expect(shape.side.color, theme.colorScheme.outlineVariant);
    });

    test('keeps every primary action within the touch target', () {
      // A village site read on cheap phones: 48dp is the floor, not a target.
      final style = AppTheme.light().filledButtonTheme.style!;

      expect(style.minimumSize?.resolve({})?.height, greaterThanOrEqualTo(48));
    });

    test('the page ground and the app bar are the same colour', () {
      // The prototype's header is the page, separated by a hairline rather
      // than by a coloured bar.
      final theme = AppTheme.light();

      expect(theme.appBarTheme.backgroundColor, theme.colorScheme.surface);
      expect(theme.scaffoldBackgroundColor, theme.colorScheme.surface);
    });

    test('names the prototype font stack as a fallback', () {
      // Named, not bundled: nothing has to download before the site is
      // readable on a slow connection.
      expect(
        AppTheme.light().textTheme.bodyMedium?.fontFamilyFallback,
        containsAll(<String>['Noto Sans Devanagari']),
      );
    });

    test('the dark theme is built from the same tokens', () {
      final dark = AppTheme.dark();

      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(dark.cardTheme.elevation, 0);
    });
  });
}
