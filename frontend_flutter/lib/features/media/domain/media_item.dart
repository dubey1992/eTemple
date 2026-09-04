import 'dart:typed_data';

import '../../../core/api/api_envelope.dart';
import '../../content/domain/localized_value.dart';

/// What a media row is, mirroring `App\Support\MediaType`.
class MediaTypes {
  const MediaTypes._();

  static const String photo = 'photo';
  static const String video = 'video';

  static const List<String> all = [photo, video];

  static bool exists(String value) => all.contains(value);
}

/// Publication state, mirroring `App\Models\Media`.
class MediaStatuses {
  const MediaStatuses._();

  static const String draft = 'draft';
  static const String published = 'published';

  static const List<String> all = [draft, published];
}

/// One gallery item as the public API sends it.
///
/// Three image sizes arrive on every item so the caller can pick per use: a
/// grid tile takes [thumbUrl] and never the full photograph, and the lightbox
/// takes [mediumUrl] or [largeUrl] by form factor. That choice is what keeps a
/// gallery of twenty tiles from costing hundreds of megabytes of decoded
/// bitmap on a phone.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.mediaType,
    required this.title,
    required this.caption,
    this.thumbUrl,
    this.mediumUrl,
    this.largeUrl,
    this.fileUrl,
    this.externalUrl,
    this.embedUrl,
    this.provider,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.albumId,
    this.sortOrder = 0,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return MediaItem(
      id: asInt(json['id']) ?? 0,
      mediaType: read('media_type') ?? MediaTypes.photo,
      title: LocalizedValue.fromJson(json['title']),
      caption: LocalizedValue.fromJson(json['caption']),
      thumbUrl: read('thumb_url'),
      mediumUrl: read('medium_url'),
      largeUrl: read('large_url'),
      fileUrl: read('file_url'),
      externalUrl: read('external_url'),
      embedUrl: read('embed_url'),
      provider: read('provider'),
      thumbnailUrl: read('thumbnail_url'),
      width: asInt(json['width']),
      height: asInt(json['height']),
      albumId: asInt(json['album_id']),
      sortOrder: asInt(json['sort_order']) ?? 0,
    );
  }

  final int id;
  final String mediaType;
  final LocalizedValue title;
  final LocalizedValue caption;
  final String? thumbUrl;
  final String? mediumUrl;
  final String? largeUrl;
  final String? fileUrl;
  final String? externalUrl;
  final String? embedUrl;
  final String? provider;
  final String? thumbnailUrl;
  final int? width;
  final int? height;
  final int? albumId;
  final int sortOrder;

  bool get isVideo => mediaType == MediaTypes.video;

  bool get isPhoto => mediaType == MediaTypes.photo;

  /// The smallest image that will do for a grid tile.
  ///
  /// A video has no stored file, so its poster is the provider's thumbnail.
  String? get previewUrl =>
      isVideo ? thumbnailUrl : (thumbUrl ?? mediumUrl ?? largeUrl);

  /// The image to open full-screen. Videos are played, not opened.
  String? get fullUrl => largeUrl ?? mediumUrl ?? thumbUrl;

  /// Shape of the photograph, for a grid that respects it. Null when the
  /// server did not record dimensions, which is the case for every video.
  double? get aspectRatio {
    final w = width;
    final h = height;
    if (w == null || h == null || w <= 0 || h <= 0) return null;
    return w / h;
  }

  static int? asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// One page of the gallery, with the position it occupies.
///
/// The gallery is paginated because an unbounded response is a
/// denial-of-service against the API, and every row here carries three URLs.
class MediaPage {
  const MediaPage({required this.items, this.meta});

  static const MediaPage empty = MediaPage(items: []);

  final List<MediaItem> items;
  final PageMeta? meta;

  bool get hasMore => meta?.hasMore ?? false;

  int get total => meta?.total ?? items.length;

  int get currentPage => meta?.currentPage ?? 1;

  /// This page followed by [next], for an append-as-you-scroll list.
  MediaPage followedBy(MediaPage next) =>
      MediaPage(items: [...items, ...next.items], meta: next.meta);
}

/// A named group of photographs, as a visitor sees it.
class AlbumSummary {
  const AlbumSummary({
    required this.id,
    required this.slug,
    required this.title,
    required this.description,
    required this.mediaCount,
    this.coverUrl,
  });

