import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/seo/seo_metadata_service.dart';

void main() {
  group('PageMetadata.compose', () {
    const site = 'राधा कृष्ण ठाकुरवाड़ी';

    test('appends the site name to a page title', () {
      expect(
        PageMetadata.compose(pageTitle: 'हमारे बारे में', siteName: site),
        'हमारे बारे में | $site',
      );
    });

    test('does not duplicate the site name', () {
      expect(PageMetadata.compose(pageTitle: site, siteName: site), site);
    });

    test('does not append when the page title already names the temple', () {
      // A real SEO title from the CMS, which already carries the temple name.
      const seoTitle = 'राधा कृष्ण ठाकुरवाड़ी, अमरपुर पंखोरिया';

      expect(
        PageMetadata.compose(pageTitle: seoTitle, siteName: site),
        seoTitle,
      );
    });

    test('falls back to the site name when there is no page title', () {
      expect(PageMetadata.compose(pageTitle: null, siteName: site), site);
      expect(PageMetadata.compose(pageTitle: '   ', siteName: site), site);
    });
  });

  group('PageMetadata.trimmedDescription', () {
    test('keeps a short description intact', () {
      const meta = PageMetadata(
        title: 't',
        language: 'hi',
        description: 'A short description.',
      );

      expect(meta.trimmedDescription, 'A short description.');
    });

    test('truncates an over-long description search engines would cut', () {
      final meta = PageMetadata(
        title: 't',
        language: 'hi',
        description: 'x' * 400,
      );

      expect(meta.trimmedDescription!.length, lessThanOrEqualTo(160));
      expect(meta.trimmedDescription, endsWith('…'));
    });

    test('treats blank as absent so a stale tag is removed', () {
      const meta = PageMetadata(title: 't', language: 'hi', description: '  ');

      expect(meta.trimmedDescription, isNull);
    });
  });

  group('SeoMetadataService', () {
    test('records what it was asked to apply', () {
      final service = SeoMetadataService();

      expect(service.lastApplied, isNull);

      service.apply(
        const PageMetadata(
          title: 'हमारे बारे में | राधा कृष्ण ठाकुरवाड़ी',
          language: 'hi',
          description: 'मंदिर की जानकारी।',
          canonicalPath: '/about',
        ),
      );

      expect(service.applied, hasLength(1));
      expect(service.lastApplied!.language, 'hi');
      expect(service.lastApplied!.canonicalPath, '/about');
    });

    test('keeps the sequence so language switches are observable', () {
      final service = SeoMetadataService()
        ..apply(const PageMetadata(title: 'a', language: 'hi'))
        ..apply(const PageMetadata(title: 'b', language: 'en'));

      expect(service.applied.map((m) => m.language), ['hi', 'en']);
    });
  });
}
