import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/events/domain/event.dart';
import 'package:rkt_web/features/events/domain/event_repository.dart';

/// Scriptable stand-in for the HTTP event repository.
///
/// The fake returns whatever occurrences a test hands it: recurrence expansion
/// belongs to the server and is tested there, so duplicating that arithmetic
/// here would only create a second implementation to disagree with.
class FakeEventRepository implements EventRepository {
  FakeEventRepository({
    List<EventOccurrence>? upcoming,
    List<EventOccurrence>? past,
    this.listError,
    this.detailError,
    this.adminError,
    this.saveError,
    this.delay = Duration.zero,
  }) : upcoming = upcoming ?? const [],
       past = past ?? const [];

  List<EventOccurrence> upcoming;
  List<EventOccurrence> past;
  List<AdminEvent> adminList = [];
  EventDetail? detail;

  AppException? listError;
  AppException? detailError;
  AppException? adminError;
  AppException? saveError;
  Duration delay;

  int listCalls = 0;
  int createCalls = 0;
  int saveCalls = 0;
  int deleteCalls = 0;

  EventQuery? lastQuery;
  String? lastLanguage;
  String? lastStatusFilter;
  String? lastOn;
  EventDraft? lastDraft;
  int? lastDeletedId;

  Future<void> _pause() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<List<EventOccurrence>> events(
    EventQuery query, {
    required String language,
  }) async {
    listCalls++;
    lastQuery = query;
    lastLanguage = language;
    await _pause();
    if (listError != null) throw listError!;

    return query.view == EventView.past ? past : upcoming;
  }

  @override
  Future<EventDetail> event(
    int id, {
    required String language,
    String? on,
  }) async {
    lastLanguage = language;
    lastOn = on;
    await _pause();
    if (detailError != null) throw detailError!;

    final existing = detail;
    if (existing != null) return existing;

    final match = upcoming.where((o) => o.id == id).toList();
    if (match.isEmpty) {
      throw const AppException(code: ErrorCode.notFound);
    }
    return EventDetail(event: match.first, occurrences: match);
  }

  @override
  Future<List<AdminEvent>> adminEvents({String? status}) async {
    lastStatusFilter = status;
    await _pause();
    if (adminError != null) throw adminError!;

    return status == null
        ? adminList
        : adminList.where((e) => e.status == status).toList();
  }

  @override
  Future<AdminEvent> adminEvent(int id) async {
    await _pause();
    if (adminError != null) throw adminError!;

    return adminList.firstWhere(
      (e) => e.id == id,
      orElse: () => throw const AppException(code: ErrorCode.notFound),
    );
  }

  @override
  Future<AdminEvent> createEvent(EventDraft draft) async {
    createCalls++;
    lastDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminEvent(id: 99, titleHi: draft.titleHi);
  }

  @override
  Future<AdminEvent> saveEvent(int id, EventDraft draft) async {
    saveCalls++;
    lastDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminEvent(id: id, titleHi: draft.titleHi);
  }

  @override
  Future<void> deleteEvent(int id) async {
    deleteCalls++;
    lastDeletedId = id;
    await _pause();
    if (saveError != null) throw saveError!;
  }
}

LocalizedValue _hi(String? value, {bool fallbackUsed = false}) =>
    LocalizedValue(value: value, language: 'hi', fallbackUsed: fallbackUsed);

/// One public occurrence, as the API would send it.
EventOccurrence testOccurrence({
  int id = 1,
  String key = '1@2026-10-05',
  String type = EventTypes.puja,
  String title = 'परीक्षण कार्यक्रम',
  String? description,
  String? venue,
  DateTime? startAt,
  DateTime? endAt,
  bool isRecurring = false,
  String recurrence = Recurrences.none,
  bool isFeatured = false,
  bool isCancelled = false,
  bool fallbackUsed = false,
}) {
  return EventOccurrence(
    id: id,
    occurrenceKey: key,
    eventType: type,
    title: _hi(title, fallbackUsed: fallbackUsed),
    description: _hi(description),
    venue: _hi(venue),
    startAt: startAt ?? DateTime(2026, 10, 5, 18, 0),
    endAt: endAt,
    isRecurring: isRecurring,
    recurrence: recurrence,
    isFeatured: isFeatured,
    isCancelled: isCancelled,
  );
}

/// One event as the editor sees it.
AdminEvent testAdminEvent({
  int id = 1,
  String titleHi = 'परीक्षण कार्यक्रम',
  String type = EventTypes.puja,
  String status = EventStatuses.draft,
  String recurrence = Recurrences.none,
  List<int> recurrenceDays = const [],
  DateTime? startAt,
  DateTime? endAt,
  bool isFeatured = false,
  String? venueHi,
}) {
  return AdminEvent(
    id: id,
    eventType: type,
    titleHi: titleHi,
    venueHi: venueHi,
    startAt: startAt ?? DateTime(2026, 10, 5, 18, 0),
    endAt: endAt,
    recurrence: recurrence,
    recurrenceDays: recurrenceDays,
    isFeatured: isFeatured,
    status: status,
  );
}