  factory AlbumSummary.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return AlbumSummary(
      id: MediaItem.asInt(json['id']) ?? 0,
      slug: read('slug') ?? '',
      title: LocalizedValue.fromJson(json['title']),
      description: LocalizedValue.fromJson(json['description']),
      mediaCount: MediaItem.asInt(json['media_count']) ?? 0,
      coverUrl: read('cover_url'),
    );
  }

  final int id;
  final String slug;
  final LocalizedValue title;
  final LocalizedValue description;
  final int mediaCount;
  final String? coverUrl;
}

/// One item as the library sees it: both languages raw, plus the technical
/// detail an editor needs to judge a file.
class AdminMedia {
  const AdminMedia({
    required this.id,
    required this.mediaType,
    required this.titleHi,
    required this.status,
    this.titleEn,
    this.captionHi,
    this.captionEn,
    this.thumbUrl,
    this.mediumUrl,
    this.largeUrl,
    this.fileUrl,
    this.externalUrl,
    this.embedUrl,
    this.thumbnailUrl,
    this.mimeType,
    this.byteSize,
    this.width,
    this.height,
    this.originalName,
    this.albumId,
    this.sortOrder = 0,
  });

  factory AdminMedia.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return AdminMedia(
      id: MediaItem.asInt(json['id']) ?? 0,
      mediaType: read('media_type') ?? MediaTypes.photo,
      titleHi: read('title_hi') ?? '',
      titleEn: read('title_en'),
      captionHi: read('caption_hi'),
      captionEn: read('caption_en'),
      thumbUrl: read('thumb_url'),
      mediumUrl: read('medium_url'),
      largeUrl: read('large_url'),
      fileUrl: read('file_url'),
      externalUrl: read('external_url'),
      embedUrl: read('embed_url'),
      thumbnailUrl: read('thumbnail_url'),
      mimeType: read('mime_type'),
      byteSize: MediaItem.asInt(json['byte_size']),
      width: MediaItem.asInt(json['width']),
      height: MediaItem.asInt(json['height']),
      originalName: read('original_name'),
      albumId: MediaItem.asInt(json['album_id']),
      sortOrder: MediaItem.asInt(json['sort_order']) ?? 0,
      status: read('status') ?? MediaStatuses.draft,
    );
  }

  final int id;
  final String mediaType;
  final String titleHi;
  final String? titleEn;
  final String? captionHi;
  final String? captionEn;
  final String? thumbUrl;
  final String? mediumUrl;
  final String? largeUrl;
  final String? fileUrl;
  final String? externalUrl;
  final String? embedUrl;
  final String? thumbnailUrl;
  final String? mimeType;
  final int? byteSize;
  final int? width;
  final int? height;
  final String? originalName;
  final int? albumId;
  final int sortOrder;
  final String status;

  bool get isPublished => status == MediaStatuses.published;

  bool get isVideo => mediaType == MediaTypes.video;

  String? get previewUrl => isVideo ? thumbnailUrl : (thumbUrl ?? mediumUrl);

  /// The URL another record would store to point at this item — the same value
  /// the server's deletion guard looks for.
  String? get referenceUrl => isVideo ? externalUrl : fileUrl;
}

/// One album as the editor sees it.
class AdminAlbum {
  const AdminAlbum({
    required this.id,
    required this.slug,
    required this.titleHi,
    required this.status,
    required this.mediaCount,
    this.titleEn,
    this.descriptionHi,
    this.descriptionEn,
    this.coverMediaId,
    this.coverUrl,
    this.sortOrder = 0,
  });

  factory AdminAlbum.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return AdminAlbum(
      id: MediaItem.asInt(json['id']) ?? 0,
      slug: read('slug') ?? '',
      titleHi: read('title_hi') ?? '',
      titleEn: read('title_en'),
      descriptionHi: read('description_hi'),
      descriptionEn: read('description_en'),
      coverMediaId: MediaItem.asInt(json['cover_media_id']),
      coverUrl: read('cover_url'),
      mediaCount: MediaItem.asInt(json['media_count']) ?? 0,
      sortOrder: MediaItem.asInt(json['sort_order']) ?? 0,
      status: read('status') ?? MediaStatuses.draft,
    );
  }

  final int id;
  final String slug;
  final String titleHi;
  final String? titleEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final int? coverMediaId;
  final String? coverUrl;
  final int mediaCount;
  final int sortOrder;
  final String status;

  bool get isPublished => status == MediaStatuses.published;
}

