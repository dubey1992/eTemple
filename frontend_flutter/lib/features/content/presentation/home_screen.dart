import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../temple/data/temple_providers.dart';
import '../../temple/domain/temple_profile.dart';
import '../../temple/presentation/widgets/committee_list.dart';
import '../data/content_providers.dart';
import '../domain/page_content.dart';
import '../domain/site_settings.dart';
import 'seo_scope.dart';
import 'widgets/address_card.dart';
import 'widgets/content_widgets.dart';

/// The public home page: hero, about excerpt, committee preview and the temple
/// address.
///
/// Every block is admin-managed — including the temple's own name, which comes
/// from the profile rather than the app's ARB files. Nothing here hardcodes
/// temple content: when the CMS is empty the page still renders, with each
/// section showing its own "coming soon" state rather than an error.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const String aboutSlug = 'about';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final settings = ref.watch(siteSettingsProvider);
    final profile = ref.watch(templeProfileProvider);

    return settings.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        error: error is AppException ? error : const AppException.unknown(),
        onRetry: () => ref.invalidate(siteSettingsProvider),
      ),
      data: (data) {
        // The profile is not allowed to take the page down: the hero degrades
        // to the app's own name and the address section shows its empty state.
        final templeProfile = profile.value ?? TempleProfile.empty;

        return SeoScope(
          title: templeProfile.name.orElse(l10n.appTitle),
          description:
              data.defaultMetaDescription.value ??
              data.tagline.value ??
              templeProfile.mission.value,
          canonicalPath: RoutePaths.home,
          child: SingleChildScrollView(
            child: PageContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(settings: data, profile: templeProfile),
                  const SizedBox(height: AppSpacing.xxl),
                  const _AboutSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  const _CommitteeSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  ContentSection(
                    title: l10n.sectionAddress,
                    child: AddressCard(
                      address: templeProfile.address,
                      contact: data.contact,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.settings, required this.profile});

  final SiteSettings settings;
  final TempleProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;
    final locality = profile.address.locality;

    return Column(
      children: [
        Text(
          l10n.invocation,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          // The temple's own name, from the profile. The ARB string stands in
          // only until that request resolves.
          profile.name.orElse(l10n.appTitle),
          key: const Key('hero-title'),
          textAlign: TextAlign.center,
          style:
              (isCompact
                      ? theme.textTheme.headlineMedium
                      : theme.textTheme.displaySmall)
                  ?.copyWith(color: theme.colorScheme.primary),
        ),
        // The village line is temple content: no fallback, it simply does not
        // appear until the committee fills in the address.
        if (locality != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            locality,
            key: const Key('hero-locality'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        // The devotional tagline is CMS-managed; it simply does not appear
        // until the committee writes one.
        if (settings.tagline.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          Text(
            settings.tagline.value!,
            key: const Key('hero-tagline'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// The About section, excerpted from the `about` CMS page.
///
/// Loaded separately from the hero so a failure here degrades one section
/// instead of blanking the whole home page.
class _AboutSection extends ConsumerWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final about = ref.watch(pageProvider(HomeScreen.aboutSlug));

    return ContentSection(
      title: l10n.sectionAbout,
      trailing: about.hasValue
          ? TextButton(
              key: const Key('about-read-more'),
              onPressed: () =>
                  context.go(RoutePaths.page(HomeScreen.aboutSlug)),
              child: Text(l10n.sectionReadMore),
            )
          : null,
      child: about.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: LoadingView(),
        ),
        // An unwritten About page is an empty state, not an error: a brand new
        // site has no content yet and must not look broken.
        error: (error, _) => _AboutUnavailable(error: error),
        data: (page) => _AboutPreview(page: page),
      ),
    );
  }
}

/// A preview of the management committee, with a link to the full page.
///
/// Loaded separately again, for the same reason: an outage here must not take
/// the address section down with it.
class _CommitteeSection extends ConsumerWidget {
  const _CommitteeSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final committee = ref.watch(committeeProvider);

    return ContentSection(
      title: l10n.sectionCommittee,
      trailing: (committee.value?.isNotEmpty ?? false)
          ? TextButton(
              key: const Key('committee-see-all'),
              onPressed: () => context.go(RoutePaths.committee),
              child: Text(l10n.viewCommittee),
            )
          : null,
      child: committee.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: LoadingView(),
        ),
        // An unlisted committee is an empty state, not an error.
        error: (_, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.committeeComingSoon,
              key: const Key('committee-unavailable'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        data: (members) => CommitteeList(members: members, limit: 3),
      ),
    );
  }
}

class _AboutPreview extends StatelessWidget {
  const _AboutPreview({required this.page});

  final PageContent page;

  @override
  Widget build(BuildContext context) {
    final paragraphs = page.content.paragraphs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (page.usesFallback) ...[
          const FallbackNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ContentBody(
              // Only the first paragraph on the home page; the full text lives
              // on /about behind "read more".
              content: paragraphs.isEmpty
                  ? page.content
                  : page.content.firstParagraphOnly,
            ),
          ),
        ),
      ],
    );
  }
}

class _AboutUnavailable extends StatelessWidget {
  const _AboutUnavailable({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final exception = error is AppException
        ? error as AppException
        : const AppException.unknown();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: exception.isNotFound
            ? Text(
                context.l10n.contentComingSoon,
                key: const Key('about-coming-soon'),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              )
            : ErrorView(error: exception),
      ),
    );
  }
}
