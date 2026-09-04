import 'event.dart';

/// What the public events list is asking for.
class EventQuery {
  const EventQuery({
    this.view = EventView.upcoming,
    this.days,
    this.featured = false,
    this.type,
  });

  final EventView view;
  final int? days;
  final bool featured;
  final String? type;

  Map<String, Object?> toQueryParameters(String language) => {
    'lang': language,
    'view': view.wireValue,
    'days': ?days,
    if (featured) 'featured': 1,
    'type': ?type,
  };

  // Value equality because this is a provider family key: without it every
  // rebuild would ask for a new provider and refetch the same list.
  @override
  bool operator ==(Object other) =>
      other is EventQuery &&
      other.view == view &&
      other.days == days &&
      other.featured == featured &&
      other.type == type;

  @override
  int get hashCode => Object.hash(view, days, featured, type);
}

enum EventView {
  upcoming('upcoming'),
  past('past');

  const EventView(this.wireValue);

  final String wireValue;
}

/// Contract for reading and editing the calendar.
///
/// Implementations live in `data/` and are the only place that knows about HTTP.
abstract interface class EventRepository {
  /// Dated occurrences a visitor may see. The server expands recurrence rules;
  /// the client never does that arithmetic itself.
  Future<List<EventOccurrence>> events(
    EventQuery query, {
    required String language,
  });

  /// One event with its next occurrences. [on] names which occurrence the
  /// visitor arrived at, so a shared link keeps its date.
  Future<EventDetail> event(int id, {required String language, String? on});

  /// Every event including drafts, cancelled and past ones. Requires
  /// `content.view`.
  Future<List<AdminEvent>> adminEvents({String? status});

  /// One event loaded raw for editing.
  Future<AdminEvent> adminEvent(int id);

  /// Creates an event. Requires `events.manage`.
  Future<AdminEvent> createEvent(EventDraft draft);

  /// Updates an event. Requires `events.manage`.
  Future<AdminEvent> saveEvent(int id, EventDraft draft);

  /// Removes an event entirely. Cancelling keeps the record and tells devotees
  /// it is off; deleting is for entries created by mistake.
  Future<void> deleteEvent(int id);
}

/// An event page: the occurrence being viewed plus the ones that follow it.
class EventDetail {
  const EventDetail({required this.event, required this.occurrences});

  /// Null when the event exists but produced no occurrence in range.
  final EventOccurrence? event;

  final List<EventOccurrence> occurrences;

  bool get hasEvent => event != null;
}
