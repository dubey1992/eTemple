import 'media_item.dart';

/// What the public gallery is asking for.
///
/// Named `GalleryQuery` rather than `MediaQuery` so it can never be confused
/// with Flutter's own widget of that name in a presentation file.
class GalleryQuery {
  const GalleryQuery({this.type, this.album, this.page = 1, this.perPage = 24});

  /// Null means "photographs and videos together".
  final String? type;

  /// An album slug, so `/gallery?album=janmashtami-2026` is shareable.
  final String? album;

  final int page;
  final int perPage;

  GalleryQuery atPage(int page) =>
      GalleryQuery(type: type, album: album, page: page, perPage: perPage);

  Map<String, Object?> toQueryParameters(String language) => {
    'lang': language,
    'type': ?type,
    'album': ?album,
    'page': page,
    'per_page': perPage,
  };

  // Value equality because this is a provider family key: without it every
  // rebuild would ask for a new provider and refetch the same page.
  @override
  bool operator ==(Object other) =>
      other is GalleryQuery &&
      other.type == type &&
      other.album == album &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode => Object.hash(type, album, page, perPage);
}

/// Contract for reading the gallery and running the library.
///
/// Implementations live in `data/` and are the only place that knows about HTTP.
abstract interface class MediaRepository {
  /// One page of published items, in the visitor's language.
  Future<MediaPage> media(GalleryQuery query, {required String language});

  /// One published item. A draft is indistinguishable from one that is absent.
  Future<MediaItem> item(int id, {required String language});

  /// Published albums with their covers.
  Future<List<AlbumSummary>> albums({required String language});

  /// The whole library including drafts. Requires `content.view`.
  Future<List<AdminMedia>> adminMedia({
    String? status,
    String? type,
    int? albumId,
  });

  /// One item loaded raw for editing.
  Future<AdminMedia> adminMediaItem(int id);

  /// Uploads a photograph. Requires `media.manage`.
  ///
  /// The bytes are validated, stripped of metadata and re-encoded on the
  /// server; nothing here may assume the file it sent is the file that is
  /// stored.
  Future<AdminMedia> uploadPhoto(PhotoUpload upload);

  /// Links a video. Requires `media.manage`. Nothing is uploaded.
  Future<AdminMedia> createVideo(VideoDraft draft);

  /// Edits titles, captions, album, order and status.
  Future<AdminMedia> saveMedia(int id, MediaDraft draft);

  /// Removes an item. Refused by the server while anything still points at it.
  Future<void> deleteMedia(int id);

  /// What points at an item, asked before offering to delete it.
  Future<MediaReferences> references(int id);

  /// Applies a new arrangement. The whole ordering is sent, not one move.
  Future<void> reorder(List<int> ids);

  Future<List<AdminAlbum>> adminAlbums();

  Future<AdminAlbum> createAlbum(AlbumDraft draft);

  Future<AdminAlbum> saveAlbum(int id, AlbumDraft draft);

  /// Deletes an album. Its photographs survive, unfiled.
  Future<void> deleteAlbum(int id);
}
