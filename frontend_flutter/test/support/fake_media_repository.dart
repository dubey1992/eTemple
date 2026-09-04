import 'dart:typed_data';

import 'package:rkt_web/core/api/api_envelope.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/media/domain/media_item.dart';
import 'package:rkt_web/features/media/domain/media_repository.dart';

/// Scriptable stand-in for the HTTP media repository.
///
/// Pagination is real here — the fake slices its own list the way the server
/// would — because "show more" is the one gallery behaviour that only shows up
/// across a page boundary.
class FakeMediaRepository implements MediaRepository {
  FakeMediaRepository({
    List<MediaItem>? photos,
    List<MediaItem>? videos,
    this.albumList = const [],
    this.adminList = const [],
    this.adminAlbumList = const [],
    this.listError,
    this.adminError,
    this.saveError,
    this.deleteError,
    this.referenceAnswer = MediaReferences.unknown,
    this.delay = Duration.zero,
  }) : photos = photos ?? const [],
       videos = videos ?? const [];

  List<MediaItem> photos;
  List<MediaItem> videos;
  List<AlbumSummary> albumList;
  List<AdminMedia> adminList;
  List<AdminAlbum> adminAlbumList;

  AppException? listError;
  AppException? adminError;
  AppException? saveError;
  AppException? deleteError;
  MediaReferences referenceAnswer;
  Duration delay;

  int listCalls = 0;
  int uploadCalls = 0;
  int createVideoCalls = 0;
  int saveCalls = 0;
  int deleteCalls = 0;
  int referenceCalls = 0;

  GalleryQuery? lastQuery;

  /// Every query the screen has issued, in order, so a test can assert what
  /// was asked for without depending on which provider settled last.
  final List<GalleryQuery> queries = [];
  String? lastLanguage;
  PhotoUpload? lastUpload;
  VideoDraft? lastVideo;
  MediaDraft? lastDraft;
  AlbumDraft? lastAlbumDraft;
  List<int>? lastOrder;
  int? lastDeletedId;

  Future<void> _pause() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<MediaPage> media(
    GalleryQuery query, {
    required String language,
  }) async {
    listCalls++;
    lastQuery = query;
    queries.add(query);
    lastLanguage = language;
    await _pause();
    if (listError != null) throw listError!;

    final all = switch (query.type) {
      MediaTypes.video => videos,
      MediaTypes.photo => photos,
      _ => [...photos, ...videos],
    };

    final from = (query.page - 1) * query.perPage;
    final to = (from + query.perPage).clamp(0, all.length);
    final items = from >= all.length ? <MediaItem>[] : all.sublist(from, to);
    final lastPage = all.isEmpty ? 1 : ((all.length - 1) ~/ query.perPage) + 1;

    return MediaPage(
      items: items,
      meta: PageMeta(
        currentPage: query.page,
        perPage: query.perPage,
        total: all.length,
        lastPage: lastPage,
        hasMore: query.page < lastPage,
      ),
    );
  }

  @override
  Future<MediaItem> item(int id, {required String language}) async {
    lastLanguage = language;
    await _pause();
    if (listError != null) throw listError!;

    final match = [
      ...photos,
      ...videos,
    ].where((item) => item.id == id).toList();
    if (match.isEmpty) throw const AppException(code: ErrorCode.notFound);
    return match.first;
  }

  @override
  Future<List<AlbumSummary>> albums({required String language}) async {
    lastLanguage = language;
    await _pause();
    if (listError != null) throw listError!;
    return albumList;
  }

  @override
  Future<List<AdminMedia>> adminMedia({
    String? status,
    String? type,
    int? albumId,
  }) async {
    await _pause();
    if (adminError != null) throw adminError!;

    return adminList
        .where((item) => status == null || item.status == status)
        .where((item) => type == null || item.mediaType == type)
        .toList();
  }

  @override
  Future<AdminMedia> adminMediaItem(int id) async {
    await _pause();
    if (adminError != null) throw adminError!;

    return adminList.firstWhere(
      (item) => item.id == id,
      orElse: () => throw const AppException(code: ErrorCode.notFound),
    );
  }

  @override
  Future<AdminMedia> uploadPhoto(PhotoUpload upload) async {
    uploadCalls++;
    lastUpload = upload;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminMedia(id: 99, titleHi: upload.titleHi);
  }

  @override
  Future<AdminMedia> createVideo(VideoDraft draft) async {
    createVideoCalls++;
    lastVideo = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminMedia(id: 98, titleHi: draft.titleHi);
  }

  @override
  Future<AdminMedia> saveMedia(int id, MediaDraft draft) async {
    saveCalls++;
    lastDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminMedia(id: id, titleHi: draft.titleHi);
  }

  @override
  Future<void> deleteMedia(int id) async {
    deleteCalls++;
    lastDeletedId = id;
    await _pause();
    if (deleteError != null) throw deleteError!;
  }

  @override
  Future<MediaReferences> references(int id) async {
    referenceCalls++;
    await _pause();
    if (adminError != null) throw adminError!;
    return referenceAnswer;
  }

