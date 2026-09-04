import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/event.dart';
import '../domain/event_repository.dart';

/// HTTP implementation of [EventRepository] against the Laravel API.
class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<EventOccurrence>> events(
    EventQuery query, {
    required String language,
  }) async {
    final envelope = await _api.get<List<EventOccurrence>>(
      ApiEndpoints.publicEvents,
      queryParameters: query.toQueryParameters(language),
      decode: (data) => _list(
        data,
        'events',
      ).map(EventOccurrence.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<EventDetail> event(
    int id, {
    required String language,
    String? on,
  }) async {
    final envelope = await _api.get<EventDetail>(
      ApiEndpoints.publicEvent(id),
      queryParameters: {'lang': language, 'on': ?on},
      decode: (data) {
        final json = _object(data, 'event');
        final event = ApiEnvelopeParser.asMap(json['event']);

        return EventDetail(
          event: event == null ? null : EventOccurrence.fromJson(event),
          occurrences: _list(
            json['occurrences'],
            'occurrences',
          ).map(EventOccurrence.fromJson).toList(growable: false),
        );
      },
    );
    return envelope.data;
  }

  @override
  Future<List<AdminEvent>> adminEvents({String? status}) async {
    final envelope = await _api.get<List<AdminEvent>>(
      ApiEndpoints.adminEvents,
      queryParameters: {'status': ?status},
      decode: (data) => _list(
        data,
        'events',
      ).map(AdminEvent.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<AdminEvent> adminEvent(int id) async {
    final envelope = await _api.get<AdminEvent>(
      ApiEndpoints.adminEvent(id),
      decode: (data) => AdminEvent.fromJson(_object(data, 'event')),
    );
    return envelope.data;
  }

  @override
  Future<AdminEvent> createEvent(EventDraft draft) async {
    final envelope = await _api.post<AdminEvent>(
      ApiEndpoints.adminEvents,
      body: draft.toJson(),
      decode: (data) => AdminEvent.fromJson(_object(data, 'event')),
    );
    return envelope.data;
  }

  @override
  Future<AdminEvent> saveEvent(int id, EventDraft draft) async {
    final envelope = await _api.put<AdminEvent>(
      ApiEndpoints.adminEvent(id),
      body: draft.toJson(),
      decode: (data) => AdminEvent.fromJson(_object(data, 'event')),
    );
    return envelope.data;
  }

  @override
  Future<void> deleteEvent(int id) async {
    await _api.delete<void>(ApiEndpoints.adminEvent(id), decode: (_) {});
  }

  static List<Map<String, dynamic>> _list(Object? data, String what) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }
    return data
        .map(ApiEnvelopeParser.asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic> _object(Object? data, String what) {
    final json = ApiEnvelopeParser.asMap(data);
    if (json == null) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a $what object in the response data.',
      );
    }
    return json;
  }
}
