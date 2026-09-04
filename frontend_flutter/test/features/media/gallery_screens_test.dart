import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/widgets/state_views.dart';
import 'package:rkt_web/features/media/domain/media_item.dart';
import 'package:rkt_web/features/media/presentation/gallery_screen.dart';
import 'package:rkt_web/features/media/presentation/widgets/gallery_mosaic.dart';
import 'package:rkt_web/features/media/presentation/widgets/media_lightbox.dart';
import 'package:rkt_web/features/media/presentation/widgets/media_tile.dart';

import '../../support/fake_media_repository.dart';
import '../../support/pump_app.dart';

/// Nothing here lets an `Image.network` reach the network: the test binding
/// answers every image request with a transparent pixel, so the tests are about
/// layout and behaviour rather than about downloads.
///
/// The screen is pumped inside a `Scaffold` exactly as the public shell
/// provides one in the application; chips and ink effects need that Material
/// ancestor.
Future<void> pumpGallery(
  WidgetTester tester,
  Widget screen, {
  FakeMediaRepository? media,
  Size surfaceSize = const Size(1280, 2600),
}) async {
  await pumpScreen(
    tester,
    Scaffold(body: screen),
    media: media,
    surfaceSize: surfaceSize,
  );
  await tester.pumpAndSettle();
}

