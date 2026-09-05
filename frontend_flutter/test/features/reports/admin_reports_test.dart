import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/admin/data/admin_providers.dart';
import 'package:rkt_web/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:rkt_web/features/reports/domain/report.dart';
import 'package:rkt_web/features/reports/presentation/admin_report_screen.dart';
import 'package:rkt_web/features/reports/presentation/admin_reports_screen.dart';
import 'package:rkt_web/l10n/app_localizations.dart';

import '../../support/fake_reports_repository.dart';
import '../../support/pump_app.dart';

/// The reporting console.
///
/// The cases that matter are the disclosure switch and the export URL: the
/// first is this phase's refusal, and the second is its guarantee.
void main() {
  late AppLocalizations hi;

  setUpAll(() async {
    hi = await AppLocalizations.delegate.load(AppLocales.hindi);
  });

  Future<void> pumpAdmin(
    WidgetTester tester,
    Widget screen,
    FakeReportsRepository reports, {
    Set<String> permissions = const {
      Permissions.reportsView,
      Permissions.reportsExport,
      Permissions.donationsView,
    },
  }) async {
    await pumpScreen(
      tester,
      // Wrapped in a Scaffold: these render inside the admin shell in the app.
      Scaffold(body: screen),
      reports: reports,
      surfaceSize: const Size(1300, 1800),
      overrides: [
        permissionsProvider.overrideWithValue(PermissionSet(permissions)),
      ],
    );
    await tester.pumpAndSettle();
  }

  group('the catalogue', () {
    testWidgets('lists what the server said this account may run', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminReportsScreen(),
        FakeReportsRepository(
          catalogue: testCatalogue(
            reports: [
              testReportListing(key: 'donations', title: 'दान रजिस्टर'),
              testReportListing(
                key: 'ledger',
                title: 'बही',
                hasPersonalColumns: false,
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('report-row-donations')), findsOneWidget);
      expect(find.byKey(const Key('report-row-ledger')), findsOneWidget);
      expect(find.text('दान रजिस्टर'), findsOneWidget);
    });

    /// A report holding somebody's details is flagged before it is opened.
    testWidgets('flags a report that has personal columns', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportsScreen(),
        FakeReportsRepository(
          catalogue: testCatalogue(
            reports: [
              testReportListing(key: 'donations'),
              testReportListing(
                key: 'donation-summary',
                hasPersonalColumns: false,
              ),
            ],
          ),
        ),
      );

      expect(find.text(hi.reportHasPersonal), findsOneWidget);
    });

    testWidgets('an empty catalogue says so rather than showing nothing', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminReportsScreen(),
        FakeReportsRepository(catalogue: testCatalogue(reports: const [])),
      );

      expect(find.byKey(const Key('reports-empty')), findsOneWidget);
    });

    /// Reading and downloading are separate permissions, and a Viewer is told
    /// why the buttons are missing before they open a report and wonder.
    testWidgets('says when this account may not download', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportsScreen(),
        FakeReportsRepository(catalogue: testCatalogue(mayExport: false)),
      );

      expect(find.byKey(const Key('reports-no-export')), findsOneWidget);
      expect(find.byKey(const Key('reports-export-limit')), findsNothing);
    });

    testWidgets('a refusal from the server is shown as one', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportsScreen(),
        FakeReportsRepository(
          catalogueError: const AppException(code: ErrorCode.forbidden),
        ),
      );

      expect(find.text(hi.stateUnauthorizedTitle), findsOneWidget);
    });
  });

  group('one report', () {
    testWidgets('shows the figures, the columns and the rows', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(),
      );

      expect(find.byKey(const Key('report-figure-total')), findsOneWidget);
      expect(find.text('₹5,000.00'), findsWidgets);
      expect(find.byKey(const Key('report-table')), findsOneWidget);
      expect(find.text('तिथि'), findsOneWidget);
    });

    /// The file and the screen carry the same filters, and the screen says so
    /// because a treasurer has no way to check it.
    testWidgets('states that the file matches the screen', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(),
      );

      expect(find.byKey(const Key('report-export-note')), findsOneWidget);
      expect(find.byKey(const Key('report-filters-applied')), findsOneWidget);
    });

    /// The guarantee itself: the export URL is built from the same query the
    /// table was drawn with (PHASE_10_PLAN assumption N1).
    testWidgets(
      'the export URL carries the filters the screen was drawn with',
      (tester) async {
        final reports = FakeReportsRepository();

        await pumpAdmin(
          tester,
          const AdminReportScreen(reportKey: 'donations'),
          reports,
        );

        // Narrow the period, then export.
        await tester.tap(find.byKey(const Key('report-year-2025')));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('report-export-csv')));
        await tester.pumpAndSettle();

        expect(reports.exportUrls, hasLength(1));
        final url = reports.exportUrls.single;

        expect(url, contains('year=2025'));
        expect(url, contains('format=csv'));
        // The screen's own last request used the same year.
        expect(reports.lastQuery?.year, 2025);
        // A file is the whole filter, never the page somebody was looking at.
        expect(url, isNot(contains('page=')));
        expect(url, isNot(contains('per_page=')));
      },
    );

    testWidgets('all three formats are offered', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(),
      );

      expect(find.byKey(const Key('report-export-csv')), findsOneWidget);
      expect(find.byKey(const Key('report-export-xlsx')), findsOneWidget);
      expect(find.byKey(const Key('report-export-pdf')), findsOneWidget);
    });

    testWidgets('a viewer is offered no export at all', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(catalogue: testCatalogue(mayExport: false)),
        permissions: const {Permissions.reportsView, Permissions.donationsView},
      );

      expect(find.byKey(const Key('report-no-export')), findsOneWidget);
      expect(find.byKey(const Key('report-export-csv')), findsNothing);
    });

    testWidgets('an empty report says so', (tester) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(data: testReportData(rows: const [], total: 0)),
      );

      expect(find.byKey(const Key('report-empty')), findsOneWidget);
    });
  });

  group('the disclosure switch', () {
    testWidgets('is offered, and off, when the report has personal columns', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(),
      );

      final control = tester.widget<SwitchListTile>(
        find.byKey(const Key('report-include-personal')),
      );

      expect(control.value, isFalse);
      expect(control.onChanged, isNotNull);
      expect(find.byKey(const Key('report-personal-chip')), findsNothing);
    });

    testWidgets('is absent on a report with nothing to disclose', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donation-summary'),
        FakeReportsRepository(
          data: testReportData(
            key: 'donation-summary',
            hasPersonalColumns: false,
          ),
        ),
      );

      expect(find.byKey(const Key('report-include-personal')), findsNothing);
    });

    /// Disabled rather than hidden: an account that may not do this should
    /// still see that the report has more in it, so they can ask somebody who
    /// may.
    testWidgets('is disabled, not hidden, when this account may not use it', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(
          catalogue: testCatalogue(
            reports: [testReportListing(maySeePersonal: false)],
          ),
        ),
      );

      final control = tester.widget<SwitchListTile>(
        find.byKey(const Key('report-include-personal')),
      );

      expect(control.onChanged, isNull);
      expect(find.text(hi.errorReportDisclosureRefused), findsOneWidget);
    });

    testWidgets('turning it on asks the server for the personal columns', (
      tester,
    ) async {
      final reports = FakeReportsRepository();

      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        reports,
      );

      expect(reports.lastQuery?.includePersonal, isFalse);

      await tester.tap(find.byKey(const Key('report-include-personal')));
      await tester.pumpAndSettle();

      expect(reports.lastQuery?.includePersonal, isTrue);
    });

    testWidgets('a view that includes personal details is marked', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminReportScreen(reportKey: 'donations'),
        FakeReportsRepository(data: testReportData(includesPersonal: true)),
      );

      expect(find.byKey(const Key('report-personal-chip')), findsOneWidget);
      expect(find.text('रामप्रसाद यादव'), findsOneWidget);
    });
  });

  group('the dashboard overview', () {
    testWidgets('shows this year in figures, with the trend', (tester) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(),
      );

      expect(find.byKey(const Key('overview-title')), findsOneWidget);
      expect(find.byKey(const Key('overview-donations')), findsOneWidget);
      expect(find.byKey(const Key('overview-balance')), findsOneWidget);
      expect(find.byKey(const Key('overview-trend')), findsOneWidget);
      expect(find.text('₹1,01,060.00'), findsOneWidget);
    });

    /// A panel this account may not see is **absent**, not empty. An absent
    /// panel says "not yours"; an empty one says "the temple received nothing".
    testWidgets('a panel the server withheld is absent, not zero', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(
          // Built directly rather than through the helper: `??` cannot tell an
          // explicit null from an omitted argument, and "the server withheld
          // this panel" is exactly an explicit null.
          overview: const Overview(financialYearLabel: '2026–27'),
        ),
      );

      expect(find.byKey(const Key('overview-donations')), findsNothing);
      expect(find.byKey(const Key('overview-enquiries')), findsNothing);
      expect(find.byKey(const Key('overview-events')), findsNothing);
      expect(find.text('₹0.00'), findsNothing);
    });

    testWidgets('the whole block disappears when there is nothing in it', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(
          overview: const Overview(financialYearLabel: '2026–27'),
        ),
      );

      expect(find.byKey(const Key('overview-title')), findsNothing);
    });

    /// The mixed case, which is the real one: an account that may read the
    /// inbox and not the money gets the inbox panel and no money panel.
    testWidgets('one panel can be present while another is withheld', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(
          overview: const Overview(
            financialYearLabel: '2026–27',
            enquiriesNew: 2,
            enquiriesOpen: 3,
          ),
        ),
      );

      expect(find.byKey(const Key('overview-enquiries')), findsOneWidget);
      expect(find.byKey(const Key('overview-donations')), findsNothing);
      expect(find.byKey(const Key('overview-trend')), findsNothing);
    });

    /// A dashboard that failed to load its figures still opens: the shortcuts
    /// below it are the thing somebody signed in to use.
    testWidgets('a failed overview does not take the dashboard down', (
      tester,
    ) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(
          overviewError: const AppException(code: ErrorCode.serverError),
        ),
      );

      expect(find.byKey(const Key('overview-title')), findsNothing);
      expect(find.byKey(const Key('dash-reports')), findsOneWidget);
    });

    testWidgets('an empty month is kept in the trend', (tester) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(),
      );

      // Twelve labels, including the months worth nothing: a chart that
      // dropped them would compress the gap.
      for (final month in [1, 4, 8, 12]) {
        expect(find.text('M$month'), findsOneWidget);
      }
    });

    testWidgets('a trend with no money in it says so', (tester) async {
      await pumpAdmin(
        tester,
        const AdminDashboardScreen(),
        FakeReportsRepository(
          overview: testOverview(
            trend: [
              for (var m = 1; m <= 12; m++)
                TrendPoint(
                  month: '2026-$m',
                  label: 'M$m',
                  totalPaise: 0,
                  display: '₹0.00',
                ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('overview-trend-empty')), findsOneWidget);
    });
  });
}
