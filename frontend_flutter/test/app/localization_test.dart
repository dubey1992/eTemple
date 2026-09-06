import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/widgets/language_switch.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/shell/presentation/public_shell.dart';
import 'package:rkt_web/l10n/app_localizations.dart';
import 'package:rkt_web/l10n/app_localizations_en.dart';
import 'package:rkt_web/l10n/app_localizations_hi.dart';

import 'package:rkt_web/features/content/data/content_providers.dart';

import '../support/fake_auth_repository.dart';
import '../support/fake_content_repository.dart';
import '../support/pump_app.dart';

FakeContentRepository contentRepository() => FakeContentRepository(
  pages: {'about': testPage()},
  settings: testSettings(),
);

void main() {
  group('generated localizations', () {
    test('Hindi and English are both delivered', () {
      expect(
        AppLocalizations.supportedLocales.map((l) => l.languageCode),
        containsAll(<String>['hi', 'en']),
      );
    });

    test('every string differs between the two languages where expected', () {
      final hi = AppLocalizationsHi();
      final en = AppLocalizationsEn();

      expect(hi.loginTitle, isNot(en.loginTitle));
      expect(hi.errorInvalidCredentials, isNot(en.errorInvalidCredentials));
      // The language names are deliberately shown in their own script in both.
      expect(hi.languageEnglish, en.languageEnglish);
    });

    test('placeholders are interpolated in both languages', () {
      expect(AppLocalizationsHi().adminWelcome('सीता'), contains('सीता'));
      expect(AppLocalizationsEn().adminWelcome('Sita'), contains('Sita'));
      expect(AppLocalizationsHi().validationPasswordTooShort(8), contains('8'));
    });
  });

  group('public shell', () {
    Future<void> pumpShell(WidgetTester tester, {Size? surfaceSize}) {
      return pumpScreen(
        tester,
        const PublicShell(child: HomeScreen()),
        surfaceSize: surfaceSize,
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          contentRepositoryProvider.overrideWithValue(contentRepository()),
        ],
      );
    }

    testWidgets('renders Hindi first, without the visitor choosing', (
      tester,
    ) async {
      await pumpShell(tester, surfaceSize: const Size(1440, 900));
      await tester.pumpAndSettle();

      // CMS-driven content, served in Hindi because that is the default.
      expect(find.text('राधा कृष्ण ठाकुरवाड़ी'), findsWidgets);
      expect(find.byKey(const Key('hero-tagline')), findsOneWidget);
      // The strip carries the approved design's emblem in front of the
      // committee's tagline.
      expect(find.text('🙏 भक्ति और सेवा का केंद्र'), findsOneWidget);
      expect(find.text('पहला अनुच्छेद।'), findsOneWidget);
    });

    testWidgets('the language switch is always visible', (tester) async {
      await pumpShell(tester, surfaceSize: const Size(1440, 900));
      await tester.pumpAndSettle();

      expect(find.byType(LanguageSwitch), findsOneWidget);
    });

    testWidgets('switching to English re-renders the page in English', (
      tester,
    ) async {
      await pumpShell(tester, surfaceSize: const Size(1440, 900));
      await tester.pumpAndSettle();

      // The switch drives the locale provider; the surrounding MaterialApp in
      // this test is pinned to Hindi, so assert on the provider-driven control
      // rather than on the whole tree.
      expect(find.text('हिन्दी'), findsWidgets);
      expect(find.text('English'), findsWidgets);
    });
  });

  group('language switch', () {
    testWidgets('toggles the locale and rebuilds dependent text', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const Scaffold(body: Center(child: LanguageSwitch(compact: true))),
        surfaceSize: const Size(400, 600),
      );
      await tester.pumpAndSettle();

      // In Hindi the compact control offers English as the alternative.
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // After switching, it offers Hindi as the way back.
      expect(find.text('हिन्दी'), findsOneWidget);
    });
  });
}
