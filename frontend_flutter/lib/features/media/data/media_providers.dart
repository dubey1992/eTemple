import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/media_item.dart';
import '../domain/media_repository.dart';
import 'media_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final mediaRepositoryProvider = Provider<MediaRepository>(
  (ref) => MediaRepositoryImpl(ref.watch(apiClientProvider)),
);

/// What the gallery page is currently showing, and how much of it.
///
/// Held in a provider rather than in the screen's state so the choice survives
/// a rebuild — switching language must not throw the visitor back to
/// photographs while they are looking at the video darshan list, nor collapse
/// the pages they have already asked for.
class GalleryView {
  const GalleryView({this.type = MediaTypes.photo, this.album, this.pages = 1});

  final String type;

  /// An album slug, or null for everything.
  final String? album;

  /// How many pages the visitor has asked for so far.
  final int pages;

  GalleryView withType(String type) => GalleryView(type: type, album: album);

  GalleryView withAlbum(String? album) => GalleryView(type: type, album: album);

  GalleryView get more =>
      GalleryView(type: type, album: album, pages: pages + 1);

  GalleryQuery queryFor(int page) =>
      GalleryQuery(type: type, album: album, page: page);

  @override
  bool operator ==(Object other) =>
      other is GalleryView &&
      other.type == type &&
      other.album == album &&
      other.pages == pages;

  @override
  int get hashCode => Object.hash(type, album, pages);
}

/// Changing the filter resets the page count on purpose: the pages already
/// loaded belong to the old filter, and keeping them would show photographs
/// under a video tab.
class GalleryViewController extends Notifier<GalleryView> {
  @override
  GalleryView build() => const GalleryView();

  void selectType(String type) => state = state.withType(type);

  void selectAlbum(String? album) => state = state.withAlbum(album);

  void showMore() => state = state.more;
}

final galleryViewProvider =
    NotifierProvider<GalleryViewController, GalleryView>(
      GalleryViewController.new,
    );

/// One page of the gallery, in the visitor's language.
///
/// Kept as a per-page family rather than an accumulating list so that each page
/// is cached, "show more" costs exactly one request, and a failed page can be
/// retried without discarding the ones already read.
final galleryProvider = FutureProvider.family<MediaPage, GalleryQuery>((
  ref,
  query,
) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(mediaRepositoryProvider).media(query, language: language);
});

/// The handful of photographs the home page shows.
///
/// A separate, small request rather than a slice of the gallery page: the home
/// page must not pull twenty-four rows to render five.
final homeGalleryProvider = FutureProvider<MediaPage>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref
      .watch(mediaRepositoryProvider)
      .media(
        const GalleryQuery(type: MediaTypes.photo, perPage: 5),
        language: language,
      );
});

/// Published albums, for the gallery's album filter.
final albumsProvider = FutureProvider<List<AlbumSummary>>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(mediaRepositoryProvider).albums(language: language);
});

/// The library list's filters, as one value-equal family key.
class AdminMediaQuery {
  const AdminMediaQuery({this.status, this.type});

  final String? status;
  final String? type;

  @override
  bool operator ==(Object other) =>
      other is AdminMediaQuery && other.status == status && other.type == type;

  @override
  int get hashCode => Object.hash(status, type);
}

/// The whole library including drafts. Admin-only; the server enforces that.
final adminMediaProvider =
    FutureProvider.family<List<AdminMedia>, AdminMediaQuery>(
      (ref, query) => ref
          .watch(mediaRepositoryProvider)
          .adminMedia(status: query.status, type: query.type),
    );

/// One item loaded raw for editing.
final adminMediaItemProvider = FutureProvider.family<AdminMedia, int>(
  (ref, id) => ref.watch(mediaRepositoryProvider).adminMediaItem(id),
);

/// What still points at an item, so the editor can say so before offering a
/// delete button that would fail.
final mediaReferencesProvider = FutureProvider.family<MediaReferences, int>(
  (ref, id) => ref.watch(mediaRepositoryProvider).references(id),
);

/// Albums as the editor sees them, counts including drafts.
final adminAlbumsProvider = FutureProvider<List<AdminAlbum>>(
  (ref) => ref.watch(mediaRepositoryProvider).adminAlbums(),
);

/// Published photographs offered by the picker used for the temple logo, a
/// member's portrait and an event poster.
final pickerPhotosProvider = FutureProvider<List<AdminMedia>>(
  (ref) => ref
      .watch(mediaRepositoryProvider)
      .adminMedia(status: MediaStatuses.published, type: MediaTypes.photo),
);
