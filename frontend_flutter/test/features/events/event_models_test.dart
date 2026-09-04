import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/features/events/domain/event.dart';
import 'package:rkt_web/features/events/domain/event_repository.dart';

void main() {
  group('EventOccurrence', () {
    test('parses an occurrence and keeps the offset the server sent', () {
      // The API sends the temple's offset precisely so the device shows the
      // right local time; parsing must not discard it.
      final occurrence = EventOccurrence.fromJson({
        'id': 7,
        'occurrence_key': '7@2026-10-12',
        'event_type': EventTypes.aarti,
        'title': {
          'value': 'संध्या आरती',
          'language': 'hi',
          'fallback_used': false,
        },
        'description': {
          'value': null,
          'language': 'hi',
          'fallback_used': false,
        },
        'venue': {
          'value': 'मुख्य मंदिर',
          'language': 'hi',
          'fallback_used': false,
        },
        'start_at': '2026-10-12T18:30:00+05:30',
        'end_at': '2026-10-12T19:15:00+05:30',
        'is_recurring': true,
        'recurrence': Recurrences.daily,
        'is_featured': false,
        'is_cancelled': false,
      });

      expect(occurrence.id, 7);
      expect(occurrence.occurrenceKey, '7@2026-10-12');
      expect(occurrence.title.value, 'संध्या आरती');
      expect(occurrence.isRecurring, isTrue);
      expect(occurrence.startAt.toUtc(), DateTime.utc(2026, 10, 12, 13, 0));
      expect(occurrence.endAt!.difference(occurrence.startAt).inMinutes, 45);
    });

    test('an occurrence with no end parses without one', () {
      final occurrence = EventOccurrence.fromJson({
        'id': 1,
        'start_at': '2026-10-12T18:30:00+05:30',
      });

      expect(occurrence.endAt, isNull);
      expect(occurrence.spansMultipleDays, isFalse);
    });

    test('recognises an event that runs past midnight', () {
      final occurrence = EventOccurrence.fromJson({
        'id': 1,
        'start_at': '2026-10-12T17:00:00+05:30',
        'end_at': '2026-10-13T01:00:00+05:30',
      });

      expect(occurrence.spansMultipleDays, isTrue);
    });

    test('the occurrence date is the one a shared link carries', () {
      final occurrence = testDate(DateTime(2026, 1, 5, 6, 30));

      expect(occurrence.occurrenceDate, '2026-01-05');
    });

    test('a cancelled occurrence says so', () {
      final occurrence = EventOccurrence.fromJson({
        'id': 1,
        'start_at': '2026-10-12T18:30:00+05:30',
        'is_cancelled': true,
      });

      expect(occurrence.isCancelled, isTrue);
    });
  });

  group('AdminEvent', () {
    test('reads the recurrence rule rather than expanded dates', () {
      final event = AdminEvent.fromJson({
        'id': 3,
        'event_type': EventTypes.bhajanKirtan,
        'title_hi': 'भजन-कीर्तन',
        'start_at': '2026-10-06T19:00:00+05:30',
        'recurrence': Recurrences.weekly,
        'recurrence_days': [2, 6],
        'recurrence_until': '2027-03-31',
        'status': EventStatuses.published,
        'is_featured': true,
      });

      expect(event.repeats, isTrue);
      expect(event.recurrenceDays, [2, 6]);
      expect(event.recurrenceUntil, '2027-03-31');
      expect(event.isPublished, isTrue);
      expect(event.isFeatured, isTrue);
    });

    test('a one-off event knows it repeats no further', () {
      final event = AdminEvent.fromJson({
        'id': 1,
        'title_hi': 'एक बार',
        'start_at': '2026-10-06T19:00:00+05:30',
        'recurrence': Recurrences.none,
        'status': EventStatuses.draft,
      });

      expect(event.repeats, isFalse);
      expect(event.recurrenceDays, isEmpty);
      expect(event.isPublished, isFalse);
      expect(event.isCancelled, isFalse);
    });

    test('a repeating event is never counted as passed', () {
      // The daily aarti began years ago and is still happening.
      final event = AdminEvent.fromJson({
        'id': 1,
        'title_hi': 'आरती',
        'start_at': '2015-01-01T18:30:00+05:30',
        'recurrence': Recurrences.daily,
        'status': EventStatuses.published,
      });

      expect(event.hasPassed, isFalse);
    });
  });

  group('EventDraft', () {
    test('sends blank optional fields as null', () {
      final json = EventDraft(
        eventType: EventTypes.festival,
        titleHi: '  जन्माष्टमी  ',
        titleEn: '   ',
        venueHi: '',
        startAt: DateTime(2026, 10, 15, 18, 0),
        status: EventStatuses.published,
        recurrence: Recurrences.none,
        isFeatured: false,
      ).toJson();

      expect(json['title_hi'], 'जन्माष्टमी');
      expect(json['title_en'], isNull);
      expect(json['venue_hi'], isNull);
      expect(json['end_at'], isNull);
    });

    test('sends the start without a zone, in the temple\'s own clock time', () {
      // The committee typed a local time; sending an offset would risk the
      // server re-interpreting it.
      final json = EventDraft(
        eventType: EventTypes.puja,
        titleHi: 'पूजा',
        startAt: DateTime(2026, 10, 5, 6, 5),
        status: EventStatuses.draft,
        recurrence: Recurrences.none,
        isFeatured: false,
      ).toJson();

      expect(json['start_at'], '2026-10-05 06:05:00');
    });

    test('weekday selections are sent only for a weekly rule', () {
      // A leftover day list on a daily event would be silently misleading.
      final weekly = EventDraft(
        eventType: EventTypes.bhajanKirtan,
        titleHi: 'कीर्तन',
        startAt: DateTime(2026, 10, 6, 19, 0),
        status: EventStatuses.published,
        recurrence: Recurrences.weekly,
        recurrenceDays: const [2, 6],
        isFeatured: false,
      ).toJson();

      final daily = EventDraft(
        eventType: EventTypes.aarti,
        titleHi: 'आरती',
        startAt: DateTime(2026, 10, 6, 18, 30),
        status: EventStatuses.published,
        recurrence: Recurrences.daily,
        recurrenceDays: const [2, 6],
        isFeatured: false,
      ).toJson();

      expect(weekly['recurrence_days'], [2, 6]);
      expect(daily['recurrence_days'], isNull);
    });
  });

  group('EventQuery', () {
    test('two identical queries are the same provider key', () {
      // Without value equality every rebuild would refetch the same list.
      expect(
        const EventQuery(view: EventView.past, days: 30),
        const EventQuery(view: EventView.past, days: 30),
      );
      expect(
        const EventQuery(view: EventView.past).hashCode,
        const EventQuery(view: EventView.past).hashCode,
      );
      expect(
        const EventQuery(view: EventView.past),
        isNot(const EventQuery(view: EventView.upcoming)),
      );
    });

    test('builds the query string the API expects', () {
      final params = const EventQuery(
        view: EventView.past,
        days: 30,
        featured: true,
        type: EventTypes.festival,
      ).toQueryParameters('en');

      expect(params['lang'], 'en');
      expect(params['view'], 'past');
      expect(params['days'], 30);
      expect(params['featured'], 1);
      expect(params['type'], EventTypes.festival);
    });

    test('omits filters that were not asked for', () {
      final params = const EventQuery().toQueryParameters('hi');

      expect(params.containsKey('days'), isFalse);
      expect(params.containsKey('featured'), isFalse);
      expect(params.containsKey('type'), isFalse);
    });
  });
}

EventOccurrence testDate(DateTime startAt) =>
    EventOccurrence.fromJson({'id': 1, 'start_at': startAt.toIso8601String()});
