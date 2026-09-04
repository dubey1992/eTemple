import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/features/media/domain/media_item.dart';
import 'package:rkt_web/features/media/domain/media_repository.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';
import 'package:rkt_web/l10n/app_localizations.dart';
import 'package:rkt_web/features/media/presentation/media_formatting.dart';

import '../../support/fake_media_repository.dart';

void main() {
  group('MediaItem', () {
    test('parses the three sizes the API sends', () {
      final item = MediaItem.fromJson({
        'id': 7,
        'media_type': MediaTypes.photo,
        'title': {'value': 'मंदिर', 'language': 'hi', 'fallback_used': false},
        'caption': {'value': null, 'language': 'hi', 'fallback_used': false},
        'thumb_url': 'https://cdn.example/a-sm.jpg',
        'medium_url': 'https://cdn.example/a-md.jpg',
        'large_url': 'https://cdn.example/a-lg.jpg',
        'width': 1920,
        'height': 1280,
      });

      expect(item.id, 7);
      expect(item.isPhoto, isTrue);
      // A grid takes the smallest and a lightbox the largest; that choice is
      // what keeps twenty tiles from costing hundreds of megabytes.
      expect(item.previewUrl, 'https://cdn.example/a-sm.jpg');
      expect(item.fullUrl, 'https://cdn.example/a-lg.jpg');
      expect(item.aspectRatio, closeTo(1.5, 0.001));
    });

    test('a small photograph falls back to the size it has', () {
      final item = MediaItem.fromJson({
        'id': 1,
        'large_url': 'https://cdn.example/a-lg.jpg',
      });

      expect(item.previewUrl, 'https://cdn.example/a-lg.jpg');
      expect(item.fullUrl, 'https://cdn.example/a-lg.jpg');
    });

    test('a video previews from its provider thumbnail, not a stored file', () {
      final item = MediaItem.fromJson({
        'id': 3,
        'media_type': MediaTypes.video,
        'external_url': 'https://www.youtube.com/watch?v=abcdefghijk',
        'embed_url': 'https://www.youtube-nocookie.com/embed/abcdefghijk',
        'thumbnail_url': 'https://i.ytimg.com/vi/abcdefghijk/hqdefault.jpg',
      });

      expect(item.isVideo, isTrue);
      expect(
        item.previewUrl,
        'https://i.ytimg.com/vi/abcdefghijk/hqdefault.jpg',
      );
      expect(item.aspectRatio, isNull);
    });

    test('a malformed payload is an empty item, not a crash', () {
      final item = MediaItem.fromJson({});

      expect(item.id, 0);
      expect(item.mediaType, MediaTypes.photo);
      expect(item.title.value, isNull);
      expect(item.previewUrl, isNull);
    });
  });

  group('MediaPage', () {
    test('appending a page keeps the earlier items and the newer position', () {
      const first = MediaPage(items: []);
      final second = MediaPage(items: [testMediaItem(id: 1)]);

      final combined = first.followedBy(second);

      expect(combined.items, hasLength(1));
      expect(combined.currentPage, 1);
    });
  });

  group('GalleryQuery', () {
    test('two identical queries are the same provider key', () {
      // Without value equality every rebuild would refetch the same page.
      expect(
        const GalleryQuery(type: MediaTypes.video, page: 2),
        const GalleryQuery(type: MediaTypes.video, page: 2),
      );
      expect(
        const GalleryQuery(type: MediaTypes.video).hashCode,
        const GalleryQuery(type: MediaTypes.video).hashCode,
      );
      expect(const GalleryQuery(page: 1), isNot(const GalleryQuery(page: 2)));
    });

    test('builds the query string the API expects', () {
      final params = const GalleryQuery(
        type: MediaTypes.photo,
        album: 'janmashtami',
        page: 3,
        perPage: 12,
      ).toQueryParameters('en');

      expect(params['lang'], 'en');
      expect(params['type'], MediaTypes.photo);
      expect(params['album'], 'janmashtami');
      expect(params['page'], 3);
      expect(params['per_page'], 12);
    });

    test('omits filters that were not asked for', () {
      final params = const GalleryQuery().toQueryParameters('hi');

      expect(params.containsKey('type'), isFalse);
      expect(params.containsKey('album'), isFalse);
    });
  });

  group('drafts', () {
    test('a video draft sends blank optional fields as null', () {
      final json = const VideoDraft(
        externalUrl: '  https://youtu.be/abcdefghijk  ',
        titleHi: '  आरती  ',
        titleEn: '   ',
        status: MediaStatuses.published,
      ).toJson();

      expect(json['external_url'], 'https://youtu.be/abcdefghijk');
      expect(json['title_hi'], 'आरती');
      // The bilingual fallback keys on absence, and '' is not absence.
      expect(json['title_en'], isNull);
      expect(json['caption_hi'], isNull);
    });

    test('an edit carries no file', () {
      final json = const MediaDraft(
        titleHi: 'शीर्षक',
        status: MediaStatuses.draft,
      ).toJson();

      // Replacing bytes under a URL would silently change a page, a poster and
      // a portrait at once, so the draft has no way to express it.
      expect(json.containsKey('file'), isFalse);
      expect(json['status'], MediaStatuses.draft);
    });

    test(
      'an album draft omits an unset sort order rather than sending zero',
      () {
        final json = const AlbumDraft(
          titleHi: 'जन्माष्टमी',
          status: MediaStatuses.published,
        ).toJson();

        expect(json.containsKey('sort_order'), isFalse);
        expect(json['slug'], isNull);
      },
    );
  });

  group('MediaReferences', () {
    test('reads what is blocking a deletion', () {
      final references = MediaReferences.fromJson({
        'can_delete': false,
        'references': [
          {'type': 'event_poster', 'label': 'जन्माष्टमी', 'id': 4},
          {'type': 'page', 'label': 'मंदिर परिचय', 'id': 2},
        ],
      });

      expect(references.canDelete, isFalse);
      expect(references.references, hasLength(2));
      expect(references.references.first.type, 'event_poster');
      expect(references.references.first.label, 'जन्माष्टमी');
    });

    test('an empty answer means the file may be deleted', () {
      final references = MediaReferences.fromJson({
        'can_delete': true,
        'references': <Object>[],
      });

      expect(references.canDelete, isTrue);
      expect(references.references, isEmpty);
    });
  });

  group('AdminMedia', () {
    test('the reference URL is the one the deletion guard looks for', () async {
      final photo = testAdminMedia();
      final video = testAdminMedia(
        id: 2,
        type: MediaTypes.video,
        externalUrl: 'https://www.youtube.com/watch?v=abcdefghijk',
      );

      // Choosing a photograph in the picker stores exactly this value, so the
      // picker and the guard agree by construction rather than by luck.
      expect(photo.referenceUrl, photo.fileUrl);
      expect(video.referenceUrl, video.externalUrl);
    });
  });

  group('MediaFormatting', () {
    late AppLocalizations l10n;

    setUp(() async {
      l10n = await AppLocalizations.delegate.load(AppLocales.hindi);
    });

    test('file sizes read the way an operating system reports them', () {
      expect(MediaFormatting.fileSize(null), '—');
      expect(MediaFormatting.fileSize(0), '—');
      expect(MediaFormatting.fileSize(512), '512 B');
      expect(MediaFormatting.fileSize(2048), '2 KB');
      expect(MediaFormatting.fileSize(1572864), '1.5 MB');
    });

    test('dimensions are omitted where there are none', () {
      expect(MediaFormatting.dimensions(1920, 1280), '1920 × 1280');
      expect(MediaFormatting.dimensions(null, 1280), isNull);
      expect(MediaFormatting.dimensions(0, 0), isNull);
    });

    test('every reference type the server can return has words', () {
      for (final type in const [
        'event_poster',
        'committee_member',
        'temple_logo',
        'album_cover',
        'page',
      ]) {
        final label = MediaFormatting.referenceLabel(type, l10n);
        expect(label, isNotEmpty);
        expect(label, isNot(type), reason: '$type was not translated');
      }
    });

    test('an unknown reference type falls back to its code, not to nothing', () {
      // A blocked deletion has to say *something*; a code the reader can quote
      // back to us beats a blank line.
      expect(
        MediaFormatting.referenceLabel('future_thing', l10n),
        'future_thing',
      );
    });
  });
}
