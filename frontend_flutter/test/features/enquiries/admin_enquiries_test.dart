import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/enquiries/domain/enquiry.dart';
import 'package:rkt_web/features/enquiries/presentation/admin_enquiries_screen.dart';
import 'package:rkt_web/features/enquiries/presentation/admin_enquiry_detail_screen.dart';

import 'package:rkt_web/features/auth/data/auth_providers.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_enquiry_repository.dart';
import '../../support/pump_app.dart';

/// Every admin screen is pumped inside a `Scaffold` and with a signed-in
/// account that holds `enquiries.manage` — the permission the inbox needs, and
/// the only one it recognises (PHASE_7_PLAN assumption N9).
Future<void> pumpInbox(
  WidgetTester tester,
  Widget screen,
  FakeEnquiryRepository repository, {
  Set<String> permissions = const {Permissions.enquiriesManage},
  Size surfaceSize = const Size(1024, 2400),
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize,
    enquiries: repository,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: testUser(permissions: permissions)),
      ),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AdminEnquiriesScreen', () {
    testWidgets('lists what is waiting', (tester) async {
      final repository = FakeEnquiryRepository(
        enquiries: [
          testEnquiry(id: 1, name: 'सीता देवी'),
          testEnquiry(
            id: 2,
            name: 'मोहन साह',
            reference: 'RKT/E/2026-27/0002',
            status: EnquiryStatuses.resolved,
          ),
        ],
        summaryResult: const EnquirySummary(
          newCount: 1,
          inProgress: 0,
          resolved: 1,
          spam: 0,
          open: 1,
        ),
      );

      await pumpInbox(
        tester,
        const AdminEnquiriesScreen(),
        repository,
        surfaceSize: const Size(1200, 1600),
      );

      expect(find.text('सीता देवी'), findsOneWidget);
      expect(find.text('मोहन साह'), findsOneWidget);
      // The counts come from the server's summary over the whole inbox, not
      // from the length of the page in view.
      expect(find.textContaining('(1)'), findsWidgets);
    });

    testWidgets('an empty inbox says so rather than looking broken', (
      tester,
    ) async {
      await pumpInbox(
        tester,
        const AdminEnquiriesScreen(),
        FakeEnquiryRepository(),
        surfaceSize: const Size(1200, 1200),
      );

      expect(find.byKey(const Key('enquiries-empty')), findsOneWidget);
    });

    testWidgets('a refused reader is told, not shown a broken screen', (
      tester,
    ) async {
      // What a Treasurer or a Viewer gets: reading the inbox and answering it
      // are the same right (PHASE_7_PLAN assumption N9).
      await pumpInbox(
        tester,
        const AdminEnquiriesScreen(),
        FakeEnquiryRepository(
          listError: const AppException(code: ErrorCode.forbidden),
        ),
        surfaceSize: const Size(1200, 1200),
      );

      expect(find.byType(UnauthorizedView), findsOneWidget);
    });

    testWidgets('choosing a status asks the server for that status', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(enquiries: [testEnquiry(id: 1)]);

      await pumpInbox(
        tester,
        const AdminEnquiriesScreen(),
        repository,
        surfaceSize: const Size(1200, 1600),
      );

      await tester.tap(find.byKey(const Key('enquiry-filter-resolved')));
      await tester.pumpAndSettle();

      expect(repository.lastQuery?.status, EnquiryStatuses.resolved);
      // Filtering returns to the first page: page four of a filter matching two
      // rows is an empty screen with no explanation.
      expect(repository.lastQuery?.page, 1);
    });

    testWidgets('spam is reachable but is not the default view', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(enquiries: [testEnquiry(id: 1)]);

      await pumpInbox(
        tester,
        const AdminEnquiriesScreen(),
        repository,
        surfaceSize: const Size(1200, 1600),
      );

      expect(repository.lastQuery?.status, isNull);
      expect(find.byKey(const Key('enquiry-filter-spam')), findsOneWidget);
    });
  });

  group('AdminEnquiryDetailScreen', () {
    testWidgets('shows how to reply before what was asked', (tester) async {
      final repository = FakeEnquiryRepository(
        enquiries: [
          testEnquiry(
            id: 7,
            mobile: '9876500011',
            message: 'आरती का समय क्या है? कृपया बताइए।',
          ),
        ],
      );

      await pumpInbox(
        tester,
        const AdminEnquiryDetailScreen(id: 7),
        repository,
        surfaceSize: const Size(1000, 1600),
      );

      expect(find.textContaining('9876500011'), findsOneWidget);
      expect(find.byKey(const Key('enquiry-message-body')), findsOneWidget);
      // The language the devotee asked to be answered in is an instruction to
      // whoever picks this up (assumption N5).
      expect(find.textContaining('हिन्दी'), findsWidgets);
    });

    testWidgets('an enquiry with no contact details says so plainly', (
      tester,
    ) async {
      await pumpInbox(
        tester,
        const AdminEnquiryDetailScreen(id: 7),
        FakeEnquiryRepository(enquiries: [testEnquiry(id: 7, mobile: null)]),
        surfaceSize: const Size(1000, 1600),
      );

      expect(find.text('कोई संपर्क विवरण नहीं दिया गया'), findsOneWidget);
    });

    testWidgets('moving it along calls the server', (tester) async {
      final repository = FakeEnquiryRepository(enquiries: [testEnquiry(id: 7)]);

      await pumpInbox(
        tester,
        const AdminEnquiryDetailScreen(id: 7),
        repository,
        surfaceSize: const Size(1000, 1600),
      );

      await tester.ensureVisible(find.byKey(const Key('enquiry-set-resolved')));
      await tester.tap(find.byKey(const Key('enquiry-set-resolved')));
      await tester.pumpAndSettle();

      expect(repository.statusChanges, [(7, EnquiryStatuses.resolved)]);
    });

    testWidgets('marking spam is offered as a status, not as a delete', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(enquiries: [testEnquiry(id: 7)]);

      await pumpInbox(
        tester,
        const AdminEnquiryDetailScreen(id: 7),
        repository,
        surfaceSize: const Size(1000, 1600),
      );

      // Nothing is ever deleted: `spam` is how noise leaves the inbox, and it
      // keeps the row (assumption N8).
      expect(find.byKey(const Key('enquiry-set-spam')), findsOneWidget);
      expect(find.text('हटाएं'), findsNothing);
    });

    testWidgets('a refusal from the server is reported, not swallowed', (
      tester,
    ) async {
      final repository = FakeEnquiryRepository(
        enquiries: [testEnquiry(id: 7)],
        updateError: const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'assigned_to': ['That member cannot open the enquiry inbox.'],
          },
        ),
      );

      await pumpInbox(
        tester,
        const AdminEnquiryDetailScreen(id: 7),
        repository,
        surfaceSize: const Size(1000, 1600),
      );

      await tester.ensureVisible(
        find.byKey(const Key('enquiry-set-in_progress')),
      );
      await tester.tap(find.byKey(const Key('enquiry-set-in_progress')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
