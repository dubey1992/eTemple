import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/seo/seo_metadata_service.dart';
import '../domain/content_repository.dart';
import '../domain/page_content.dart';
import '../domain/site_settings.dart';
import 'content_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final contentRepositoryProvider = Provider<ContentRepository>(
  (ref) => ContentRepositoryImpl(ref.watch(apiClientProvider)),
);

/// One instance for the app so metadata updates are serialized and inspectable.
final seoMetadataServiceProvider = Provider<SeoMetadataService>(
  (ref) => SeoMetadataService(),
);

/// The active language as the API expects it (`hi` / `en`).
///
/// Derived from the locale controller so every content request re-runs when the
/// visitor switches language — that is what makes the switch reload CMS copy.
final contentLanguageProvider = Provider<String>(
  (ref) => ref.watch(localeControllerProvider).languageCode,
);

/// Site-wide settings for the current language. Feeds the shell's navigation,
/// footer and the home page's hero and address blocks.
final siteSettingsProvider = FutureProvider<SiteSettings>((ref) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(contentRepositoryProvider).siteSettings(language: language);
});

/// Navigation for the public shell.
///
/// Falls back to an empty menu rather than an error: a settings outage should
/// not stop a visitor reading a page they already navigated to.
final navigationProvider = Provider<List<NavigationEntry>>((ref) {
  return ref.watch(siteSettingsProvider).value?.navigation ?? const [];
});

/// A published page by slug, for the current language.
final pageProvider = FutureProvider.family<PageContent, String>((ref, slug) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(contentRepositoryProvider).page(slug, language: language);
});

/// Every page including drafts. Admin-only; the server enforces that.
final adminPagesProvider = FutureProvider<List<EditablePage>>(
  (ref) => ref.watch(contentRepositoryProvider).adminPages(),
);

/// One page loaded raw for editing.
final adminPageProvider = FutureProvider.family<EditablePage, int>(
  (ref, id) => ref.watch(contentRepositoryProvider).adminPage(id),
);
