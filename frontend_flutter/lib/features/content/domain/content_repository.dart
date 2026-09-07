import 'page_content.dart';
import 'site_settings.dart';

/// Contract for reading and editing CMS content.
///
/// Implementations live in `data/` and are the only place that knows about HTTP.
abstract interface class ContentRepository {
  /// A published page, resolved for [language].
  ///
  /// Throws `AppException(ErrorCode.notFound)` for an unknown slug or a page
  /// that is still a draft — the server deliberately makes those identical.
  /// Slugs of every published page.
  ///
  /// Asked before a page is fetched by name, so a site with nothing written
  /// yet answers with an empty list instead of a 404 per visit.
  Future<List<String>> publishedPageSlugs({required String language});

  Future<PageContent> page(String slug, {required String language});

  /// Site-wide settings and the visible navigation menu, resolved for [language].
  Future<SiteSettings> siteSettings({required String language});

  /// Every page including drafts, for the editor. Requires content permission.
  Future<List<EditablePage>> adminPages();

  /// One page with both languages raw, for the editor.
  Future<EditablePage> adminPage(int id);

  /// Saves an edit. Hindi fields are required by the server.
  Future<EditablePage> savePage(int id, EditablePageDraft draft);

  /// Site settings with both languages raw, for the editor.
  Future<EditableSiteSettings> adminSiteSettings();

  /// Saves the site-wide settings. Navigation is left untouched when the draft
  /// does not include it.
  Future<EditableSiteSettings> saveSiteSettings(SiteSettingsDraft draft);
}

/// The values an editor can change on a page.
///
/// A separate type from [EditablePage] so the write contract is explicit: the
/// slug and the publish timestamp are the server's to manage, not the editor's.
class EditablePageDraft {
  const EditablePageDraft({
    required this.titleHi,
    required this.contentHi,
    required this.status,
    this.titleEn,
    this.contentEn,
    this.metaTitleHi,
    this.metaTitleEn,
    this.metaDescriptionHi,
    this.metaDescriptionEn,
  });

  final String titleHi;
  final String? titleEn;
  final String contentHi;
  final String? contentEn;
  final String? metaTitleHi;
  final String? metaTitleEn;
  final String? metaDescriptionHi;
  final String? metaDescriptionEn;
  final PageStatus status;

  /// Blank optional fields are sent as null so the server stores "absent"
  /// rather than an empty string, which is what the fallback rule keys on.
  Map<String, Object?> toJson() => {
    'title_hi': titleHi.trim(),
    'title_en': _nullIfBlank(titleEn),
    'content_hi': contentHi.trim(),
    'content_en': _nullIfBlank(contentEn),
    'meta_title_hi': _nullIfBlank(metaTitleHi),
    'meta_title_en': _nullIfBlank(metaTitleEn),
    'meta_description_hi': _nullIfBlank(metaDescriptionHi),
    'meta_description_en': _nullIfBlank(metaDescriptionEn),
    'status': status.wireValue,
  };

  static String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
