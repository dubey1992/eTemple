import 'package:web/web.dart' as web;

import 'page_metadata.dart';

/// Web implementation: rewrites the real document head.
class SeoMetadataService {
  SeoMetadataService();

  final List<PageMetadata> applied = [];

  PageMetadata? get lastApplied => applied.isEmpty ? null : applied.last;

  void apply(PageMetadata metadata) {
    applied.add(metadata);

    final document = web.document;
    document.title = metadata.title;
    document.documentElement?.setAttribute('lang', metadata.language);

    final description = metadata.trimmedDescription;
    _setMeta(name: 'description', content: description);
    _setMeta(property: 'og:title', content: metadata.title);
    _setMeta(property: 'og:description', content: description);
    _setMeta(
      property: 'og:locale',
      content: metadata.language == 'en' ? 'en_IN' : 'hi_IN',
    );

    final canonical = metadata.canonicalPath;
    if (canonical != null) {
      final url = '${web.window.location.origin}$canonical';
      _setMeta(property: 'og:url', content: url);
      _setLink(rel: 'canonical', href: url);
    }
  }

  /// Updates an existing tag or creates it; passing a null content removes it,
  /// so a page without a description does not inherit the previous page's.
  void _setMeta({String? name, String? property, required String? content}) {
    final selector = name != null
        ? 'meta[name="$name"]'
        : 'meta[property="$property"]';
    final existing = web.document.querySelector(selector);

    if (content == null) {
      existing?.remove();
      return;
    }

    if (existing != null) {
      existing.setAttribute('content', content);
      return;
    }

    final element = web.document.createElement('meta');
    if (name != null) {
      element.setAttribute('name', name);
    } else {
      element.setAttribute('property', property!);
    }
    element.setAttribute('content', content);
    web.document.head?.append(element);
  }

  void _setLink({required String rel, required String href}) {
    final existing = web.document.querySelector('link[rel="$rel"]');
    if (existing != null) {
      existing.setAttribute('href', href);
      return;
    }

    final element = web.document.createElement('link');
    element.setAttribute('rel', rel);
    element.setAttribute('href', href);
    web.document.head?.append(element);
  }
}