/// A photograph chosen in the browser, on its way to the server.
///
/// Bytes rather than a path: on the web there is no filesystem path to send,
/// and the picked file is only ever read into memory.
class PhotoUpload {
  const PhotoUpload({
    required this.bytes,
    required this.fileName,
    required this.titleHi,
    required this.status,
    this.titleEn,
    this.captionHi,
    this.captionEn,
    this.albumId,
    this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String titleHi;
  final String? titleEn;
  final String? captionHi;
  final String? captionEn;
  final int? albumId;
  final String status;

  /// What the browser said the file is. Sent for completeness and ignored by
  /// the server, which detects the type from the bytes itself.
  final String? contentType;

  int get byteSize => bytes.length;
}

/// A video link on its way to the server.
class VideoDraft {
  const VideoDraft({
    required this.externalUrl,
    required this.titleHi,
    required this.status,
    this.titleEn,
    this.captionHi,
    this.captionEn,
    this.albumId,
  });

  final String externalUrl;
  final String titleHi;
  final String? titleEn;
  final String? captionHi;
  final String? captionEn;
  final int? albumId;
  final String status;

  Map<String, Object?> toJson() => {
    'external_url': externalUrl.trim(),
    'title_hi': titleHi.trim(),
    'title_en': nullIfBlank(titleEn),
    'caption_hi': nullIfBlank(captionHi),
    'caption_en': nullIfBlank(captionEn),
    'album_id': albumId,
    'status': status,
  };

  /// Blank optional fields are sent as null so the server stores "absent"
  /// rather than an empty string, which is what the fallback rule keys on.
  static String? nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// An edit to an existing item.
///
/// There is no file here on purpose: the server refuses to swap the bytes under
/// a URL, because every reference on the site is by URL and one swap would
/// silently change a page, an event poster and a portrait at once.
class MediaDraft {
  const MediaDraft({
    required this.titleHi,
    required this.status,
    this.titleEn,
    this.captionHi,
    this.captionEn,
    this.externalUrl,
    this.albumId,
    this.sortOrder,
  });

  final String titleHi;
  final String? titleEn;
  final String? captionHi;
  final String? captionEn;
  final String? externalUrl;
  final int? albumId;
  final int? sortOrder;
  final String status;

  Map<String, Object?> toJson() => {
    'title_hi': titleHi.trim(),
    'title_en': VideoDraft.nullIfBlank(titleEn),
    'caption_hi': VideoDraft.nullIfBlank(captionHi),
    'caption_en': VideoDraft.nullIfBlank(captionEn),
    'external_url': VideoDraft.nullIfBlank(externalUrl),
    'album_id': albumId,
    'sort_order': ?sortOrder,
    'status': status,
  };
}

/// An album being created or edited.
class AlbumDraft {
  const AlbumDraft({
    required this.titleHi,
    required this.status,
    this.titleEn,
    this.descriptionHi,
    this.descriptionEn,
    this.slug,
    this.coverMediaId,
    this.sortOrder,
  });

  final String titleHi;
  final String? titleEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final String? slug;
  final int? coverMediaId;
  final int? sortOrder;
  final String status;

  Map<String, Object?> toJson() => {
    'title_hi': titleHi.trim(),
    'title_en': VideoDraft.nullIfBlank(titleEn),
    'description_hi': VideoDraft.nullIfBlank(descriptionHi),
    'description_en': VideoDraft.nullIfBlank(descriptionEn),
    'slug': VideoDraft.nullIfBlank(slug),
    'cover_media_id': coverMediaId,
    'sort_order': ?sortOrder,
    'status': status,
  };
}

/// What still points at a media item, and therefore whether it can be deleted.
class MediaReferences {
  const MediaReferences({required this.canDelete, required this.references});

  factory MediaReferences.fromJson(Map<String, dynamic> json) {
    final raw = json['references'];

    return MediaReferences(
      canDelete: json['can_delete'] == true,
      references: raw is List
          ? raw
                .map(ApiEnvelopeParser.asMap)
                .whereType<Map<String, dynamic>>()
                .map(MediaReference.fromJson)
                .toList(growable: false)
          : const [],
    );
  }

  static const MediaReferences unknown = MediaReferences(
    canDelete: true,
    references: [],
  );

  final bool canDelete;
  final List<MediaReference> references;
}

/// One record that points at a media item.
class MediaReference {
  const MediaReference({required this.type, required this.label, this.id});

  factory MediaReference.fromJson(Map<String, dynamic> json) => MediaReference(
    type: json['type'] as String? ?? 'unknown',
    label: json['label'] as String? ?? '',
    id: MediaItem.asInt(json['id']),
  );

  /// `event_poster`, `committee_member`, `temple_logo`, `album_cover`, `page`.
  final String type;
  final String label;
  final int? id;
}
