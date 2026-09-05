import '../../content/domain/localized_value.dart';

/// The kinds of event the calendar carries.
///
/// Mirrors `App\Support\EventType`. The labels are translated in the client, so
/// adding a type is one constant here and two ARB entries — not a migration.
class EventTypes {
  const EventTypes._();

  static const String aarti = 'aarti';
  static const String bhajanKirtan = 'bhajan_kirtan';
  static const String festival = 'festival';
  static const String puja = 'puja';

  /// Bhandara, prasad and the other things the temple does for the village
  /// that are not worship. Mirrors `App\Support\EventType`.
  static const String communityService = 'community_service';
  static const String other = 'other';

  static const List<String> all = [
    aarti,
    bhajanKirtan,
    festival,
    puja,
    communityService,
    other,
  ];

  static bool exists(String value) => all.contains(value);
}

/// Publication state, mirroring `App\Models\Event`.
class EventStatuses {
  const EventStatuses._();

  static const String draft = 'draft';
  static const String published = 'published';
  static const String cancelled = 'cancelled';

  static const List<String> all = [draft, published, cancelled];
}

/// How an event repeats, mirroring `App\Models\Event`.
class Recurrences {
  const Recurrences._();

  static const String none = 'none';
  static const String daily = 'daily';
  static const String weekly = 'weekly';
  static const String monthly = 'monthly';
  static const String yearly = 'yearly';

  static const List<String> all = [none, daily, weekly, monthly, yearly];
}

/// One dated occurrence of an event, as the public API sends it.
///
/// A recurring event is stored once as a rule; the server expands it and the
/// client receives dates. There is no recurrence arithmetic here — doing it in
/// two places is how the two disagree.
class EventOccurrence {
  const EventOccurrence({
    required this.id,
    required this.occurrenceKey,
    required this.eventType,
    required this.title,
    required this.description,
    required this.venue,
    required this.startAt,
    required this.isRecurring,
    required this.recurrence,
    required this.isFeatured,
    required this.isCancelled,
    this.endAt,
    this.posterUrl,
  });

  factory EventOccurrence.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final start = read('start_at');

    return EventOccurrence(
      id: _asInt(json['id']) ?? 0,
      occurrenceKey: read('occurrence_key') ?? '${json['id']}',
      eventType: read('event_type') ?? EventTypes.other,
      title: LocalizedValue.fromJson(json['title']),
      description: LocalizedValue.fromJson(json['description']),
      venue: LocalizedValue.fromJson(json['venue']),
      startAt: start == null ? DateTime.now() : templeClock(start),
      endAt: read('end_at') == null ? null : templeClock(read('end_at')!),
      isRecurring: json['is_recurring'] == true,
      recurrence: read('recurrence') ?? Recurrences.none,
      isFeatured: json['is_featured'] == true,
      isCancelled: json['is_cancelled'] == true,
      posterUrl: read('poster_url'),
    );
  }

  /// Reads an ISO-8601 instant as the **temple's** wall clock.
  ///
  /// Deliberately not `toLocal()`. The aarti is at 6:30 pm at the temple, and
  /// that is what everyone should be told — a relative reading this from London
  /// wants to know when it happens there, not that it is 1:00 pm for them.
  ///
  /// Converting to the device's zone also made "does this event run past
  /// midnight?" depend on where the reader was standing: a 5 pm to 1 am
  /// festival spans two days in the temple's zone and one day in UTC.
  ///
  /// The server sends the offset, so the components before it are already the
  /// temple's clock; dropping the designator keeps them.
  static DateTime templeClock(String iso) {
    final withoutZone = iso.replaceFirst(RegExp(r'(Z|[+-]\d{2}:?\d{2})$'), '');
    return DateTime.parse(withoutZone);
  }

  final int id;

  /// Identifies one occurrence of a repeating event, so a link to "the aarti on
  /// the 12th" survives being shared.
  final String occurrenceKey;

  final String eventType;
  final LocalizedValue title;
  final LocalizedValue description;
  final LocalizedValue venue;
  final DateTime startAt;
  final DateTime? endAt;
  final bool isRecurring;
  final String recurrence;
  final bool isFeatured;
  final bool isCancelled;
  final String? posterUrl;

  /// The date part of this occurrence, for a link back to it.
  String get occurrenceDate =>
      '${startAt.year.toString().padLeft(4, '0')}-'
      '${startAt.month.toString().padLeft(2, '0')}-'
      '${startAt.day.toString().padLeft(2, '0')}';

  bool get spansMultipleDays {
    final end = endAt;
    if (end == null) return false;
    return end.year != startAt.year ||
        end.month != startAt.month ||
        end.day != startAt.day;
  }

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// An event as the editor sees it: both languages raw, and the recurrence rule
/// rather than the dates it produces.
class AdminEvent {
  const AdminEvent({
    required this.id,
    required this.eventType,
    required this.titleHi,
    required this.startAt,
    required this.recurrence,
    required this.recurrenceDays,
    required this.isFeatured,
    required this.status,
    this.titleEn,
    this.descriptionHi,
    this.descriptionEn,
    this.venueHi,
    this.venueEn,
    this.endAt,
    this.recurrenceUntil,
    this.posterUrl,
  });

