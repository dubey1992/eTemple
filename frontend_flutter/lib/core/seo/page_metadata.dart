/// The metadata one route contributes to the document head.
///
/// Kept as a plain value object so the SEO strategy is testable on the Dart VM
/// without a browser.
class PageMetadata {
  const PageMetadata({
    required this.title,
    required this.language,
    this.description,
    this.canonicalPath,
  });

  /// The document title, already including the site name where appropriate.
  final String title;

  /// BCP-47 language of the content actually being shown ("hi" or "en"),
  /// written to `<html lang>` so crawlers and screen readers agree with it.
  final String language;

  final String? description;

  /// Path this page should be indexed under, e.g. `/about`.
  final String? canonicalPath;

  /// Composes the browser/tab title from a page title and the site name.
  ///
  /// Skips the suffix when the page title already carries the site name — an
  /// SEO title such as "राधा कृष्ण ठाकुरबाड़ी, अमरपुर पंखोरिया" must not become
  /// "... | राधा कृष्ण ठाकुरबाड़ी".
  static String compose({
    required String? pageTitle,
    required String siteName,
  }) {
    final page = pageTitle?.trim();
    if (page == null || page.isEmpty) return siteName;
    if (page == siteName || page.contains(siteName)) return page;
    return '$page | $siteName';
  }

  /// Search engines truncate long descriptions; keep them useful.
  String? get trimmedDescription {
    final text = description?.trim();
    if (text == null || text.isEmpty) return null;
    if (text.length <= 160) return text;
    return '${text.substring(0, 157).trimRight()}…';
  }

  @override
  String toString() =>
      'PageMetadata($title, lang: $language, canonical: $canonicalPath)';
}
