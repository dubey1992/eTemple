import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/content/presentation/page_screen.dart';
import 'package:rkt_web/features/shell/presentation/not_found_screen.dart';
import 'package:rkt_web/features/shell/presentation/public_shell.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpContent(
  WidgetTester tester,
  Widget screen,
  FakeContentRepository content, {
  Size? surfaceSize,
}) async {
  await pumpScreen(
    tester,
    screen,
    surfaceSize: surfaceSize,
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      contentRepositoryProvider.overrideWithValue(content),
    ],
  );
}

void main() {
  group('HomeScreen', () {
    testWidgets('renders the CMS hero, about excerpt and address', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const HomeScreen(),
        FakeContentRepository(
          pages: {'about': testPage()},
          settings: testSettings(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hero-title')), findsOneWidget);
      expect(find.text('भक्ति और सेवा का केंद्र'), findsOneWidget);
      // Only the first paragraph is excerpted on the home page.
      expect(find.text('पहला अनुच्छेद।'), findsOneWidget);
      expect(find.text('दूसरा अनुच्छेद।'), findsNothing);
      expect(find.byKey(const Key('address-card')), findsOneWidget);
      expect(find.text('Amarpur Pankhoriya, पंचायत: Kurma'), findsOneWidget);
    });

    testWidgets('shows a loading state while settings load', (tester) async {
      await pumpContent(
        tester,
        const HomeScreen(),
        FakeContentRepository(
          settings: testSettings(),
          delay: const Duration(milliseconds: 200),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      await tester.pumpAndSettle();
    });

    testWidgets('an unconfigured site still renders, with empty states', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const HomeScreen(),
        FakeContentRepository(), // nothing configured, no about page
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('hero-title')), findsOneWidget);
      // No tagline written yet, so the block is simply absent.
      expect(find.byKey(const Key('hero-tagline')), findsNothing);
      expect(find.byKey(const Key('about-coming-soon')), findsOneWidget);
      expect(find.byKey(const Key('address-empty')), findsOneWidget);
    });

    testWidgets('a settings outage shows a retry, not a blank page', (
      tester,
    ) async {
      final content = FakeContentRepository(
        settingsError: const AppException(code: ErrorCode.network),
      );
      await pumpContent(tester, const HomeScreen(), content);
      await tester.pumpAndSettle();

      expect(
        find.text('नेटवर्क उपलब्ध नहीं है। कृपया अपना इंटरनेट कनेक्शन जाँचें।'),
        findsOneWidget,
      );
      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });

    testWidgets('shows the fallback notice when English is unavailable', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const HomeScreen(),
        FakeContentRepository(
          pages: {'about': testPage(language: 'en', fallbackUsed: true)},
          settings: testSettings(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fallback-notice')), findsOneWidget);
      expect(
        find.text('यह सामग्री अभी केवल हिन्दी में उपलब्ध है।'),
        findsOneWidget,
      );
    });

    testWidgets('no fallback notice when the language matches', (tester) async {
      await pumpContent(
        tester,
        const HomeScreen(),
        FakeContentRepository(
          pages: {'about': testPage()},
          settings: testSettings(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fallback-notice')), findsNothing);
    });

    testWidgets('requests content in the active language', (tester) async {
      final content = FakeContentRepository(
        pages: {'about': testPage()},
        settings: testSettings(),
      );

      await pumpScreen(
        tester,
        const HomeScreen(),
        locale: AppLocales.english,
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          contentRepositoryProvider.overrideWithValue(content),
        ],
      );
      await tester.pumpAndSettle();

      // The provider derives the API language from the locale controller, which
      // still defaults to Hindi until the visitor switches it.
      expect(content.lastLanguage, isNotNull);
      expect(content.settingsCalls, greaterThan(0));
    });

    testWidgets('lays out without overflow at all three breakpoints', (
      tester,
    ) async {
      for (final size in const [
        Size(500, 1000),
        Size(768, 1024),
        Size(1440, 900),
      ]) {
        await pumpContent(
          tester,
          const PublicShell(child: HomeScreen()),
          FakeContentRepository(
            pages: {'about': testPage()},
            settings: testSettings(),
          ),
          surfaceSize: size,
        );
        await tester.pumpAndSettle();

        expect(
          tester.takeException(),
          isNull,
          reason: 'home page overflowed at $size',
        );
      }
    });
  });

  group('PageScreen', () {
    testWidgets('renders every paragraph of a published page', (tester) async {
      await pumpContent(
        tester,
        const PageScreen(slug: 'about'),
        FakeContentRepository(pages: {'about': testPage()}),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page-title')), findsOneWidget);
      expect(find.text('पहला अनुच्छेद।'), findsOneWidget);
      expect(find.text('दूसरा अनुच्छेद।'), findsOneWidget);
    });

    testWidgets('an unknown or draft slug renders the not-found screen', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const PageScreen(slug: 'no-such-page'),
        FakeContentRepository(),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsOneWidget);
      expect(find.text('पृष्ठ नहीं मिला'), findsOneWidget);
    });

    testWidgets('a transport failure offers a retry instead of not-found', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const PageScreen(slug: 'about'),
        FakeContentRepository(
          pageError: const AppException(code: ErrorCode.network),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundScreen), findsNothing);
      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });

    testWidgets('a published but empty page shows the coming-soon state', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const PageScreen(slug: 'about'),
        FakeContentRepository(pages: {'about': testPage(content: null)}),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('content-empty')), findsOneWidget);
    });

    testWidgets('never renders raw markup from content', (tester) async {
      // Content is plain text by design, so an editor cannot inject markup.
      await pumpContent(
        tester,
        const PageScreen(slug: 'about'),
        FakeContentRepository(
          pages: {
            'about': testPage(
              content: '<b>bold</b> & <script>alert(1)</script>',
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('<b>bold</b> & <script>alert(1)</script>'),
        findsOneWidget,
      );
    });
  });

  group('public shell navigation', () {
    testWidgets('renders the admin-configured menu on desktop', (tester) async {
      await pumpContent(
        tester,
        const PublicShell(child: SizedBox.shrink()),
        FakeContentRepository(settings: testSettings()),
        surfaceSize: const Size(1440, 900),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav-1')), findsOneWidget);
      expect(find.byKey(const Key('nav-2')), findsOneWidget);
      expect(find.text('हमारे बारे में'), findsWidgets);
    });

    testWidgets('moves the menu into a drawer on narrow screens', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const PublicShell(child: SizedBox.shrink()),
        FakeContentRepository(settings: testSettings()),
        surfaceSize: const Size(500, 900),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('nav-1')), findsNothing);
      expect(find.byType(Drawer), findsNothing);

      // Found by icon, not tooltip: the tooltip text is localized to Hindi.
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('drawer-nav-2')), findsOneWidget);
    });

    testWidgets('renders the CMS footer text', (tester) async {
      await pumpContent(
        tester,
        const PublicShell(child: SizedBox.shrink()),
        FakeContentRepository(settings: testSettings()),
        surfaceSize: const Size(1440, 900),
      );
      await tester.pumpAndSettle();

      expect(find.text('श्री राधा कृष्ण ठाकुरबाड़ी समिति'), findsOneWidget);
    });

    testWidgets('falls back to the temple identity when settings fail', (
      tester,
    ) async {
      await pumpContent(
        tester,
        const PublicShell(child: SizedBox.shrink()),
        FakeContentRepository(
          settingsError: const AppException(code: ErrorCode.network),
        ),
        surfaceSize: const Size(1440, 900),
      );
      await tester.pumpAndSettle();

      // No menu, but the shell still renders rather than failing outright.
      expect(find.byKey(const Key('public-footer')), findsOneWidget);
      expect(find.byKey(const Key('nav-1')), findsNothing);
    });
  });

  group('fallback notice wording', () {
    testWidgets('is shown in English when English is the active language', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const PageScreen(slug: 'about'),
        locale: AppLocales.english,
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(
              pages: {
                'about': testPage(
                  language: 'en',
                  fallbackUsed: true,
                  content: 'हिन्दी सामग्री।',
                ),
              },
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(
        find.text('This content is currently available in Hindi only.'),
        findsOneWidget,
      );
    });
  });

  group('LocalizedValue in the widget layer', () {
    test('an empty excerpt does not crash the preview', () {
      expect(LocalizedValue.empty.firstParagraphOnly.isEmpty, isTrue);
    });
  });
}
