import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/files/link_opener.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';
import 'package:rkt_web/features/donations/domain/donation.dart';
import 'package:rkt_web/features/donations/presentation/admin_donation_editor_screen.dart';
import 'package:rkt_web/features/donations/presentation/admin_donation_settings_screen.dart';
import 'package:rkt_web/features/donations/presentation/admin_donations_screen.dart';
import 'package:rkt_web/features/donations/presentation/donate_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_donation_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpDonations(
  WidgetTester tester,
  Widget screen,
  FakeDonationRepository donations, {
  Set<String> permissions = const {
    Permissions.donationsView,
    Permissions.donationsManage,
  },
  Size surfaceSize = const Size(1024, 3000),
  List<Override> overrides = const [],
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize,
    donations: donations,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: testUser(permissions: permissions)),
      ),
      contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
      ...overrides,
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('DonateScreen (public)', () {
    testWidgets('shows the bank details the committee published', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const DonateScreen(),
        FakeDonationRepository(details: testDonationDetails()),
      );

      expect(find.byKey(const Key('donation-details-card')), findsOneWidget);
      expect(find.text('thakurbari@upi'), findsOneWidget);
      expect(find.text('XXXX XXXX 1234'), findsOneWidget);
      expect(find.text('DEMO0001234'), findsOneWidget);
    });

    testWidgets('shows no donor, no total and no count', (tester) async {
      // The whole public surface is where to send money. There is nowhere for
      // donor detail to come from, and this asserts the screen asks for
      // nothing else.
      final donations = FakeDonationRepository(details: testDonationDetails());

      await pumpDonations(tester, const DonateScreen(), donations);

      expect(donations.lastQuery, isNull, reason: 'the register was queried');
      expect(find.textContaining('₹'), findsNothing);
    });

    testWidgets('an unpublished block is an empty state, not an error', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const DonateScreen(),
        FakeDonationRepository(),
      );

      expect(find.byKey(const Key('donate-coming-soon')), findsOneWidget);
      expect(find.byType(ErrorView), findsNothing);
    });

    testWidgets('unreachable details never show a half-loaded account', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const DonateScreen(),
        FakeDonationRepository(
          listError: const AppException(code: ErrorCode.network),
        ),
      );

      expect(find.byKey(const Key('donate-coming-soon')), findsOneWidget);
      expect(find.byKey(const Key('donate-bank-box')), findsNothing);
    });

    testWidgets('only the rows the committee filled in are shown', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const DonateScreen(),
        FakeDonationRepository(
          details: testDonationDetails(
            bankName: null,
            accountName: null,
            accountNumber: null,
            ifsc: null,
          ),
        ),
      );

      expect(find.text('thakurbari@upi'), findsOneWidget);
      expect(find.byKey(const Key('donate-value-1')), findsNothing);
    });

    testWidgets('a value can be copied rather than transcribed by eye', (
      tester,
    ) async {
      // A mistyped IFSC is a donation that goes somewhere else.
      await pumpDonations(
        tester,
        const DonateScreen(),
        FakeDonationRepository(details: testDonationDetails()),
      );

      expect(find.byKey(const Key('donate-copy-0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('donate-copy-0')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('AdminDonationsScreen', () {
    testWidgets('shows the register and the totals the server sent', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(
          donations: [
            testDonation(id: 1, donorName: 'सीता देवी'),
            testDonation(
              id: 2,
              donorName: 'मोहन लाल',
              status: DonationStatuses.confirmed,
              receiptNumber: 'RKT/2026-27/0001',
            ),
          ],
          summary: testSummary(),
        ),
      );

      expect(find.byKey(const Key('donation-1')), findsOneWidget);
      expect(find.byKey(const Key('donation-2')), findsOneWidget);
      // The server's figure, shown verbatim: adding up the rows in view would
      // report the total of one page as the total of everything.
      expect(find.text('₹1,25,500.00'), findsOneWidget);
      expect(find.text('126'), findsOneWidget);
    });

    testWidgets('an empty register shows its empty state', (tester) async {
      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(),
      );

      expect(find.byKey(const Key('donations-empty')), findsOneWidget);
    });

    testWidgets('the status filter narrows the register', (tester) async {
      final donations = FakeDonationRepository(
        donations: [
          testDonation(id: 1),
          testDonation(
            id: 2,
            status: DonationStatuses.confirmed,
            receiptNumber: 'RKT/2026-27/0001',
          ),
        ],
      );

      await pumpDonations(tester, const AdminDonationsScreen(), donations);

      await tester.tap(find.byKey(const Key('donation-filter-confirmed')));
      await tester.pumpAndSettle();

      expect(donations.lastQuery?.status, DonationStatuses.confirmed);
      expect(find.byKey(const Key('donation-2')), findsOneWidget);
      expect(find.byKey(const Key('donation-1')), findsNothing);
    });

    testWidgets('a reversed donation is struck through, not hidden', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(
          donations: [
            testDonation(
              id: 3,
              status: DonationStatuses.reversed,
              reversalReason: 'चेक अनादरित',
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('donation-3')), findsOneWidget);

      final amount = tester.widget<Text>(
        find.byKey(const Key('donation-amount-3')),
      );
      expect(amount.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('a viewer sees the register but is offered no new button', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(donations: [testDonation()]),
        permissions: const {Permissions.donationsView},
      );

      expect(find.byKey(const Key('donation-1')), findsOneWidget);
      // A courtesy, never the access control: the server refuses the write
      // whatever this widget shows.
      expect(find.byKey(const Key('donation-new')), findsNothing);
      expect(find.byKey(const Key('donation-settings-open')), findsNothing);
    });

    testWidgets('a forbidden register shows the unauthorized state', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(
          listError: const AppException(code: ErrorCode.forbidden),
        ),
      );

      expect(find.byType(UnauthorizedView), findsOneWidget);
    });

    testWidgets('the pager appears only when there is more than one page', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(donations: [testDonation()]),
      );
      expect(find.byKey(const Key('donations-next')), findsNothing);

      await pumpDonations(
        tester,
        const AdminDonationsScreen(),
        FakeDonationRepository(donations: [testDonation()], lastPage: 3),
      );
      expect(find.byKey(const Key('donations-next')), findsOneWidget);
    });
  });

  group('AdminDonationEditorScreen', () {
    testWidgets('recording sends the amount as the string that was typed', (
      tester,
    ) async {
      final donations = FakeDonationRepository();

      await pumpDonations(tester, const AdminDonationEditorScreen(), donations);

      await tester.enterText(
        find.byKey(const Key('donation-donor_name')),
        'रामप्रसाद यादव',
      );
      await tester.enterText(
        find.byKey(const Key('donation-amount')),
        '1,25,500',
      );
      await tester.tap(find.byKey(const Key('donation-save')));
      await tester.pumpAndSettle();

      expect(donations.recordCalls, 1);
      // Parsing it into paise happens in exactly one place, on the server.
      expect(donations.lastDraft?.amount, '1,25,500');
      expect(donations.lastDraft?.donorName, 'रामप्रसाद यादव');
    });

    testWidgets('a reference is asked for only when the mode needs one', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(),
        FakeDonationRepository(),
      );

      // Cash is the default, and cash leaves nothing to match.
      expect(find.byKey(const Key('donation-reference_number')), findsNothing);

      await tester.tap(find.byKey(const Key('donation-mode')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('donation-mode-upi')).last);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('donation-reference_number')),
        findsOneWidget,
      );
    });

    testWidgets('a pending donation shows what its receipt is waiting for', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(donationId: 1),
        FakeDonationRepository(donations: [testDonation(id: 1)]),
      );

      expect(find.byKey(const Key('donation-receipt-number')), findsOneWidget);
      expect(find.byKey(const Key('donation-confirm')), findsOneWidget);
      // Nothing to print until a receipt exists.
      expect(find.byKey(const Key('donation-print')), findsNothing);
    });

    testWidgets('confirming asks first, then issues the receipt', (
      tester,
    ) async {
      final donations = FakeDonationRepository(
        donations: [testDonation(id: 1)],
      );

      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(donationId: 1),
        donations,
      );

      await tester.tap(find.byKey(const Key('donation-confirm')));
      await tester.pumpAndSettle();

      // The dialogue says what confirming costs: after it, the amount, the
      // date and the donor cannot be changed.
      expect(find.byKey(const Key('donation-confirm-dialog')), findsOneWidget);
      expect(donations.confirmCalls, 0);

      await tester.tap(find.byKey(const Key('donation-confirm-accept')));
      await tester.pumpAndSettle();

      expect(donations.confirmCalls, 1);
      expect(donations.lastConfirmedId, 1);
    });

    testWidgets('a receipted donation is locked down to its notes', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(donationId: 1),
        FakeDonationRepository(
          donations: [
            testDonation(
              id: 1,
              status: DonationStatuses.confirmed,
              receiptNumber: 'RKT/2026-27/0007',
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('donation-locked')), findsOneWidget);
      expect(find.text('RKT/2026-27/0007'), findsOneWidget);

      final amount = tester.widget<TextFormField>(
        find.byKey(const Key('donation-amount')),
      );
      expect(amount.enabled, isFalse);

      // The notes are the one field that is about the record rather than on it.
      final notes = tester.widget<TextFormField>(
        find.byKey(const Key('donation-notes')),
      );
      expect(notes.enabled, isTrue);
    });

    testWidgets('reversing requires a reason before it will run', (
      tester,
    ) async {
      final donations = FakeDonationRepository(
        donations: [
          testDonation(
            id: 1,
            status: DonationStatuses.confirmed,
            receiptNumber: 'RKT/2026-27/0007',
          ),
        ],
      );

      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(donationId: 1),
        donations,
      );

      await tester.tap(find.byKey(const Key('donation-reverse')));
      await tester.pumpAndSettle();

      // Accepting with an empty reason does nothing: "why was this removed
      // from the books" is the first question an auditor asks.
      await tester.tap(find.byKey(const Key('donation-reverse-accept')));
      await tester.pumpAndSettle();
      expect(donations.reverseCalls, 0);

      await tester.tap(find.byKey(const Key('donation-reverse')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('donation-reverse-reason')),
        'चेक अनादरित हो गया',
      );
      await tester.tap(find.byKey(const Key('donation-reverse-accept')));
      await tester.pumpAndSettle();

      expect(donations.reverseCalls, 1);
      expect(donations.lastReversalReason, 'चेक अनादरित हो गया');
    });

    testWidgets('a reversed donation says so and offers no second reversal', (
      tester,
    ) async {
      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(donationId: 1),
        FakeDonationRepository(
          donations: [
            testDonation(
              id: 1,
              status: DonationStatuses.reversed,
              receiptNumber: 'RKT/2026-27/0007',
              reversalReason: 'चेक अनादरित',
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('donation-reversed')), findsOneWidget);
      expect(find.textContaining('चेक अनादरित'), findsWidgets);
      expect(find.byKey(const Key('donation-reverse')), findsNothing);
      // The receipt is still printable — cancelling it has to stay traceable.
      expect(find.byKey(const Key('donation-print')), findsOneWidget);
    });

    testWidgets('printing opens the receipt document', (tester) async {
      final opener = _RecordingOpener();

      await pumpDonations(
        tester,
        AdminDonationEditorScreen(donationId: 1, opener: opener),
        FakeDonationRepository(
          donations: [
            testDonation(
              id: 1,
              status: DonationStatuses.confirmed,
              receiptNumber: 'RKT/2026-27/0007',
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('donation-print')));
      await tester.pumpAndSettle();

      // A new tab, because the browser is what shapes the Devanagari in a
      // donor's name and what writes the PDF.
      // `openedOwn`, not `opened`: the receipt is our own authenticated
      // endpoint, and opening it with `noreferrer` would make the request
      // anonymous — the defect this stub now pins.
      expect(opener.opened, isEmpty);
      expect(opener.openedOwn, hasLength(1));
      expect(
        opener.openedOwn.single,
        endsWith('/api/admin/donations/1/receipt'),
      );
    });

    testWidgets('a viewer sees the record read-only', (tester) async {
      await pumpDonations(
        tester,
        const AdminDonationEditorScreen(donationId: 1),
        FakeDonationRepository(donations: [testDonation(id: 1)]),
        permissions: const {Permissions.donationsView},
      );

      expect(find.byKey(const Key('donation-read-only')), findsOneWidget);
      expect(find.byKey(const Key('donation-save')), findsNothing);
      expect(find.byKey(const Key('donation-confirm')), findsNothing);
      expect(find.byKey(const Key('donation-reverse')), findsNothing);
    });

    testWidgets('a server refusal is shown against its field', (tester) async {
      final donations = FakeDonationRepository(
        saveError: const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'amount': ['A donation must be more than zero.'],
          },
        ),
      );

      await pumpDonations(tester, const AdminDonationEditorScreen(), donations);

      await tester.enterText(
        find.byKey(const Key('donation-donor_name')),
        'सीता देवी',
      );
      await tester.enterText(find.byKey(const Key('donation-amount')), '0');
      await tester.tap(find.byKey(const Key('donation-save')));
      await tester.pumpAndSettle();

      expect(find.text('A donation must be more than zero.'), findsOneWidget);
    });
  });

  group('AdminDonationSettingsScreen', () {
    testWidgets('saving sends what the committee typed', (tester) async {
      final donations = FakeDonationRepository();

      await pumpDonations(
        tester,
        const AdminDonationSettingsScreen(),
        donations,
      );

      await tester.enterText(
        find.byKey(const Key('donation-settings-upi_id')),
        'thakurbari@upi',
      );
      await tester.tap(find.byKey(const Key('donation-settings-publish')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('donation-settings-save')));
      await tester.pumpAndSettle();

      expect(donations.settingsSaveCalls, 1);
      expect(donations.lastSettingsDraft?.upiId, 'thakurbari@upi');
      expect(donations.lastSettingsDraft?.isPublished, isTrue);
    });

    testWidgets('publishing an empty block warns before it is saved', (
      tester,
    ) async {
      // Published with nothing payable renders an empty box on the public
      // page, which reads as a broken site rather than an unconfigured one.
      await pumpDonations(
        tester,
        const AdminDonationSettingsScreen(),
        FakeDonationRepository(),
      );

      expect(
        find.byKey(const Key('donation-settings-incomplete')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('donation-settings-publish')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('donation-settings-incomplete')),
        findsOneWidget,
      );
    });

    testWidgets('the QR is chosen from the gallery, not typed', (tester) async {
      await pumpDonations(
        tester,
        const AdminDonationSettingsScreen(),
        FakeDonationRepository(),
      );

      expect(find.byKey(const Key('donation-qr_url-choose')), findsOneWidget);
    });
  });

  group('the home page donate block', () {
    testWidgets('shows the published details in the prototype position', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const HomeScreen(),
        donations: FakeDonationRepository(details: testDonationDetails()),
        surfaceSize: const Size(1280, 4200),
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('donation-details-card')), findsOneWidget);
      expect(find.byKey(const Key('donate-see-all')), findsOneWidget);
    });

    testWidgets('degrades to an empty state when nothing is published', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        const HomeScreen(),
        donations: FakeDonationRepository(),
        surfaceSize: const Size(1280, 4200),
        overrides: [
          contentRepositoryProvider.overrideWithValue(
            FakeContentRepository(settings: testSettings()),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('donate-coming-soon')), findsOneWidget);
      expect(find.byKey(const Key('donate-see-all')), findsNothing);
    });
  });
}

/// Records what would have been opened, since the VM has no browser.
///
/// Both doors are recorded, but separately: the receipt is our own
/// authenticated endpoint and must go through [openOwn], because `noreferrer`
/// would leave the API unable to see that the request came from this signed-in
/// app. `opened` staying empty is part of what the receipt test asserts.
class _RecordingOpener implements LinkOpener {
  final List<String> opened = [];
  final List<String> openedOwn = [];

  @override
  bool open(String url) {
    opened.add(url);
    return true;
  }

  @override
  bool openOwn(String url) {
    openedOwn.add(url);
    return true;
  }
}
