import 'package:dio/dio.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/media_item.dart';
import '../domain/media_repository.dart';

/// HTTP implementation of [MediaRepository] against the Laravel API.
class MediaRepositoryImpl implements MediaRepository {
  const MediaRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<MediaPage> media(
    GalleryQuery query, {
    required String language,
  }) async {
    final envelope = await _api.get<List<MediaItem>>(
      ApiEndpoints.publicMedia,
      queryParameters: query.toQueryParameters(language),
      decode: (data) =>
          _list(data, 'media').map(MediaItem.fromJson).toList(growable: false),
    );

    // The envelope's pagination block is what tells the gallery whether to keep
    // asking for more, so it is carried through rather than dropped.
    return MediaPage(items: envelope.data, meta: envelope.meta);
  }

  @override
  Future<MediaItem> item(int id, {required String language}) async {
    final envelope = await _api.get<MediaItem>(
      ApiEndpoints.publicMediaItem(id),
      queryParameters: {'lang': language},
      decode: (data) => MediaItem.fromJson(_object(data, 'media item')),
    );
    return envelope.data;
  }

  @override
  Future<List<AlbumSummary>> albums({required String language}) async {
    final envelope = await _api.get<List<AlbumSummary>>(
      ApiEndpoints.publicAlbums,
      queryParameters: {'lang': language},
      decode: (data) => _list(
        data,
        'albums',
      ).map(AlbumSummary.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<List<AdminMedia>> adminMedia({
    String? status,
    String? type,
    int? albumId,
  }) async {
    final envelope = await _api.get<List<AdminMedia>>(
      ApiEndpoints.adminMedia,
      queryParameters: {'status': ?status, 'type': ?type, 'album': ?albumId},
      decode: (data) =>
          _list(data, 'media').map(AdminMedia.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<AdminMedia> adminMediaItem(int id) async {
    final envelope = await _api.get<AdminMedia>(
      ApiEndpoints.adminMediaItem(id),
      decode: (data) => AdminMedia.fromJson(_object(data, 'media item')),
    );
    return envelope.data;
  }

  @override
  Future<AdminMedia> uploadPhoto(PhotoUpload upload) async {
    // Multipart, because this is the one endpoint that carries a file. Dio sets
    // the boundary and content type from the FormData itself.
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        upload.bytes,
        filename: upload.fileName,
        contentType: upload.contentType == null
            ? null
            : DioMediaType.parse(upload.contentType!),
      ),
      'title_hi': upload.titleHi.trim(),
      // Null entries are dropped rather than sent as the string "null": a
      // multipart field has no concept of absence, so an empty optional has to
      // simply not be there.
      'title_en': ?VideoDraft.nullIfBlank(upload.titleEn),
      'caption_hi': ?VideoDraft.nullIfBlank(upload.captionHi),
      'caption_en': ?VideoDraft.nullIfBlank(upload.captionEn),
      'album_id': ?upload.albumId,
      'status': upload.status,
    });

    final envelope = await _api.post<AdminMedia>(
      ApiEndpoints.adminMedia,
      body: form,
      decode: (data) => AdminMedia.fromJson(_object(data, 'media item')),
    );
    return envelope.data;
  }

  @override
  Future<AdminMedia> createVideo(VideoDraft draft) async {
    final envelope = await _api.post<AdminMedia>(
      ApiEndpoints.adminMediaVideo,
      body: draft.toJson(),
      decode: (data) => AdminMedia.fromJson(_object(data, 'media item')),
    );
    return envelope.data;
  }

  @override
  Future<AdminMedia> saveMedia(int id, MediaDraft draft) async {
    final envelope = await _api.put<AdminMedia>(
      ApiEndpoints.adminMediaItem(id),
      body: draft.toJson(),
      decode: (data) => AdminMedia.fromJson(_object(data, 'media item')),
    );
    return envelope.data;
  }

  @override
  Future<void> deleteMedia(int id) async {
    await _api.delete<void>(ApiEndpoints.adminMediaItem(id), decode: (_) {});
  }

  @override
  Future<MediaReferences> references(int id) async {
    final envelope = await _api.get<MediaReferences>(
      ApiEndpoints.adminMediaReferences(id),
      decode: (data) => MediaReferences.fromJson(_object(data, 'references')),
    );
    return envelope.data;
  }

  @override
  Future<void> reorder(List<int> ids) async {
    await _api.post<void>(
      ApiEndpoints.adminMediaReorder,
      body: {'ids': ids},
      decode: (_) {},
    );
  }

  @override
  Future<List<AdminAlbum>> adminAlbums() async {
    final envelope = await _api.get<List<AdminAlbum>>(
      ApiEndpoints.adminAlbums,
      decode: (data) => _list(
        data,
        'albums',
      ).map(AdminAlbum.fromJson).toList(growable: false),
    );
    return envelope.data;
  }

  @override
  Future<AdminAlbum> createAlbum(AlbumDraft draft) async {
    final envelope = await _api.post<AdminAlbum>(
      ApiEndpoints.adminAlbums,
      body: draft.toJson(),
      decode: (data) => AdminAlbum.fromJson(_object(data, 'album')),
    );
    return envelope.data;
  }

  @override
  Future<AdminAlbum> saveAlbum(int id, AlbumDraft draft) async {
    final envelope = await _api.put<AdminAlbum>(
      ApiEndpoints.adminAlbum(id),
      body: draft.toJson(),
      decode: (data) => AdminAlbum.fromJson(_object(data, 'album')),
    );
    return envelope.data;
  }

  @override
  Future<void> deleteAlbum(int id) async {
    await _api.delete<void>(ApiEndpoints.adminAlbum(id), decode: (_) {});
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
