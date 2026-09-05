import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/domain/content_highlight.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/shell/presentation/public_shell.dart';

import '../../support/fake_accounts_repository.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_temple_repository.dart';
import '../../support/pump_app.dart';

/// The public site against the committee's approved design.
///
/// Every case here is a difference somebody found by reading the two side by
/// side (`docs/PROTOTYPE_CONTENT_MATCH.md`). They are cheap to reintroduce —
/// one deleted widget, one renamed string — and expensive to notice, because
/// nothing breaks when they go.
Future<void> _pumpHome(
  WidgetTester tester, {
  FakeContentRepository? content,
  FakeTempleRepository? temple,
  FakeAccountsRepository? accounts,
  Size surfaceSize = const Size(1440, 2400),
}) async {
  await pumpScreen(
    tester,
    const HomeScreen(),
    surfaceSize: surfaceSize,
    temple: temple,
    accounts: accounts,
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      contentRepositoryProvider.overrideWithValue(
        content ??
            FakeContentRepository(
              pages: {'about': testPage()},
              settings: testSettings(),
            ),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('the About cards', () {
    test('a paragraph shaped like a card becomes one', () {
      final highlight = ContentHighlight.parse(
        '🛕 हमारी विरासत — मंदिर के इतिहास को संरक्षित करना।',
      )!;

      expect(highlight.emblem, '🛕');
      expect(highlight.heading, 'हमारी विरासत');
      expect(highlight.body, 'मंदिर के इतिहास को संरक्षित करना।');
    });

    test('an emblem is optional', () {
      final highlight = ContentHighlight.parse('Our Heritage — the history.')!;

      expect(highlight.emblem, isNull);
      expect(highlight.heading, 'Our Heritage');
    });

    /// The cap on the heading is what stops this: an ordinary sentence with an
    /// em dash in it must stay a paragraph, or the page loses everything after
    /// the dash into a card body under a nonsense heading.
    test('ordinary prose with an em dash is not a card', () {
      expect(
        ContentHighlight.parse(
          'मंदिर की स्थापना गाँव के बुजुर्गों ने की थी — और तब से यह सेवा का '
          'केंद्र रहा है।',
        ),
        isNull,
      );
      expect(ContentHighlight.parse('एक साधारण अनुच्छेद।'), isNull);
      expect(ContentHighlight.parse('— नहीं'), isNull);
      expect(ContentHighlight.parse('शीर्षक — '), isNull);
    });

    test('parseAll keeps the order and drops the rest', () {
      final highlights = ContentHighlight.parseAll(const [
        'एक साधारण अनुच्छेद।',
        '🛕 पहला — पहला विवरण।',
        '🤝 दूसरा — दूसरा विवरण।',
      ]);

      expect(highlights.map((h) => h.heading), ['पहला', 'दूसरा']);
    });

    testWidgets('the home page renders them as a grid', (tester) async {
      await _pumpHome(
        tester,
        content: FakeContentRepository(
          settings: testSettings(),
          pages: {
            'about': testPage(
              content:
                  'लीड अनुच्छेद।\n\n'
                  '🛕 हमारी विरासत — परंपराओं को संरक्षित करना।\n\n'
                  '🤝 ग्राम सहभागिता — सामूहिक सहयोग।\n\n'
                  '🪔 सेवा और भक्ति — आध्यात्मिक वातावरण।',
            ),
          },
        ),
      );

      expect(find.byKey(const Key('about-highlights')), findsOneWidget);
      expect(find.text('हमारी विरासत'), findsOneWidget);
      expect(find.text('ग्राम सहभागिता'), findsOneWidget);
      expect(find.text('सेवा और भक्ति'), findsOneWidget);
      // The lead paragraph stays a paragraph.
      expect(find.text('लीड अनुच्छेद।'), findsOneWidget);
    });

    testWidgets('a page written as prose renders no grid', (tester) async {
      await _pumpHome(tester);

      expect(find.byKey(const Key('about-highlights')), findsNothing);
    });
  });

  group('the hero', () {
    testWidgets('leads with the donate call to action', (tester) async {
      await _pumpHome(tester);

      expect(find.byKey(const Key('hero-donate')), findsOneWidget);
      expect(find.byKey(const Key('hero-events')), findsOneWidget);
      // The committee link moved to its own section, where the approved design
      // puts it.
      expect(find.byKey(const Key('hero-committee')), findsNothing);
    });

    testWidgets('the panel carries the temple name and village', (
      tester,
    ) async {
      await _pumpHome(tester);

      expect(find.byKey(const Key('hero-emblem-name')), findsOneWidget);
      expect(find.byKey(const Key('hero-emblem-locality')), findsOneWidget);
      // The gold line that used to sit under the title is gone: the approved
      // design has no such line.
      expect(find.byKey(const Key('hero-locality')), findsNothing);
    });

    testWidgets('an unconfigured profile leaves the panel uncaptioned', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        temple: FakeTempleRepository(
          profile: testProfile(name: null, village: null),
        ),
      );

      expect(find.byKey(const Key('hero-emblem-name')), findsNothing);
      expect(find.byKey(const Key('hero-emblem-locality')), findsNothing);
    });
  });

  group('the accounts band', () {
    testWidgets('shows the four figures the approved design puts here', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        accounts: FakeAccountsRepository(
          transparency: testTransparency(
            summary: testTransparencyYear(
              openingBalancePaise: 0,
              donationsPaise: 12550000,
              otherIncomePaise: 0,
              totalExpensePaise: 4230000,
              donationCount: 126,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('home-transparency')), findsOneWidget);
      expect(find.text('₹1,25,500.00'), findsOneWidget);
      expect(find.text('₹42,300.00'), findsOneWidget);
      // Opening 0 + 1,25,500 received − 42,300 spent.
      expect(find.text('₹83,200.00'), findsOneWidget);
      expect(find.text('126'), findsOneWidget);
      // It links to the full page rather than replacing it.
      expect(find.byKey(const Key('transparency-see-all')), findsOneWidget);
    });

    /// A band of zeros on the front page would say "the temple received
    /// nothing", which is a false statement about somebody's finances rather
    /// than a missing feature.
    testWidgets('unpublished books show nothing at all, not zeros', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        accounts: FakeAccountsRepository(
          transparency: testTransparency(isPublished: false),
        ),
      );

      expect(find.byKey(const Key('home-transparency')), findsNothing);
      expect(find.text('₹0.00'), findsNothing);
    });

    testWidgets('an accounts outage does not put an error on the front page', (
      tester,
    ) async {
      await _pumpHome(
        tester,
        accounts: FakeAccountsRepository(
          transparencyError: const AppException.unknown(),
        ),
      );

      expect(find.byKey(const Key('home-transparency')), findsNothing);
      // The rest of the page is still there.
      expect(find.byKey(const Key('hero-title')), findsOneWidget);
    });
  });

  group('the address block', () {
    testWidgets('is labelled, named and has a map', (tester) async {
      await _pumpHome(tester);

      expect(find.byKey(const Key('address-temple-name')), findsOneWidget);
      expect(find.text('ग्राम - Amarpur Pankhoriya'), findsOneWidget);
      expect(find.text('पंचायत - Kurma'), findsOneWidget);
      expect(find.byKey(const Key('address-map')), findsOneWidget);
    });

    testWidgets('an unconfigured address shows no map block', (tester) async {
      await _pumpHome(
        tester,
        temple: FakeTempleRepository(
          profile: testProfile(name: null, village: null, panchayat: null),
        ),
      );

      expect(find.byKey(const Key('address-map')), findsNothing);
    });
  });

  group('the shell', () {
    testWidgets('the footer carries quick links and a copyright line', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const PublicShell(child: SizedBox.shrink()),
        surfaceSize: const Size(1440, 900),
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('public-footer')), findsOneWidget);
      expect(find.byKey(const Key('public-footer-copyright')), findsOneWidget);
      expect(find.text('त्वरित लिंक'), findsOneWidget);

      // The year is read from the clock, not written into the app.
      final copyright = tester
          .widget<Text>(find.byKey(const Key('public-footer-copyright')))
          .data!;
      expect(copyright, contains('${DateTime.now().year}'));
      expect(copyright, contains('सर्वाधिकार सुरक्षित'));
    });
  });
}