void main() {
  const desktop = Size(1280, 900);
  const mobile = Size(420, 900);

  group('GalleryScreen', () {
    testWidgets('shows the published photographs', (tester) async {
      final media = FakeMediaRepository(
        photos: [
          testMediaItem(id: 1, title: 'मंदिर प्रांगण'),
          testMediaItem(id: 2, title: 'दीपावली'),
        ],
      );

      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: media,
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('media-tile-1')), findsOneWidget);
      expect(find.byKey(const Key('media-tile-2')), findsOneWidget);
    });

    testWidgets('an empty gallery shows the approved placeholder block', (
      tester,
    ) async {
      // The prototype's own caption says the photographs "will appear here",
      // so its five tiles *are* the empty state.
      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: FakeMediaRepository(),
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('gallery-placeholder')), findsOneWidget);
      expect(find.text('🛕'), findsOneWidget);
    });

    testWidgets('switching to video darshan asks for videos', (tester) async {
      final media = FakeMediaRepository(
        photos: [testMediaItem(id: 1)],
        videos: [testVideoItem(id: 50)],
      );

      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: media,
        surfaceSize: desktop,
      );

      // The icon, not the translated label: a CI runner with no Devanagari
      // font renders that label at near-zero width and the tap misses.
      await tester.tap(find.byIcon(Icons.smart_display_outlined).first);
      await tester.pumpAndSettle();

      expect(media.lastQuery?.type, MediaTypes.video);
      expect(find.byKey(const Key('media-tile-50')), findsOneWidget);
    });

    testWidgets('no videos is a plain empty state, not the photo placeholder', (
      tester,
    ) async {
      final media = FakeMediaRepository(photos: [testMediaItem(id: 1)]);

      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: media,
        surfaceSize: desktop,
      );

      await tester.tap(find.byIcon(Icons.smart_display_outlined).first);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gallery-no-videos')), findsOneWidget);
      expect(find.byKey(const Key('gallery-placeholder')), findsNothing);
    });

    testWidgets('show more appends the next page rather than replacing it', (
      tester,
    ) async {
      final media = FakeMediaRepository(
        photos: [
          for (var i = 1; i <= 30; i++) testMediaItem(id: i, title: 'चित्र $i'),
        ],
      );

      // A tall surface so the whole first page and the button below it are
      // laid out; this is about paging, not about scrolling.
      await pumpGallery(tester, const GalleryScreen(), media: media);

      expect(media.queries.map((q) => q.page), [1]);

      await tester.tap(find.byKey(const Key('gallery-load-more')));
      await tester.pumpAndSettle();

      // Page two is asked for and page one is not asked for again: each page
      // is its own cached request, so showing more never re-reads or discards
      // what was already loaded.
      expect(media.queries.map((q) => q.page), [1, 2]);
    });

    testWidgets('the load-more button disappears on the last page', (
      tester,
    ) async {
      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: FakeMediaRepository(photos: [testMediaItem(id: 1)]),
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('gallery-load-more')), findsNothing);
    });

    testWidgets('a failed gallery says so and offers a retry', (tester) async {
      final media = FakeMediaRepository(
        listError: const AppException(code: ErrorCode.network),
      );

      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: media,
        surfaceSize: desktop,
      );

      expect(find.byType(ErrorView), findsOneWidget);
      final attempts = media.listCalls;

      // The retry is the icon, not the translated label: a runner with no
      // Devanagari font renders that label at near-zero width and the tap
      // lands outside the widget.
      media.listError = null;
      media.photos = [testMediaItem(id: 1)];
      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(media.listCalls, greaterThan(attempts));
      expect(find.byKey(const Key('media-tile-1')), findsOneWidget);
    });

    testWidgets('a shared album link selects that album', (tester) async {
      final media = FakeMediaRepository(
        photos: [testMediaItem(id: 1)],
        albumList: [testAlbum(slug: 'janmashtami')],
      );

      await pumpGallery(
        tester,
        const GalleryScreen(album: 'janmashtami'),
        media: media,
        surfaceSize: desktop,
      );

      expect(media.lastQuery?.album, 'janmashtami');
    });

    testWidgets('the album chips appear only once albums exist', (
      tester,
    ) async {
      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: FakeMediaRepository(photos: [testMediaItem(id: 1)]),
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('album-chip-all')), findsNothing);
    });

    testWidgets('lays out without overflow at every breakpoint', (
      tester,
    ) async {
      for (final size in const [mobile, Size(800, 900), desktop]) {
        await pumpGallery(
          tester,
          const GalleryScreen(),
          media: FakeMediaRepository(
            photos: [for (var i = 1; i <= 6; i++) testMediaItem(id: i)],
          ),
          surfaceSize: size,
        );

        expect(tester.takeException(), isNull, reason: 'overflow at $size');
      }
    });
  });

  group('GalleryMosaic', () {
    testWidgets('places at most five tiles, feature first', (tester) async {
      await pumpGallery(
        tester,
        GalleryMosaic(
          items: [for (var i = 1; i <= 8; i++) testMediaItem(id: i)],
        ),
        surfaceSize: desktop,
      );

      // The prototype's block has five cells; a sixth photograph belongs on
      // the gallery page, not squeezed into the home page.
      expect(find.byType(MediaTile), findsNWidgets(5));
      expect(find.byKey(const Key('media-tile-6')), findsNothing);
    });

    testWidgets('an empty mosaic is the prototype placeholder', (tester) async {
      await pumpGallery(
        tester,
        const GalleryMosaic(items: []),
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('gallery-placeholder')), findsOneWidget);
      for (final glyph in GalleryPlaceholderMosaic.glyphs) {
        expect(find.text(glyph), findsOneWidget);
      }
    });

    testWidgets('narrows to a single column on a phone', (tester) async {
      await pumpGallery(
        tester,
        SingleChildScrollView(
          // As on the home page: five stacked tiles are taller than a phone
          // screen, and the page they live on scrolls.
          child: GalleryMosaic(
            items: [for (var i = 1; i <= 5; i++) testMediaItem(id: i)],
          ),
        ),
        surfaceSize: mobile,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MediaTile), findsNWidgets(5));
    });
  });

  group('MediaLightbox', () {
    testWidgets('a photograph opens with its title and caption', (
      tester,
    ) async {
      await pumpGallery(
        tester,
        MediaLightbox(
          item: testMediaItem(
            id: 1,
            title: 'मंदिर प्रांगण',
            caption: 'जन्माष्टमी 2026',
          ),
        ),
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('lightbox-title')), findsOneWidget);
      expect(find.byKey(const Key('lightbox-caption')), findsOneWidget);
      expect(find.byKey(const Key('lightbox-watch')), findsNothing);
    });

    testWidgets('a video offers the provider link instead of an embed', (
      tester,
    ) async {
      // Playing inline would put a third-party iframe on the temple's own
      // origin; the visitor is sent to the provider instead.
      await pumpGallery(
        tester,
        MediaLightbox(item: testVideoItem()),
        surfaceSize: desktop,
      );

      expect(find.byKey(const Key('lightbox-watch')), findsOneWidget);
    });

    testWidgets('tapping a tile opens the lightbox', (tester) async {
      await pumpGallery(
        tester,
        const GalleryScreen(),
        media: FakeMediaRepository(photos: [testMediaItem(id: 1)]),
        surfaceSize: desktop,
      );

      await tester.tap(find.byKey(const Key('media-tile-1')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-lightbox')), findsOneWidget);

      await tester.tap(find.byKey(const Key('lightbox-close')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('media-lightbox')), findsNothing);
    });
  });
}
