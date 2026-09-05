import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/announcement.dart';
import '../domain/announcement_repository.dart';

/// HTTP implementation of [AnnouncementRepository] against the Laravel API.
class AnnouncementRepositoryImpl implements AnnouncementRepository {
  const AnnouncementRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<List<PublicAnnouncement>> current({required String language}) async {
    final envelope = await _api.get<List<PublicAnnouncement>>(
      ApiEndpoints.publicAnnouncements,
      queryParameters: {'lang': language},
      decode: (data) => _list(
        data,
        'announcements',
      ).map(PublicAnnouncement.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<AnnouncementPage> announcements(AnnouncementQuery query) async {
    final envelope = await _api.get<List<Announcement>>(
      ApiEndpoints.adminAnnouncements,
      queryParameters: query.toQueryParameters(),
      decode: (data) => _list(
        data,
        'announcements',
      ).map(Announcement.fromJson).toList(growable: false),
    );

    return AnnouncementPage(announcements: envelope.data, meta: envelope.meta);
  }

  @override
  Future<Announcement> announcement(int id) async {
    final envelope = await _api.get<Announcement>(
      ApiEndpoints.adminAnnouncement(id),
      decode: _decode,
    );
    return envelope.data;
  }

  @override
  Future<Announcement> create(AnnouncementDraft draft) async {
    final envelope = await _api.post<Announcement>(
      ApiEndpoints.adminAnnouncements,
      body: draft.toJson(),
      decode: _decode,
    );
    return envelope.data;
  }

  @override
  Future<Announcement> save(int id, AnnouncementDraft draft) async {
    final envelope = await _api.put<Announcement>(
      ApiEndpoints.adminAnnouncement(id),
      body: draft.toJson(),
      decode: _decode,
    );
    return envelope.data;
  }

  @override
  Future<Announcement> publish(int id) async {
    final envelope = await _api.post<Announcement>(
      ApiEndpoints.adminAnnouncementPublish(id),
      decode: _decode,
    );
    return envelope.data;
  }

  @override
  Future<Announcement> archive(int id) async {
    final envelope = await _api.post<Announcement>(
      ApiEndpoints.adminAnnouncementArchive(id),
      decode: _decode,
    );
    return envelope.data;
  }

  @override
  Future<Announcement> send(int id, List<String> channels) async {
    final envelope = await _api.post<Announcement>(
      ApiEndpoints.adminAnnouncementSend(id),
      // Always sent explicitly, never defaulted: the server refuses an empty
      // list, and so should anything on the way to it.
      body: {'channels': channels},
      decode: _decode,
    );
    return envelope.data;
  }

  static Announcement _decode(Object? data) =>
      Announcement.fromJson(_object(data, 'announcement'));

  static List<Map<String, dynamic>> _list(Object? data, String what) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Map<String, dynamic> _object(Object? data, String what) {
    if (data is! Map<String, dynamic>) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected $what.',
      );
    }

    return data;
  }
}
