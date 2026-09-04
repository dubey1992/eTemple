import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/auth/permissions.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_providers.dart';
import 'package:rkt_web/features/content/data/content_providers.dart';
import 'package:rkt_web/features/events/data/event_providers.dart';
import 'package:rkt_web/features/events/domain/event.dart';
import 'package:rkt_web/features/events/domain/event_repository.dart';
import 'package:rkt_web/features/events/presentation/admin_event_editor_screen.dart';
import 'package:rkt_web/features/events/presentation/admin_events_screen.dart';
import 'package:rkt_web/features/events/presentation/event_detail_screen.dart';
import 'package:rkt_web/features/events/presentation/events_screen.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_content_repository.dart';
import '../../support/fake_event_repository.dart';
import '../../support/pump_app.dart';

Future<void> pumpEvents(
  WidgetTester tester,
  Widget screen,
  FakeEventRepository events, {
  Set<String> permissions = const {Permissions.eventsManage},
  Size surfaceSize = const Size(1024, 2600),
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    surfaceSize: surfaceSize,
    overrides: [
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(session: testUser(permissions: permissions)),
      ),
      contentRepositoryProvider.overrideWithValue(FakeContentRepository()),
      eventRepositoryProvider.overrideWithValue(events),
    ],
  );
  await tester.pumpAndSettle();
}

