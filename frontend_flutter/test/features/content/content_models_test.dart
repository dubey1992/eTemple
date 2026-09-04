import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/content/domain/page_content.dart';
import 'package:rkt_web/features/content/domain/site_settings.dart';

void main() {
  group('LocalizedValue', () {
    test('parses the documented block', () {
      final v = LocalizedValue.fromJson({
        'value': 'हिन्दी',
        'language': 'hi',
        'fallback_used': true,
      });

      expect(v.value, 'हिन्दी');
      expect(v.language, 'hi');
      expect(v.fallbackUsed, isTrue);
    });

    test('treats a null or blank value as empty', () {
      expect(LocalizedValue.fromJson({'value': null}).isEmpty, isTrue);
      expect(LocalizedValue.fromJson({'value': '   '}).isEmpty, isTrue);
      expect(LocalizedValue.fromJson(null).isEmpty, isTrue);
      expect(LocalizedValue.fromJson('not-an-object').isEmpty, isTrue);
    });

    test('defaults defensively when the server omits fields', () {
      final v = LocalizedValue.fromJson({'value': 'x'});

      expect(v.language, 'hi');
      expect(v.fallbackUsed, isFalse);
    });

    test('splits content into paragraphs on blank lines', () {
      final v = LocalizedValue.fromJson({
        'value': 'पहला।\n\nदूसरा।\n\n\n  तीसरा।  ',
      });

      expect(v.paragraphs, ['पहला।', 'दूसरा।', 'तीसरा।']);
    });

    test('a single line is one paragraph, and empty text has none', () {
      expect(LocalizedValue.fromJson({'value': 'एक'}).paragraphs, ['एक']);
      expect(LocalizedValue.empty.paragraphs, isEmpty);
    });

    test('an excerpt keeps the fallback flag', () {
      const v = LocalizedValue(
        value: 'पहला।\n\nदूसरा।',
        language: 'hi',
        fallbackUsed: true,
      );

      expect(v.firstParagraphOnly.value, 'पहला।');
      expect(v.firstParagraphOnly.fallbackUsed, isTrue);
    });

    test('orElse supplies a placeholder only when empty', () {
      expect(LocalizedValue.empty.orElse('fallback'), 'fallback');
      expect(
        const LocalizedValue(
          value: 'real',
          language: 'hi',
          fallbackUsed: false,
        ).orElse('fallback'),
        'real',
      );
    });
  });

  group('PageContent', () {
    Map<String, dynamic> block(String? value, {bool fallback = false}) => {
      'value': value,
      'language': fallback ? 'hi' : 'en',
      'fallback_used': fallback,
    };

    test('parses a full payload', () {
      final page = PageContent.fromJson({
        'id': 7,
        'slug': 'about',
        'requested_language': 'en',
        'title': block('About'),
        'content': block('Body'),
        'meta_title': block('Meta'),
        'meta_description': block('Description'),
        'published_at': '2026-09-04T06:30:00+05:30',
      });

      expect(page.id, 7);
      expect(page.slug, 'about');
      expect(page.requestedLanguage, 'en');
      expect(page.title.value, 'About');
      expect(page.publishedAt, isNotNull);
      expect(page.usesFallback, isFalse);
    });

    test('reports a fallback when any block fell back', () {
      final page = PageContent.fromJson({
        'id': 1,
        'slug': 'about',
        'requested_language': 'en',
        'title': block('About'),
        'content': block('हिन्दी', fallback: true),
        'meta_title': block(null),
        'meta_description': block(null),
      });

      expect(page.usesFallback, isTrue);
    });

    test('survives a payload missing every optional field', () {
      final page = PageContent.fromJson({'id': 1, 'slug': 'about'});

      expect(page.title.isEmpty, isTrue);
      expect(page.hasNoContent, isTrue);
      expect(page.publishedAt, isNull);
      expect(page.usesFallback, isFalse);
    });
  });

  group('EditablePage', () {
    test('parses both languages raw and defaults status to draft', () {
      final page = EditablePage.fromJson({
        'id': 2,
        'slug': 'about',
        'title_hi': 'शीर्षक',
        'title_en': null,
        'content_hi': 'सामग्री',
        'content_en': null,
      });

      expect(page.status, PageStatus.draft);
      expect(page.isHindiOnly, isTrue);
    });

    test('is not flagged Hindi-only when English is present', () {
      final page = EditablePage.fromJson({
        'id': 2,
        'slug': 'about',
        'title_hi': 'शीर्षक',
        'title_en': 'Title',
        'content_hi': 'सामग्री',
        'content_en': 'Content',
        'status': 'published',
      });

      expect(page.status, PageStatus.published);
      expect(page.isHindiOnly, isFalse);
    });
  });

  group('SiteSettings', () {
    test('sorts navigation by sort order and ignores malformed entries', () {
      final settings = SiteSettings.fromJson({
        'requested_language': 'hi',
        'navigation': [
          {
            'id': 2,
            'label': {'value': 'दूसरा'},
            'route': '/b',
            'sort_order': 5,
          },
          'garbage',
          {
            'id': 1,
            'label': {'value': 'पहला'},
            'route': '/a',
            'sort_order': 1,
          },
        ],
      });

      expect(settings.navigation.map((n) => n.route), ['/a', '/b']);
      expect(settings.hasNavigation, isTrue);
    });

    test('an unconfigured site parses to empty values, not an error', () {
      final settings = SiteSettings.fromJson({});

      expect(settings.tagline.isEmpty, isTrue);
      expect(settings.navigation, isEmpty);
      expect(settings.contact.isEmpty, isTrue);
      expect(settings.socialLinks, isEmpty);
    });

    test('external navigation targets are recognised', () {
      const internal = NavigationEntry(
        id: 1,
        label: LocalizedValue.empty,
        route: '/about',
        sortOrder: 0,
      );
      const external = NavigationEntry(
        id: 2,
        label: LocalizedValue.empty,
        route: 'https://example.test',
        sortOrder: 1,
      );

      expect(internal.isExternal, isFalse);
      expect(external.isExternal, isTrue);
    });

    test('keeps only usable social links', () {
      final settings = SiteSettings.fromJson({
        'social_links': {'facebook': 'https://example.test', 'x': '', 'n': 42},
      });

      expect(settings.socialLinks, {'facebook': 'https://example.test'});
    });
  });

  group('ContactInfo', () {
    test('builds address lines in order, skipping blanks', () {
      final contact = ContactInfo.fromJson({
        'village': 'Amarpur Pankhoriya',
        'panchayat': 'Kurma',
        'police_station': 'Rasulpur Ekchari',
        'district': 'Bhagalpur',
        'state': 'Bihar',
        'postal_code': '813204',
        'country': 'India',
        'address_line1': '   ',
      });

      expect(contact.addressLines, [
        'Amarpur Pankhoriya, पंचायत: Kurma',
        'Rasulpur Ekchari, Bhagalpur, Bihar, 813204',
        'India',
      ]);
      expect(contact.isEmpty, isFalse);
    });

    test('an unfilled contact block is empty', () {
      expect(ContactInfo.fromJson(null).isEmpty, isTrue);
      expect(ContactInfo.fromJson({'phone': '  '}).isEmpty, isTrue);
    });

    test('a phone number alone makes it non-empty', () {
      expect(
        ContactInfo.fromJson({'phone': '+91 90000 00000'}).isEmpty,
        isFalse,
      );
    });
  });
}
