import 'localized_value.dart';

/// A published CMS page as a visitor sees it.
class PageContent {
  const PageContent({
    required this.id,
    required this.slug,
    required this.requestedLanguage,
    required this.title,
    required this.content,
    required this.metaTitle,
    required this.metaDescription,
    this.publishedAt,
    this.updatedAt,
  });

  factory PageContent.fromJson(Map<String, dynamic> json) => PageContent(
    id: _asInt(json['id']) ?? 0,
    slug: json['slug'] as String? ?? '',
    requestedLanguage: json['requested_language'] as String? ?? 'hi',
    title: LocalizedValue.fromJson(json['title']),
    content: LocalizedValue.fromJson(json['content']),
    metaTitle: LocalizedValue.fromJson(json['meta_title']),
    metaDescription: LocalizedValue.fromJson(json['meta_description']),
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
  );

  final int id;
  final String slug;

  /// The language the client asked for, echoed back by the server.
  final String requestedLanguage;

  final LocalizedValue title;
  final LocalizedValue content;
  final LocalizedValue metaTitle;
  final LocalizedValue metaDescription;
  final DateTime? publishedAt;
  final DateTime? updatedAt;

  /// True when English was requested but some part was served in Hindi.
  ///
  /// Drives the one unobtrusive notice on the page, rather than a badge on
  /// every individual block.
  bool get usesFallback =>
      title.fallbackUsed ||
      content.fallbackUsed ||
      metaTitle.fallbackUsed ||
      metaDescription.fallbackUsed;

  /// A page whose body the committee has not written yet.
  bool get hasNoContent => content.isEmpty;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// A page as the editor sees it: both languages, raw, no fallback applied.
class EditablePage {
  const EditablePage({
    required this.id,
    required this.slug,
    required this.titleHi,
    required this.contentHi,
    required this.status,
    this.titleEn,
    this.contentEn,
    this.metaTitleHi,
    this.metaTitleEn,
    this.metaDescriptionHi,
    this.metaDescriptionEn,
    this.publishedAt,
  });

  factory EditablePage.fromJson(Map<String, dynamic> json) => EditablePage(
    id: PageContent._asInt(json['id']) ?? 0,
    slug: json['slug'] as String? ?? '',
    titleHi: json['title_hi'] as String? ?? '',
    titleEn: json['title_en'] as String?,
    contentHi: json['content_hi'] as String? ?? '',
    contentEn: json['content_en'] as String?,
    metaTitleHi: json['meta_title_hi'] as String?,
    metaTitleEn: json['meta_title_en'] as String?,
    metaDescriptionHi: json['meta_description_hi'] as String?,
    metaDescriptionEn: json['meta_description_en'] as String?,
    status: PageStatus.fromWire(json['status'] as String?),
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
  );

  final int id;
  final String slug;
  final String titleHi;
  final String? titleEn;
  final String contentHi;
  final String? contentEn;
  final String? metaTitleHi;
  final String? metaTitleEn;
  final String? metaDescriptionHi;
  final String? metaDescriptionEn;
  final PageStatus status;
  final DateTime? publishedAt;

  /// True when the page exists in Hindi only — useful signal for the editor.
  bool get isHindiOnly =>
      (titleEn?.trim().isEmpty ?? true) || (contentEn?.trim().isEmpty ?? true);
}

enum PageStatus {
  draft('draft'),
  published('published');

  const PageStatus(this.wireValue);

  final String wireValue;

  static PageStatus fromWire(String? value) => PageStatus.values.firstWhere(
    (s) => s.wireValue == value,
    orElse: () => PageStatus.draft,
  );
}
