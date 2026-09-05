import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/features/admin/data/admin_providers.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/audit/presentation/admin_audit_screen.dart';

import '../../support/fake_audit_repository.dart';
import '../../support/pump_app.dart';

/// The console's window onto the trail.
///
/// Every case here is about what the screen must *not* offer as much as what it
/// shows: there is no edit, no delete and no download, and an account without
/// the permission is told so rather than shown an empty list.
Future<void> _pump(
  WidgetTester tester, {
  FakeAuditRepository? audit,
  Set<String> permissions = const {Permissions.auditView},
}) async {
  await pumpScreen(
    tester,
    const AdminAuditScreen(),
    audit: audit ?? FakeAuditRepository(),
    surfaceSize: const Size(1280, 1400),
    overrides: [
      permissionsProvider.overrideWithValue(PermissionSet(permissions)),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminAuditScreen', () {
    testWidgets('lists what happened, newest first as the server sent it', (
      tester,
    ) async {
      await _pump(
        tester,
        audit: FakeAuditRepository(
          entries: [
            testAuditEntry(id: 2, context: 'दोहरी प्रविष्टि'),
            testAuditEntry(
              id: 1,
              action: 'donation.recorded',
              actionLabel: 'दान दर्ज किया / Donation recorded',
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('audit-entry-2')), findsOneWidget);
      expect(find.byKey(const Key('audit-entry-1')), findsOneWidget);
      expect(find.text('त्रिभुवन सिंह'), findsWidgets);
      // The reason travels with the row, so "why" needs no second lookup.
      expect(find.text('दोहरी प्रविष्टि'), findsOneWidget);
    });

    /// The diff is what the trail is for: not "somebody edited a donation" but
    /// "the amount went from ₹500 to ₹750, and who did it".
    testWidgets('shows the fields that changed, with both sides', (
      tester,
    ) async {
      await _pump(
        tester,
        audit: FakeAuditRepository(
          entries: [
            testAuditEntry(
              before: {'amount_paise': 50000},
              after: {'amount_paise': 75000},
            ),
          ],
        ),
      );

      expect(find.text('amount_paise'), findsOneWidget);
      expect(find.textContaining('50000'), findsOneWidget);
      expect(find.textContaining('75000'), findsOneWidget);
    });

    /// A record being created is not an edit. Drawing a column of em dashes
    /// beside it would read as though every field had moved.
    testWidgets('a creation is shown without an empty before column', (
      tester,
    ) async {
      await _pump(
        tester,
        audit: FakeAuditRepository(
          entries: [
            testAuditEntry(
              action: 'donation.recorded',
              actionLabel: 'दान दर्ज किया / Donation recorded',
              after: {'donor_name': 'सुमित्रा देवी', 'amount_paise': 250000},
            ),
          ],
        ),
      );

      expect(find.textContaining('दर्ज हुआ'), findsWidgets);
      expect(find.textContaining('पहले'), findsNothing);
    });

    /// An absent value reads as an em dash, not as the word "null", which means
    /// nothing to a treasurer.
    testWidgets('an absent value is shown as a dash', (tester) async {
      await _pump(
        tester,
        audit: FakeAuditRepository(
          entries: [
            testAuditEntry(
              before: {'notes': null},
              after: {'notes': 'जाँच हुई'},
            ),
          ],
        ),
      );

      expect(find.textContaining('—'), findsWidgets);
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('choosing an action really reaches the repository', (
      tester,
    ) async {
      final audit = FakeAuditRepository(
        entries: [
          testAuditEntry(id: 1),
          testAuditEntry(id: 2, action: 'report.exported'),
        ],
      );

      await _pump(tester, audit: audit);

      await tester.tap(find.byKey(const Key('audit-action-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('रिपोर्ट डाउनलोड की / Report exported').last);
      await tester.pumpAndSettle();

      expect(audit.lastQuery?.action, 'report.exported');
      expect(find.byKey(const Key('audit-entry-2')), findsOneWidget);
      expect(find.byKey(const Key('audit-entry-1')), findsNothing);
    });

    /// The `??` trap: clearing a filter must really clear it, not fall through
    /// to the value that is already set.
    testWidgets('clearing the filter really clears it', (tester) async {
      final audit = FakeAuditRepository(entries: [testAuditEntry()]);

      await _pump(tester, audit: audit);

      await tester.tap(find.byKey(const Key('audit-action-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('रिपोर्ट डाउनलोड की / Report exported').last);
      await tester.pumpAndSettle();
      expect(audit.lastQuery?.action, 'report.exported');

      // Filtering to a kind this trail has none of empties the list.
      expect(find.byKey(const Key('audit-empty')), findsOneWidget);

      await tester.tap(find.byKey(const Key('audit-clear-filters')));
      await tester.pumpAndSettle();

      // And clearing brings it back. Asserted on what is rendered rather than
      // on the last call to the repository: the unfiltered page is already
      // cached, so a correct implementation makes no second request at all.
      expect(find.byKey(const Key('audit-entry-1')), findsOneWidget);
      expect(find.byKey(const Key('audit-clear-filters')), findsNothing);
    });

    testWidgets('an empty trail says so rather than looking broken', (
      tester,
    ) async {
      await _pump(tester, audit: FakeAuditRepository(entries: const []));

      expect(find.byKey(const Key('audit-empty')), findsOneWidget);
    });

    testWidgets('an outage offers a retry', (tester) async {
      await _pump(
        tester,
        audit: FakeAuditRepository(listError: const AppException.unknown()),
      );

      expect(find.byKey(const Key('audit-empty')), findsNothing);
      expect(find.byType(ErrorView), findsOneWidget);
    });

    /// Hiding the screen is a courtesy; the server refuses the endpoint
    /// regardless, which `AuditTrailTest` proves by calling it directly.
    testWidgets('an account without audit.view is told, not shown a list', (
      tester,
    ) async {
      await _pump(
        tester,
        permissions: const {Permissions.usersView},
        audit: FakeAuditRepository(entries: [testAuditEntry()]),
      );

      expect(find.byKey(const Key('audit-unauthorized')), findsOneWidget);
      expect(find.byKey(const Key('audit-entry-1')), findsNothing);
    });

    /// There is no download, on purpose: the trail carries donor names, and a
    /// downloadable audit trail is a personal-data leak with an
    /// official-sounding name.
    testWidgets('the screen offers no way to export or edit the trail', (
      tester,
    ) async {
      await _pump(
        tester,
        audit: FakeAuditRepository(entries: [testAuditEntry()]),
      );

      for (final icon in const [
        Icons.download,
        Icons.download_outlined,
        Icons.edit,
        Icons.edit_outlined,
        Icons.delete,
        Icons.delete_outline,
        Icons.print,
      ]) {
        expect(find.byIcon(icon), findsNothing);
      }
    });
  });
}
