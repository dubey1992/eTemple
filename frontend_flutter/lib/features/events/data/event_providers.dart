import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/event.dart';
import '../domain/event_repository.dart';
import 'event_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final eventRepositoryProvider = Provider<EventRepository>(
  (ref) => EventRepositoryImpl(ref.watch(apiClientProvider)),
);

/// Which slice of the calendar the public events page is showing.
///
/// Held in a provider rather than in the screen's state so the choice survives
/// a rebuild — switching language must not throw the visitor back to the first
/// tab while they are reading the past events.
class EventViewController extends Notifier<EventView> {
  /// Opens on today. Most people arriving at a temple calendar are asking what
  /// is on *now*; the aarti runs daily, so this is rarely an empty page, and
  /// when it is the screen offers a way forward.
  @override
  EventView build() => EventView.today;

  void select(EventView view) => state = view;
}

final eventViewProvider = NotifierProvider<EventViewController, EventView>(
  EventViewController.new,
);

/// Occurrences for the selected view, in the visitor's language.
final eventsProvider = FutureProvider.family<List<EventOccurrence>, EventQuery>(
  (ref, query) {
    final language = ref.watch(contentLanguageProvider);
    return ref.watch(eventRepositoryProvider).events(query, language: language);
  },
);

/// The upcoming events shown on the home page.
///
/// Asks for [EventView.upcoming] — the overlapping view that keeps today's
/// remaining events — and not the events page's [EventView.afterToday], which
/// would empty this block of the evening aarti every morning.
final featuredEventsProvider = FutureProvider<List<EventOccurrence>>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref
      .watch(eventRepositoryProvider)
      .events(const EventQuery(days: 60), language: language);
});

/// One event page. The record carries the occurrence date so a shared link to
/// a particular day still resolves to that day.
final eventDetailProvider =
    FutureProvider.family<EventDetail, EventDetailRequest>((ref, request) {
      final language = ref.watch(contentLanguageProvider);
      return ref
          .watch(eventRepositoryProvider)
          .event(request.id, language: language, on: request.on);
    });

/// Identifies one event page, so the family keys on the date as well as the id.
class EventDetailRequest {
  const EventDetailRequest(this.id, {this.on});

  final int id;
  final String? on;

  @override
  bool operator ==(Object other) =>
      other is EventDetailRequest && other.id == id && other.on == on;

  @override
  int get hashCode => Object.hash(id, on);
}

/// Every event including drafts. Admin-only; the server enforces that.
final adminEventsProvider = FutureProvider.family<List<AdminEvent>, String?>(
  (ref, status) =>
      ref.watch(eventRepositoryProvider).adminEvents(status: status),
);

/// One event loaded raw for editing.
final adminEventProvider = FutureProvider.family<AdminEvent, int>(
  (ref, id) => ref.watch(eventRepositoryProvider).adminEvent(id),
);
