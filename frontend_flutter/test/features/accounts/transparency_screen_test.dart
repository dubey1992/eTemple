import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/features/accounts/data/accounts_providers.dart';
import 'package:rkt_web/features/accounts/domain/account.dart';
import 'package:rkt_web/features/accounts/presentation/account_labels.dart';
import 'package:rkt_web/features/accounts/presentation/transparency_screen.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import '../../support/fake_accounts_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/pump_app.dart';

/// The public accounts page.
///
/// Two of these cases are about what is **not** on it. That is the deliverable:
/// the page's whole reason to exist is publishing figures, and the reason it is
/// safe to publish them is that they name nobody.
void main() {
  late AppLocalizations hi;

  setUpAll(() async {
    // Loaded once rather than reached for through a widget tree: a test that
    // taps translated text is a test that breaks on a wording change.
    hi = await AppLocalizations.delegate.load(AppLocales.hindi);
  });

  Future<void> pumpPage(
    WidgetTester tester,
    FakeAccountsRepository accounts, {
    Locale locale = AppLocales.hindi,
  }) async {
    await pumpScreen(
      tester,
      // Wrapped in a Scaffold: the public shell supplies one in the
      // application, and chips need a Material ancestor.
      const Scaffold(body: TransparencyScreen()),
      locale: locale,
      accounts: accounts,
      overrides: [
        // The public shell reads the site settings; the temple profile is
        // already stubbed by the harness.
        contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
      ],
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the year, the totals and the balance', (tester) async {
    await pumpPage(tester, FakeAccountsRepository());

    expect(find.byKey(const Key('transparency-year')), findsOneWidget);

    // ₹40,000 opening + ₹8,700 received − ₹3,000 spent.
    expect(find.byKey(const Key('transparency-opening')), findsOneWidget);
    expect(find.text('₹40,000.00'), findsOneWidget);
    expect(find.text('₹8,700.00'), findsOneWidget);
    expect(find.text('₹3,000.00'), findsOneWidget);
    expect(find.text('₹45,700.00'), findsOneWidget);
  });

  testWidgets('reports donations separately from other income', (tester) async {
    await pumpPage(tester, FakeAccountsRepository());

    expect(find.text(hi.transparencyDonations), findsOneWidget);
    expect(find.text('₹7,500.00'), findsOneWidget);
  });

  testWidgets('breaks expenditure down by heading', (tester) async {
    await pumpPage(tester, FakeAccountsRepository());

    expect(
      find.byKey(const Key('transparency-expense-breakdown')),
      findsOneWidget,
    );
    expect(find.text('निर्माण कार्य'), findsOneWidget);
    expect(find.text('₹9,000.00'), findsOneWidget);
  });

  /// The books are not open, and the page says so rather than showing zeros.
  ///
  /// Zeros would read as "the temple received nothing", which is a false
  /// statement about somebody's finances rather than a missing feature
  /// (PHASE_9_PLAN assumption N7).
  testWidgets('an unpublished ledger shows words, not a column of zeros', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeAccountsRepository(
        transparency: testTransparency(isPublished: false),
      ),
    );

    expect(find.byKey(const Key('transparency-not-published')), findsOneWidget);
    expect(find.byKey(const Key('transparency-opening')), findsNothing);
    expect(find.textContaining('₹0.00'), findsNothing);
  });

  testWidgets('the notes about approval and about names are always shown', (
    tester,
  ) async {
    await pumpPage(tester, FakeAccountsRepository());

    expect(find.byKey(const Key('transparency-approved-note')), findsOneWidget);
    expect(find.byKey(const Key('transparency-names-note')), findsOneWidget);
  });

  testWidgets('a year can be chosen when there is more than one', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeAccountsRepository(
        transparency: testTransparency(
          years: const [
            TransparencyYearOption(year: 2026, label: '2026–27'),
            TransparencyYearOption(year: 2025, label: '2025–26'),
          ],
        ),
      ),
    );

    expect(find.byKey(const Key('transparency-year-2026')), findsOneWidget);
    expect(find.byKey(const Key('transparency-year-2025')), findsOneWidget);

    await tester.tap(find.byKey(const Key('transparency-year-2025')));
    await tester.pumpAndSettle();
  });

  testWidgets('a single year offers no picker', (tester) async {
    await pumpPage(tester, FakeAccountsRepository());

    expect(find.byKey(const Key('transparency-year-2026')), findsNothing);
  });

  testWidgets('an empty year says so rather than showing a set of zeros', (
    tester,
  ) async {
    await pumpPage(
      tester,
      FakeAccountsRepository(
        transparency: testTransparency(
          summary: testTransparencyYear(
            openingBalancePaise: 0,
            donationsPaise: 0,
            otherIncomePaise: 0,
            totalExpensePaise: 0,
            donationCount: 0,
            expenseByCategory: const [],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('transparency-empty-year')), findsOneWidget);
  });

  /// The page asks the server for the reader's language, and the server —
  /// which holds both — decides what to serve and whether it fell back.
  ///
  /// Exercised through the provider rather than a widget: the question is what
  /// the repository is asked for, and a container answers it without a frame.
  test('the request carries the language the reader chose', () async {
    final accounts = FakeAccountsRepository();
    final container = ProviderContainer(
      overrides: [accountsRepositoryProvider.overrideWithValue(accounts)],
    );
    addTearDown(container.dispose);

    await container.read(transparencyProvider.future);
    expect(accounts.lastLanguage, 'hi');

    container.read(localeControllerProvider.notifier).toggle();
    await container.read(transparencyProvider.future);

    expect(accounts.lastLanguage, 'en');
  });

  group('the money formatter', () {
    /// The village reads lakhs, not millions. Mirrors
    /// `App\Support\Money::groupIndian` so the page and the printed receipt
    /// group a figure the same way.
    test('groups the Indian way', () {
      expect(AccountLabels.rupees(0), '₹0.00');
      expect(AccountLabels.rupees(50), '₹0.50');
      expect(AccountLabels.rupees(100), '₹1.00');
      expect(AccountLabels.rupees(123456), '₹1,234.56');
      expect(AccountLabels.rupees(12550000), '₹1,25,500.00');
      expect(AccountLabels.rupees(1234567890), '₹1,23,45,678.90');
    });

    /// A year that spent more than it received is a real year, and the page
    /// must be able to say so.
    test('carries a minus sign rather than clamping at zero', () {
      expect(AccountLabels.rupees(-250000), '-₹2,500.00');
    });
  });
}