  @override
  Future<void> reorder(List<int> ids) async {
    lastOrder = ids;
    await _pause();
    if (saveError != null) throw saveError!;
  }

  @override
  Future<List<AdminAlbum>> adminAlbums() async {
    await _pause();
    if (adminError != null) throw adminError!;
    return adminAlbumList;
  }

  @override
  Future<AdminAlbum> createAlbum(AlbumDraft draft) async {
    lastAlbumDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminAlbum(id: 97, titleHi: draft.titleHi);
  }

  @override
  Future<AdminAlbum> saveAlbum(int id, AlbumDraft draft) async {
    lastAlbumDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testAdminAlbum(id: id, titleHi: draft.titleHi);
  }

  @override
  Future<void> deleteAlbum(int id) async {
    deleteCalls++;
    lastDeletedId = id;
    await _pause();
    if (deleteError != null) throw deleteError!;
  }
}

LocalizedValue _hi(String? value, {bool fallbackUsed = false}) =>
    LocalizedValue(value: value, language: 'hi', fallbackUsed: fallbackUsed);

/// One published gallery item, as the API would send it.
MediaItem testMediaItem({
  int id = 1,
  String type = MediaTypes.photo,
  String title = 'मंदिर प्रांगण',
  String? caption,
  bool fallbackUsed = false,
  String? thumbUrl = 'https://cdn.example/temple-sm.jpg',
  String? mediumUrl = 'https://cdn.example/temple-md.jpg',
  String? largeUrl = 'https://cdn.example/temple-lg.jpg',
  String? externalUrl,
  String? embedUrl,
  String? thumbnailUrl,
  int? width = 1920,
  int? height = 1280,
}) {
  return MediaItem(
    id: id,
    mediaType: type,
    title: _hi(title, fallbackUsed: fallbackUsed),
    caption: _hi(caption),
    thumbUrl: thumbUrl,
    mediumUrl: mediumUrl,
    largeUrl: largeUrl,
    fileUrl: largeUrl,
    externalUrl: externalUrl,
    embedUrl: embedUrl,
    thumbnailUrl: thumbnailUrl,
    width: width,
    height: height,
  );
}

/// One linked video, which has no stored file at all.
MediaItem testVideoItem({
  int id = 50,
  String title = 'संध्या आरती दर्शन',
  String reference = 'abcdefghijk',
}) {
  return MediaItem(
    id: id,
    mediaType: MediaTypes.video,
    title: _hi(title),
    caption: LocalizedValue.empty,
    externalUrl: 'https://www.youtube.com/watch?v=$reference',
    embedUrl: 'https://www.youtube-nocookie.com/embed/$reference',
    thumbnailUrl: 'https://i.ytimg.com/vi/$reference/hqdefault.jpg',
  );
}

/// One item as the library sees it.
AdminMedia testAdminMedia({
  int id = 1,
  String titleHi = 'मंदिर प्रांगण',
  String type = MediaTypes.photo,
  String status = MediaStatuses.draft,
  int? albumId,
  int sortOrder = 0,
  String? externalUrl,
}) {
  return AdminMedia(
    id: id,
    mediaType: type,
    titleHi: titleHi,
    status: status,
    albumId: albumId,
    sortOrder: sortOrder,
    thumbUrl: type == MediaTypes.photo
        ? 'https://cdn.example/temple-sm.jpg'
        : null,
    largeUrl: type == MediaTypes.photo
        ? 'https://cdn.example/temple-lg.jpg'
        : null,
    fileUrl: type == MediaTypes.photo
        ? 'https://cdn.example/temple-lg.jpg'
        : null,
    externalUrl: externalUrl,
    mimeType: type == MediaTypes.photo ? 'image/jpeg' : null,
    byteSize: type == MediaTypes.photo ? 240000 : null,
    width: type == MediaTypes.photo ? 1920 : null,
    height: type == MediaTypes.photo ? 1280 : null,
    originalName: type == MediaTypes.photo ? 'temple.jpg' : null,
  );
}

AdminAlbum testAdminAlbum({
  int id = 1,
  String titleHi = 'जन्माष्टमी',
  String slug = 'janmashtami',
  String status = MediaStatuses.draft,
  int mediaCount = 0,
}) {
  return AdminAlbum(
    id: id,
    slug: slug,
    titleHi: titleHi,
    status: status,
    mediaCount: mediaCount,
  );
}

AlbumSummary testAlbum({
  int id = 1,
  String slug = 'janmashtami',
  String title = 'जन्माष्टमी',
  int mediaCount = 2,
}) {
  return AlbumSummary(
    id: id,
    slug: slug,
    title: _hi(title),
    description: LocalizedValue.empty,
    mediaCount: mediaCount,
  );
}

/// A tiny byte payload, for exercising the upload path without a real image.
///
/// The bytes are never decoded here: what the server does with them is tested
/// against real images in `ImageProcessingTest`, and duplicating that in Dart
/// would be a second implementation to disagree with.
Uint8List testBytes([int length = 32]) =>
    Uint8List.fromList(List<int>.generate(length, (i) => i % 256));