void main() {
  group('EventsScreen (public)', () {
    testWidgets('lists the occurrences the server returned', (tester) async {
      final events = FakeEventRepository(
        upcoming: [
          testOccurrence(id: 1, key: '1@2026-10-05', title: 'जन्माष्टमी'),
          testOccurrence(id: 2, key: '2@2026-10-08', title: 'संध्या आरती'),
        ],
      );

      await pumpEvents(tester, const EventsScreen(), events);

      expect(find.text('जन्माष्टमी'), findsOneWidget);
      expect(find.text('संध्या आरती'), findsOneWidget);
      expect(find.byKey(const Key('event-card-1@2026-10-05')), findsOneWidget);
    });

    testWidgets('starts on the upcoming view', (tester) async {
      final events = FakeEventRepository(upcoming: [testOccurrence()]);

      await pumpEvents(tester, const EventsScreen(), events);

      expect(events.lastQuery?.view, EventView.upcoming);
    });

    testWidgets('switching to past asks the server for past events', (
      tester,
    ) async {
      // The client never decides what counts as past; the server does.
      // Titles deliberately unlike the view-switch labels, so the assertions
      // are about the list rather than about the buttons.
      final events = FakeEventRepository(
        upcoming: [testOccurrence(title: 'जन्माष्टमी')],
        past: [testOccurrence(id: 9, key: '9@2026-09-01', title: 'होली')],
      );

      await pumpEvents(tester, const EventsScreen(), events);
      expect(find.text('जन्माष्टमी'), findsOneWidget);

      await tester.tap(find.text('पूर्व कार्यक्रम'));
      await tester.pumpAndSettle();

      expect(events.lastQuery?.view, EventView.past);
      expect(find.text('होली'), findsOneWidget);
      expect(find.text('जन्माष्टमी'), findsNothing);
    });

    testWidgets('an empty calendar is an empty state, not an error', (
      tester,
    ) async {
      await pumpEvents(tester, const EventsScreen(), FakeEventRepository());

      expect(find.byKey(const Key('events-empty')), findsOneWidget);
      expect(
        find.text('अभी कोई आगामी कार्यक्रम निर्धारित नहीं है।'),
        findsOneWidget,
      );
    });

    testWidgets('an outage offers a retry', (tester) async {
      final events = FakeEventRepository(
        listError: const AppException(code: ErrorCode.network),
      );

      await pumpEvents(tester, const EventsScreen(), events);

      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });

    testWidgets('a cancelled event is shown and marked, not hidden', (
      tester,
    ) async {
      // Devotees who planned around it need to be told it is off.
      final events = FakeEventRepository(
        upcoming: [testOccurrence(title: 'रद्द उत्सव', isCancelled: true)],
      );

      await pumpEvents(tester, const EventsScreen(), events);

      expect(find.text('रद्द उत्सव'), findsOneWidget);
      expect(
        find.byKey(const Key('event-cancelled-1@2026-10-05')),
        findsOneWidget,
      );
    });

    testWidgets('a repeating event carries its recurrence label', (
      tester,
    ) async {
      final events = FakeEventRepository(
        upcoming: [
          testOccurrence(
            type: EventTypes.aarti,
            isRecurring: true,
            recurrence: Recurrences.daily,
          ),
        ],
      );

      await pumpEvents(tester, const EventsScreen(), events);

      expect(find.text('प्रतिदिन'), findsOneWidget);
      expect(find.text('आरती'), findsOneWidget);
    });

    testWidgets('a Hindi-only event shows the fallback notice', (tester) async {
      final events = FakeEventRepository(
        upcoming: [testOccurrence(fallbackUsed: true)],
      );

      await pumpEvents(tester, const EventsScreen(), events);

      expect(find.byKey(const Key('fallback-notice')), findsOneWidget);
    });

    testWidgets('cards in a row are the same height', (tester) async {
      final events = FakeEventRepository(
        upcoming: [
          testOccurrence(
            id: 1,
            key: '1@a',
            description: 'एक लम्बा विवरण जो कई पंक्तियों में फैलता है।',
            venue: 'मंदिर प्रांगण',
          ),
          testOccurrence(id: 2, key: '2@b', title: 'छोटा'),
        ],
      );

      await pumpEvents(tester, const EventsScreen(), events);

      final first = tester.getSize(find.byKey(const Key('event-card-1@a')));
      final second = tester.getSize(find.byKey(const Key('event-card-2@b')));

      expect(second.height, first.height);
      expect(second.width, first.width);
    });
  });

  group('EventDetailScreen', () {
    testWidgets('renders the event it was asked for', (tester) async {
      final events = FakeEventRepository(
        upcoming: [testOccurrence(id: 4, title: 'जन्माष्टमी')],
      );

      await pumpEvents(tester, const EventDetailScreen(eventId: 4), events);

      expect(find.byKey(const Key('event-title')), findsOneWidget);
      expect(find.text('जन्माष्टमी'), findsOneWidget);
    });

    testWidgets('passes the occurrence date through to the API', (
      tester,
    ) async {
      // A shared link to "the aarti on the 12th" must still say the 12th.
      final events = FakeEventRepository(upcoming: [testOccurrence(id: 4)]);

      await pumpEvents(
        tester,
        const EventDetailScreen(eventId: 4, on: '2026-10-12'),
        events,
      );

      expect(events.lastOn, '2026-10-12');
    });

    testWidgets('a cancelled event carries a notice, not just a strike', (
      tester,
    ) async {
      final events = FakeEventRepository(
        upcoming: [testOccurrence(id: 4, isCancelled: true)],
      );

      await pumpEvents(tester, const EventDetailScreen(eventId: 4), events);

      expect(find.byKey(const Key('event-cancelled-notice')), findsOneWidget);
    });

    testWidgets('an unknown event renders the not-found screen', (
      tester,
    ) async {
      final events = FakeEventRepository(
        detailError: const AppException(code: ErrorCode.notFound),
      );

      await pumpEvents(tester, const EventDetailScreen(eventId: 99), events);

      expect(find.text('पृष्ठ नहीं मिला'), findsOneWidget);
    });

    testWidgets('a transport failure offers a retry rather than not-found', (
      tester,
    ) async {
      final events = FakeEventRepository(
        detailError: const AppException(code: ErrorCode.network),
      );

      await pumpEvents(tester, const EventDetailScreen(eventId: 4), events);

      expect(find.text('पुनः प्रयास करें'), findsOneWidget);
    });

    testWidgets('a repeating event lists its next dates', (tester) async {
      final events = FakeEventRepository()
        ..detail = EventDetail(
          event: testOccurrence(
            id: 4,
            key: '4@2026-10-12',
            isRecurring: true,
            recurrence: Recurrences.daily,
          ),
          occurrences: [
            testOccurrence(
              id: 4,
              key: '4@2026-10-12',
              isRecurring: true,
              recurrence: Recurrences.daily,
            ),
            testOccurrence(
              id: 4,
              key: '4@2026-10-13',
              isRecurring: true,
              recurrence: Recurrences.daily,
              startAt: DateTime(2026, 10, 13, 18, 0),
            ),
          ],
        );

      await pumpEvents(tester, const EventDetailScreen(eventId: 4), events);

      expect(find.text('आगामी तिथियाँ'), findsOneWidget);
      expect(
        find.byKey(const Key('event-occurrence-4@2026-10-13')),
        findsOneWidget,
      );
    });
  });

  group('AdminEventsScreen', () {
    testWidgets('lists every event including drafts', (tester) async {
      final events = FakeEventRepository()
        ..adminList = [
          testAdminEvent(
            id: 1,
            titleHi: 'प्रकाशित उत्सव',
            status: EventStatuses.published,
          ),
          testAdminEvent(id: 2, titleHi: 'मसौदा पूजा'),
        ];

      await pumpEvents(tester, const AdminEventsScreen(), events);

      expect(find.byKey(const Key('admin-event-1')), findsOneWidget);
      expect(find.byKey(const Key('admin-event-2')), findsOneWidget);
      expect(find.text('मसौदा पूजा'), findsOneWidget);
    });

    testWidgets('a repeating event is one row, labelled with its rule', (
      tester,
    ) async {
      // The point the committee has to understand: it is a rule, not 365 rows.
      final events = FakeEventRepository()
        ..adminList = [
          testAdminEvent(
            id: 1,
            titleHi: 'संध्या आरती',
            recurrence: Recurrences.weekly,
            recurrenceDays: const [2, 6],
          ),
        ];

      await pumpEvents(tester, const AdminEventsScreen(), events);

      expect(find.byKey(const Key('admin-event-repeats-1')), findsOneWidget);
      expect(find.textContaining('साप्ताहिक'), findsOneWidget);
      expect(find.textContaining('मंगल'), findsOneWidget);
    });

    testWidgets('the status filter narrows the list', (tester) async {
      final events = FakeEventRepository()
        ..adminList = [
          testAdminEvent(
            id: 1,
            titleHi: 'प्रकाशित',
            status: EventStatuses.published,
          ),
          testAdminEvent(id: 2, titleHi: 'मसौदा'),
        ];

      await pumpEvents(tester, const AdminEventsScreen(), events);
      expect(find.text('मसौदा'), findsWidgets);

      await tester.tap(find.byKey(const Key('event-filter-published')));
      await tester.pumpAndSettle();

      expect(events.lastStatusFilter, EventStatuses.published);
      expect(find.text('प्रकाशित'), findsWidgets);
    });

    testWidgets('an empty calendar shows the empty state', (tester) async {
      await pumpEvents(
        tester,
        const AdminEventsScreen(),
        FakeEventRepository(),
      );

      expect(find.byKey(const Key('admin-events-empty')), findsOneWidget);
    });

    testWidgets('without events.manage the add button is not offered', (
      tester,
    ) async {
      await pumpEvents(
        tester,
        const AdminEventsScreen(),
        FakeEventRepository(),
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('event-new')), findsNothing);
    });

    testWidgets('a forbidden load shows the unauthorized state', (
      tester,
    ) async {
      final events = FakeEventRepository(
        adminError: const AppException(code: ErrorCode.forbidden),
      );

      await pumpEvents(tester, const AdminEventsScreen(), events);

      expect(find.text('अनुमति नहीं है'), findsOneWidget);
    });
  });

  group('AdminEventEditorScreen', () {
    testWidgets('a new event starts as a draft and repeats once', (
      tester,
    ) async {
      // Publishing is a deliberate act, so a new entry is not live by accident.
      await pumpEvents(
        tester,
        const AdminEventEditorScreen(),
        FakeEventRepository(),
      );

      expect(find.text('मसौदा'), findsWidgets);
      expect(find.text('एक बार'), findsWidgets);
      // The weekday picker belongs to a weekly rule only.
      expect(find.byKey(const Key('event-day-1')), findsNothing);
    });

    testWidgets('the weekday picker appears only for a weekly rule', (
      tester,
    ) async {
      await pumpEvents(
        tester,
        const AdminEventEditorScreen(),
        FakeEventRepository(),
      );

      await tester.tap(find.byKey(const Key('event-recurrence')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('साप्ताहिक').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-day-1')), findsOneWidget);
      expect(find.byKey(const Key('event-day-7')), findsOneWidget);
    });

    testWidgets('a Hindi title is required before the API is called', (
      tester,
    ) async {
      final events = FakeEventRepository();

      await pumpEvents(tester, const AdminEventEditorScreen(), events);

      await tester.tap(find.byKey(const Key('event-save')));
      await tester.pumpAndSettle();

      expect(find.text('यह जानकारी आवश्यक है'), findsOneWidget);
      expect(events.createCalls, 0);
    });

    testWidgets('creating an event sends the typed values', (tester) async {
      final events = FakeEventRepository();

      await pumpEvents(tester, const AdminEventEditorScreen(), events);

      await tester.enterText(
        find.byKey(const Key('event-title_hi')),
        'जन्माष्टमी',
      );
      await tester.tap(find.byKey(const Key('event-save')));
      await tester.pumpAndSettle();

      expect(events.createCalls, 1);
      final json = events.lastDraft!.toJson();
      expect(json['title_hi'], 'जन्माष्टमी');
      expect(json['status'], EventStatuses.draft);
    });

    testWidgets('loads an existing event into the form', (tester) async {
      final events = FakeEventRepository()
        ..adminList = [
          testAdminEvent(
            id: 5,
            titleHi: 'संध्या आरती',
            venueHi: 'मुख्य मंदिर',
            recurrence: Recurrences.daily,
            status: EventStatuses.published,
          ),
        ];

      await pumpEvents(
        tester,
        const AdminEventEditorScreen(eventId: 5),
        events,
      );

      expect(find.text('संध्या आरती'), findsOneWidget);
      expect(find.text('मुख्य मंदिर'), findsOneWidget);
      expect(find.text('प्रतिदिन'), findsWidgets);
    });

    testWidgets('a server refusal on a date is shown against that field', (
      tester,
    ) async {
      final events = FakeEventRepository()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'end_at': ['The event cannot end before it starts.'],
          },
        );

      await pumpEvents(tester, const AdminEventEditorScreen(), events);

      await tester.enterText(find.byKey(const Key('event-title_hi')), 'पूजा');
      await tester.tap(find.byKey(const Key('event-save')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-error')), findsOneWidget);
      expect(
        find.text('The event cannot end before it starts.'),
        findsOneWidget,
      );
    });

    testWidgets('a refusal with no field of its own is still shown', (
      tester,
    ) async {
      final events = FakeEventRepository()
        ..saveError = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {
            'recurrence_days': ['Choose at least one day.'],
          },
        );

      await pumpEvents(tester, const AdminEventEditorScreen(), events);

      await tester.enterText(find.byKey(const Key('event-title_hi')), 'पूजा');
      await tester.tap(find.byKey(const Key('event-save')));
      await tester.pumpAndSettle();

      expect(find.text('Choose at least one day.'), findsOneWidget);
    });

    testWidgets('deleting asks first and only then calls the API', (
      tester,
    ) async {
      final events = FakeEventRepository()..adminList = [testAdminEvent(id: 8)];

      await pumpEvents(
        tester,
        const AdminEventEditorScreen(eventId: 8),
        events,
      );

      await tester.tap(find.byKey(const Key('event-delete')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event-delete-dialog')), findsOneWidget);
      expect(events.deleteCalls, 0);

      await tester.tap(find.byKey(const Key('event-delete-confirm')));
      await tester.pumpAndSettle();

      expect(events.deleteCalls, 1);
      expect(events.lastDeletedId, 8);
    });

    testWidgets('without events.manage the editor is read-only', (
      tester,
    ) async {
      final events = FakeEventRepository()..adminList = [testAdminEvent(id: 8)];

      await pumpEvents(
        tester,
        const AdminEventEditorScreen(eventId: 8),
        events,
        permissions: const {Permissions.contentView},
      );

      expect(find.byKey(const Key('event-read-only')), findsOneWidget);
      expect(find.byKey(const Key('event-save')), findsNothing);
      expect(find.byKey(const Key('event-delete')), findsNothing);
    });
  });
}
