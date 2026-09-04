import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/content/domain/content_repository.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/content/domain/page_content.dart';
import 'package:rkt_web/features/content/domain/site_settings.dart';

/// Scriptable stand-in for the HTTP content repository.
///
/// Widget tests use this so nothing touches a network and every state — loaded,
/// empty, missing, forbidden, offline — is reproducible.
class FakeContentRepository implements ContentRepository {
  FakeContentRepository({
    Map<String, PageContent>? pages,
    SiteSettings? settings,
    this.pageError,
    this.settingsError,
    this.adminError,
    this.saveError,
    this.delay = Duration.zero,
  }) : pages = pages ?? {},
       settings = settings ?? SiteSettings.empty;

  /// Keyed by slug. A slug absent from the map behaves like a 404, which is how
  /// the server treats both unknown and draft pages.
  final Map<String, PageContent> pages;
  SiteSettings settings;

  AppException? pageError;
  AppException? settingsError;
  AppException? adminError;
  AppException? saveError;
  Duration delay;

  List<EditablePage> adminPageList = [];

  int pageCalls = 0;
  int settingsCalls = 0;
  int saveCalls = 0;
  int saveSettingsCalls = 0;
  SiteSettingsDraft? lastSettingsDraft;
  EditableSiteSettings editableSettings = const EditableSiteSettings();
  String? lastLanguage;
  EditablePageDraft? lastDraft;

  @override
  Future<PageContent> page(String slug, {required String language}) async {
    pageCalls++;
    lastLanguage = language;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (pageError != null) throw pageError!;

    final page = pages[slug];
    if (page == null) {
      throw const AppException(
        code: ErrorCode.notFound,
        debugMessage: 'No such published page.',
      );
    }
    return page;
  }

  @override
  Future<SiteSettings> siteSettings({required String language}) async {
    settingsCalls++;
    lastLanguage = language;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (settingsError != null) throw settingsError!;
    return settings;
  }

  @override
  Future<List<EditablePage>> adminPages() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (adminError != null) throw adminError!;
    return adminPageList;
  }

  @override
  Future<EditablePage> adminPage(int id) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (adminError != null) throw adminError!;
    return adminPageList.firstWhere(
      (p) => p.id == id,
      orElse: () => throw const AppException(code: ErrorCode.notFound),
    );
  }

  @override
  Future<EditableSiteSettings> adminSiteSettings() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (adminError != null) throw adminError!;
    return editableSettings;
  }

  @override
  Future<EditableSiteSettings> saveSiteSettings(SiteSettingsDraft draft) async {
    saveSettingsCalls++;
    lastSettingsDraft = draft;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (saveError != null) throw saveError!;
    return editableSettings;
  }

  @override
  Future<EditablePage> savePage(int id, EditablePageDraft draft) async {
    saveCalls++;
    lastDraft = draft;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (saveError != null) throw saveError!;

    final existing = adminPageList.firstWhere((p) => p.id == id);
    return EditablePage(
      id: existing.id,
      slug: existing.slug,
      titleHi: draft.titleHi,
      titleEn: draft.titleEn,
      contentHi: draft.contentHi,
      contentEn: draft.contentEn,
      status: draft.status,
    );
  }
}

/// A published page with both languages present.
PageContent testPage({
  int id = 1,
  String slug = 'about',
  String language = 'hi',
  String? title = 'हमारे बारे में',
  String? content = 'पहला अनुच्छेद।\n\nदूसरा अनुच्छेद।',
  bool fallbackUsed = false,
  String? metaTitle,
  String? metaDescription,
}) {
  LocalizedValue v(String? value) => LocalizedValue(
    value: value,
    language: fallbackUsed ? 'hi' : language,
    fallbackUsed: fallbackUsed,
  );

  return PageContent(
    id: id,
    slug: slug,
    requestedLanguage: language,
    title: v(title),
    content: v(content),
    metaTitle: v(metaTitle),
    metaDescription: v(metaDescription),
  );
}

/// Site settings with a tagline, an address and a two-item menu.
SiteSettings testSettings({
  String? tagline = 'भक्ति और सेवा का केंद्र',
  String? footer = 'श्री राधा कृष्ण ठाकुरबाड़ी समिति',
  List<NavigationEntry>? navigation,
  ContactInfo? contact,
}) {
  return SiteSettings(
    requestedLanguage: 'hi',
    tagline: LocalizedValue(
      value: tagline,
      language: 'hi',
      fallbackUsed: false,
    ),
    footerText: LocalizedValue(
      value: footer,
      language: 'hi',
      fallbackUsed: false,
    ),
    contact:
        contact ??
        const ContactInfo(
          phone: '+91 90000 00000',
          email: 'committee@thakurbari.test',
        ),
    navigation:
        navigation ??
        const [
          NavigationEntry(
            id: 1,
            label: LocalizedValue(
              value: 'मुख पृष्ठ',
              language: 'hi',
              fallbackUsed: false,
            ),
            route: '/',
            sortOrder: 0,
          ),
          NavigationEntry(
            id: 2,
            label: LocalizedValue(
              value: 'हमारे बारे में',
              language: 'hi',
              fallbackUsed: false,
            ),
            route: '/about',
            sortOrder: 1,
          ),
        ],
    socialLinks: const {},
    defaultMetaTitle: LocalizedValue.empty,
    defaultMetaDescription: LocalizedValue.empty,
  );
}

EditablePage testEditablePage({
  int id = 1,
  String slug = 'about',
  String titleHi = 'हमारे बारे में',
  String? titleEn = 'About us',
  String contentHi = 'हिन्दी सामग्री।',
  String? contentEn = 'English content.',
  PageStatus status = PageStatus.draft,
}) {
  return EditablePage(
    id: id,
    slug: slug,
    titleHi: titleHi,
    titleEn: titleEn,
    contentHi: contentHi,
    contentEn: contentEn,
    status: status,
  );
}
