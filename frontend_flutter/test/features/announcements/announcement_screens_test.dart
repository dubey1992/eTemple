import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/announcements/domain/announcement.dart';
import 'package:rkt_web/features/announcements/presentation/admin_announcement_editor_screen.dart';
import 'package:rkt_web/features/announcements/presentation/admin_announcements_screen.dart';
import 'package:rkt_web/features/announcements/presentation/widgets/announcement_banner.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/content/presentation/home_screen.dart';

import '../../support/fake_announcement_repository.dart';
import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpAnnouncements(
  WidgetTester tester,
  Widget screen,
  FakeAnnouncementRepository repository, {
  Set<String> permissions = const {
    Permissions.contentView,
    Permissions.announcementsManage,
  },
  Size surfaceSize = const Size(1024, 2400),
  List<Override> overrides = const [],
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize,
    announcements: repository,
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

/// The home page reads site settings and the temple profile before it renders
/// anything, so the banner tests need those stubbed too — the banner lives
/// inside the page, not beside it.
Future<void> pumpHome(
  WidgetTester tester,
  FakeAnnouncementRepository repository,
) async {
  await pumpScreen(
    tester,
    const HomeScreen(),
    surfaceSize: const Size(1200, 3000),
    announcements: repository,
    overrides: [
      contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('AnnouncementBanner', () {
    testWidgets('shows the temple\'s current notice above everything', (
      tester,
    ) async {
      await pumpHome(
        tester,
        FakeAnnouncementRepository(
          current: [testPublicAnnouncement(title: 'कल आरती एक घंटे पहले')],
        ),
      );

      expect(find.byKey(const Key('announcement-banner')), findsOneWidget);
      expect(find.text('कल आरती एक घंटे पहले'), findsOneWidget);
    });

    testWidgets('renders nothing at all when there is no notice', (
      tester,
    ) async {
      await pumpHome(tester, FakeAnnouncementRepository());

      // Not an empty band: that would leave a gap above the hero.
      expect(find.byKey(const Key('announcement-banner')), findsNothing);
    });

    testWidgets('shows one notice, not a stack of them', (tester) async {
      await pumpHome(
        tester,
        FakeAnnouncementRepository(
          current: [
            testPublicAnnouncement(id: 1, title: 'पहली सूचना'),
            testPublicAnnouncement(id: 2, title: 'दूसरी सूचना'),
            testPublicAnnouncement(id: 3, title: 'तीसरी सूचना'),
          ],
        ),
      );

      expect(find.byKey(const Key('announcement-banner')), findsOneWidget);
      expect(find.text('पहली सूचना'), findsOneWidget);
      expect(find.text('दूसरी सूचना'), findsNothing);
    });

    testWidgets('closing one falls through to the next', (tester) async {
      await pumpHome(
        tester,
        FakeAnnouncementRepository(
          current: [
            testPublicAnnouncement(id: 1, title: 'पहली सूचना'),
            testPublicAnnouncement(id: 2, title: 'दूसरी सूचना'),
          ],
        ),
      );

      await tester.tap(find.byKey(const Key('announcement-dismiss')));
      await tester.pumpAndSettle();

      expect(find.text('पहली सूचना'), findsNothing);
      expect(find.text('दूसरी सूचना'), findsOneWidget);
    });

    testWidgets('an unreachable notice never takes the home page down', (
      tester,
    ) async {
      await pumpHome(
        tester,
        FakeAnnouncementRepository(
          currentError: const AppException(code: ErrorCode.network),
        ),
      );

      expect(find.byKey(const Key('announcement-banner')), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('a notice that runs out while the page is open disappears', (
      tester,
    ) async {
      await pumpHome(
        tester,
        FakeAnnouncementRepository(
          current: [
            testPublicAnnouncement(
              title: 'बीत चुकी',
              endsAt: DateTime.now().subtract(const Duration(minutes: 1)),
            ),
          ],
        ),
      );

      expect(find.byType(AnnouncementBanner), findsOneWidget);
      expect(find.text('बीत चुकी'), findsNothing);
    });
  });

  group('AdminAnnouncementsScreen', () {
    testWidgets('lists notices with where each one stands', (tester) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementsScreen(),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(id: 1, titleHi: 'अभी दिख रही', isShowing: true),
            testAnnouncement(id: 2, titleHi: 'मसौदा'),
          ],
        ),
      );

      expect(find.text('अभी दिख रही'), findsOneWidget);
      expect(find.text('मसौदा'), findsWidgets);
      expect(find.text('अभी वेबसाइट पर'), findsOneWidget);
    });

    testWidgets('a sent notice says so on the row', (tester) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementsScreen(),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(
              id: 1,
              status: AnnouncementStatuses.published,
              wasSent: true,
              sentAt: DateTime(2026, 9, 12),
            ),
          ],
        ),
      );

      expect(find.textContaining('12/09/2026'), findsOneWidget);
    });

    testWidgets('an empty list says so', (tester) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementsScreen(),
        FakeAnnouncementRepository(),
      );

      expect(find.byKey(const Key('announcements-empty')), findsOneWidget);
    });

    testWidgets('a reader without announcements.manage gets no write button', (
      tester,
    ) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementsScreen(),
        FakeAnnouncementRepository(),
        permissions: const {Permissions.contentView},
      );

      // A courtesy only. The server refuses regardless, which the backend
      // tests assert by calling the API directly.
      expect(find.byKey(const Key('announcement-new')), findsNothing);
    });

    testWidgets('a refused reader is told, not shown a broken screen', (
      tester,
    ) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementsScreen(),
        FakeAnnouncementRepository(
          listError: const AppException(code: ErrorCode.forbidden),
        ),
      );

      expect(find.byType(UnauthorizedView), findsOneWidget);
    });

    testWidgets('archived notices are reachable, not the default', (
      tester,
    ) async {
      final repository = FakeAnnouncementRepository(
        announcements: [testAnnouncement(id: 1)],
      );

      await pumpAnnouncements(
        tester,
        const AdminAnnouncementsScreen(),
        repository,
      );

      expect(repository.lastQuery?.includeArchived, isFalse);

      await tester.tap(find.byKey(const Key('announcement-show-archived')));
      await tester.pumpAndSettle();

      expect(repository.lastQuery?.includeArchived, isTrue);
    });
  });

  group('AdminAnnouncementEditorScreen', () {
    testWidgets('writing a new notice sends only what was typed', (
      tester,
    ) async {
      final repository = FakeAnnouncementRepository();

      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(),
        repository,
      );

      await tester.enterText(
        find.byKey(const Key('announcement-title-hi')),
        'कल की आरती',
      );
      await tester.enterText(
        find.byKey(const Key('announcement-message-hi')),
        'संध्या आरती एक घंटे पहले होगी।',
      );
      await tester.ensureVisible(find.byKey(const Key('announcement-save')));
      await tester.tap(find.byKey(const Key('announcement-save')));
      await tester.pumpAndSettle();

      expect(repository.createCalls, 1);

      // Nothing about publishing or sending can travel in a draft: those are
      // decisions with their own endpoints (PHASE_8_PLAN assumption N1).
      final payload = repository.lastDraft!.toJson();
      expect(payload.containsKey('status'), isFalse);
      expect(payload.containsKey('channels'), isFalse);
      expect(payload.containsKey('sent_at'), isFalse);
    });

    testWidgets('a draft offers no send button, and says why', (tester) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(announcements: [testAnnouncement(id: 1)]),
      );

      expect(find.byKey(const Key('announcement-send')), findsNothing);
      // A reason rather than a dead button.
      expect(
        find.byKey(const Key('announcement-publish-first')),
        findsOneWidget,
      );
    });

    testWidgets('a published notice can be sent', (tester) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(id: 1, status: AnnouncementStatuses.published),
          ],
        ),
      );

      expect(find.byKey(const Key('announcement-send')), findsOneWidget);
    });

    testWidgets('sending asks first, and nothing is sent if it is refused', (
      tester,
    ) async {
      final repository = FakeAnnouncementRepository(
        announcements: [
          testAnnouncement(id: 1, status: AnnouncementStatuses.published),
        ],
      );

      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        repository,
      );

      await tester.ensureVisible(find.byKey(const Key('announcement-send')));
      await tester.tap(find.byKey(const Key('announcement-send')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcement-send-dialog')), findsOneWidget);

      await tester.tap(find.byKey(const Key('announcement-send-cancel')));
      await tester.pumpAndSettle();

      expect(repository.sends, isEmpty);
    });

    testWidgets('nothing is ticked by default, so send starts disabled', (
      tester,
    ) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(id: 1, status: AnnouncementStatuses.published),
          ],
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('announcement-send')));
      await tester.tap(find.byKey(const Key('announcement-send')));
      await tester.pumpAndSettle();

      // The specification's rule: no sends without explicit admin action. A
      // pre-ticked channel would mean this could happen without a choice.
      final confirm = tester.widget<FilledButton>(
        find.byKey(const Key('announcement-send-confirm')),
      );
      expect(confirm.onPressed, isNull);
    });

    testWidgets('choosing a channel sends it on that channel', (tester) async {
      final repository = FakeAnnouncementRepository(
        announcements: [
          testAnnouncement(id: 1, status: AnnouncementStatuses.published),
        ],
      );

      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        repository,
      );

      await tester.ensureVisible(find.byKey(const Key('announcement-send')));
      await tester.tap(find.byKey(const Key('announcement-send')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('announcement-channel-email')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('announcement-send-confirm')));
      await tester.pumpAndSettle();

      // Compared piecewise: a record holding a List is only equal to itself,
      // because Dart lists use identity equality.
      expect(repository.sends, hasLength(1));
      expect(repository.sends.single.$1, 1);
      expect(repository.sends.single.$2, [AnnouncementChannels.email]);
    });

    testWidgets('a channel with no provider cannot be ticked', (tester) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(id: 1, status: AnnouncementStatuses.published),
          ],
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('announcement-send')));
      await tester.tap(find.byKey(const Key('announcement-send')));
      await tester.pumpAndSettle();

      // Shown, disabled, with the reason: hiding it would leave a committee
      // wondering; enabling it would let them believe the village was told.
      final sms = tester.widget<CheckboxListTile>(
        find.byKey(const Key('announcement-channel-sms')),
      );
      expect(sms.onChanged, isNull);
      expect(find.text('किसी प्रदाता से जुड़ा नहीं है'), findsWidgets);
    });

    testWidgets('an already-sent notice offers no send button at all', (
      tester,
    ) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(
              id: 1,
              status: AnnouncementStatuses.published,
              wasSent: true,
              sentAt: DateTime(2026, 9, 12),
              recipientCount: 4,
            ),
          ],
        ),
      );

      expect(find.byKey(const Key('announcement-send')), findsNothing);
      // And says so, before the buttons rather than after.
      expect(find.byKey(const Key('announcement-sent-panel')), findsOneWidget);
    });

    testWidgets('a refusal from the server is shown, not swallowed', (
      tester,
    ) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(
          announcements: [
            testAnnouncement(id: 1, status: AnnouncementStatuses.published),
          ],
          saveError: const AppException(
            code: ErrorCode.announcementAlreadySent,
          ),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('announcement-archive')));
      await tester.tap(find.byKey(const Key('announcement-archive')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('announcement-error')), findsOneWidget);
      expect(find.textContaining('पहले ही भेजी जा चुकी है'), findsOneWidget);
    });

    testWidgets('a reader without the permission gets a read-only form', (
      tester,
    ) async {
      await pumpAnnouncements(
        tester,
        const AdminAnnouncementEditorScreen(announcementId: 1),
        FakeAnnouncementRepository(announcements: [testAnnouncement(id: 1)]),
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('announcement-save')), findsNothing);
      expect(find.byKey(const Key('announcement-send')), findsNothing);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const Key('announcement-title-hi')),
            )
            .enabled,
        isFalse,
      );
    });
  });
}