  factory AdminEvent.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    final days = json['recurrence_days'];

    return AdminEvent(
      id: EventOccurrence._asInt(json['id']) ?? 0,
      eventType: read('event_type') ?? EventTypes.other,
      titleHi: read('title_hi') ?? '',
      titleEn: read('title_en'),
      descriptionHi: read('description_hi'),
      descriptionEn: read('description_en'),
      venueHi: read('venue_hi'),
      venueEn: read('venue_en'),
      // The temple's clock, not the reader's — see EventOccurrence.templeClock.
      startAt: read('start_at') == null
          ? DateTime.now()
          : EventOccurrence.templeClock(read('start_at')!),
      endAt: read('end_at') == null
          ? null
          : EventOccurrence.templeClock(read('end_at')!),
      recurrence: read('recurrence') ?? Recurrences.none,
      recurrenceDays: days is List
          ? days.map(EventOccurrence._asInt).whereType<int>().toList()
          : const [],
      recurrenceUntil: read('recurrence_until'),
      posterUrl: read('poster_url'),
      isFeatured: json['is_featured'] == true,
      status: read('status') ?? EventStatuses.draft,
    );
  }

  final int id;
  final String eventType;
  final String titleHi;
  final String? titleEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final String? venueHi;
  final String? venueEn;
  final DateTime startAt;
  final DateTime? endAt;
  final String recurrence;
  final List<int> recurrenceDays;
  final String? recurrenceUntil;
  final String? posterUrl;
  final bool isFeatured;
  final String status;

  bool get isPublished => status == EventStatuses.published;

  bool get isCancelled => status == EventStatuses.cancelled;

  bool get repeats => recurrence != Recurrences.none;

  bool get hasPassed {
    final finish = endAt ?? startAt;
    return !repeats && finish.isBefore(DateTime.now());
  }
}

/// The event an editor is submitting.
class EventDraft {
  const EventDraft({
    required this.eventType,
    required this.titleHi,
    required this.startAt,
    required this.status,
    required this.recurrence,
    required this.isFeatured,
    this.titleEn,
    this.descriptionHi,
    this.descriptionEn,
    this.venueHi,
    this.venueEn,
    this.endAt,
    this.recurrenceDays = const [],
    this.recurrenceUntil,
    this.posterUrl,
  });

  final String eventType;
  final String titleHi;
  final String? titleEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final String? venueHi;
  final String? venueEn;
  final DateTime startAt;
  final DateTime? endAt;
  final String recurrence;
  final List<int> recurrenceDays;
  final String? recurrenceUntil;
  final String? posterUrl;
  final bool isFeatured;
  final String status;

  /// Blank optional fields are sent as null so the server stores "absent"
  /// rather than an empty string, which is what the fallback rule keys on.
  Map<String, Object?> toJson() => {
    'event_type': eventType,
    'title_hi': titleHi.trim(),
    'title_en': _nullIfBlank(titleEn),
    'description_hi': _nullIfBlank(descriptionHi),
    'description_en': _nullIfBlank(descriptionEn),
    'venue_hi': _nullIfBlank(venueHi),
    'venue_en': _nullIfBlank(venueEn),
    'start_at': _wire(startAt),
    'end_at': endAt == null ? null : _wire(endAt!),
    'recurrence': recurrence,
    'recurrence_days': recurrence == Recurrences.weekly ? recurrenceDays : null,
    'recurrence_until': _nullIfBlank(recurrenceUntil),
    'poster_url': _nullIfBlank(posterUrl),
    'is_featured': isFeatured,
    'status': status,
  };

  /// Sent without a zone: the server reads it in the temple's timezone, which
  /// is the one the committee typed in.
  static String _wire(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')} '
      '${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}:00';

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
