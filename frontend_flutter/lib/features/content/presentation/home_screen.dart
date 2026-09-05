import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/section_band.dart';
import '../../../core/widgets/state_views.dart';
import '../../events/data/event_providers.dart';
import '../../events/presentation/widgets/event_card.dart';
import '../../donations/data/donation_providers.dart';
import '../../donations/presentation/donate_screen.dart';
import '../../donations/presentation/widgets/donation_details_card.dart';
import '../../media/data/media_providers.dart';
import '../../media/presentation/widgets/gallery_mosaic.dart';
import '../../media/presentation/widgets/media_lightbox.dart';
import '../../temple/data/temple_providers.dart';
import '../../temple/domain/temple_profile.dart';
import '../../temple/presentation/widgets/committee_list.dart';
import '../data/content_providers.dart';
import '../domain/page_content.dart';
import 'seo_scope.dart';
import 'widgets/address_card.dart';
import 'widgets/content_widgets.dart';
import 'widgets/home_hero.dart';

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
          // Full-width bands rather than one padded column: the prototype
          // alternates the page ground so each section reads as its own block
          // on a long scroll, and a colour band has to run edge to edge.
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SectionBand(
                  gradient: AppColors.heroGradient,
                  verticalPadding: AppSpacing.xxl,
                  child: HomeHero(settings: data, profile: templeProfile),
                ),
                const SectionBand(child: _AboutSection()),
                const SectionBand.alternate(child: _UpcomingEventsSection()),
                // The prototype's order: events, then the donation block, then
                // the gallery, then the committee.
                const SectionBand(child: _DonateSection()),
                const SectionBand.alternate(child: _GallerySection()),
                const SectionBand(child: _CommitteeSection()),
                SectionBand.alternate(
                  child: ContentSection(
                    title: l10n.sectionAddress,
                    // The prototype's `संपर्क` block: the address here, and
                    // the form on its own page — the same shape /donate has,
                    // so the home page does not grow a second long form.
                    trailing: TextButton(
                      key: const Key('contact-open'),
                      onPressed: () => context.go(RoutePaths.contact),
                      child: Text(l10n.contactOpenForm),
                    ),
                    child: AddressCard(
                      address: templeProfile.address,
                      contact: data.contact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

/// What is coming up at the temple, with a link to the full calendar.
///
/// Loaded separately from the rest so a calendar outage degrades one section
/// rather than the whole page.
class _UpcomingEventsSection extends ConsumerWidget {
  const _UpcomingEventsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(featuredEventsProvider);

    return ContentSection(
      title: l10n.sectionEvents,
      trailing: (events.value?.isNotEmpty ?? false)
          ? TextButton(
              key: const Key('events-see-all'),
              onPressed: () => context.go(RoutePaths.events),
              child: Text(l10n.viewAllEvents),
            )
          : null,
      child: events.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: LoadingView(),
        ),
        // An empty calendar is an empty state, not an error.
        error: (_, _) => Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              l10n.noUpcomingEvents,
              key: const Key('events-unavailable'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        data: (data) => EventList(
          occurrences: data,
          limit: 3,
          emptyMessage: l10n.noUpcomingEvents,
        ),
      ),
    );
  }
}

/// The prototype's `दान` block.
///
/// Loaded separately from the rest so an unreachable set of bank details
/// degrades one section rather than the whole page — and never shows an account
/// number it could not load.
class _DonateSection extends ConsumerWidget {
  const _DonateSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final details = ref.watch(donationDetailsProvider);

    return ContentSection(
      title: l10n.donateTitle,
      subtitle: l10n.donateSubtitle,
      trailing: (details.value != null)
          ? TextButton(
              key: const Key('donate-see-all'),
              onPressed: () => context.go(RoutePaths.donate),
              child: Text(l10n.viewDonate),
            )
          : null,
      child: details.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: LoadingView(),
        ),
        error: (_, _) => const DonationDetailsUnavailable(),
        data: (data) => data == null
            ? const DonationDetailsUnavailable()
            : DonationDetailsCard(details: data),
      ),
    );
  }
}

/// The prototype's photo gallery block.
///
/// With nothing published it renders the approved design's own placeholder
/// tiles, which is what that design *is*: its caption says the photographs
/// "will appear here" (PHASE_5_PLAN assumption M12). Seeding invented
/// photographs to make the demo look full is not an option the working
/// agreement leaves open.
class _GallerySection extends ConsumerWidget {
  const _GallerySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final gallery = ref.watch(homeGalleryProvider);
    final items = gallery.value?.items ?? const [];

    return ContentSection(
      title: l10n.sectionGallery,
      subtitle: l10n.gallerySubtitle,
      trailing: items.isNotEmpty
          ? TextButton(
              key: const Key('gallery-see-all'),
              onPressed: () => context.go(RoutePaths.gallery),
              child: Text(l10n.viewGallery),
            )
          : null,
      child: gallery.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: LoadingView(),
        ),
        // An unreachable gallery falls back to the approved placeholder rather
        // than to an error: the block is decorative here, and the page a
        // devotee came for must not break because of it.
        error: (_, _) => const GalleryPlaceholderMosaic(),
        data: (page) => GalleryMosaic(
          items: page.items,
          onOpen: (item) => MediaLightbox.show(context, item),
        ),
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
