import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// One step in the admin trail.
///
/// [route] is null for the page you are already on, which is what makes the
/// last crumb plain text rather than a link.
class Crumb {
  const Crumb(this.label, [this.route]);

  final String label;
  final String? route;

  bool get isLink => route != null;
}

/// The trail for an admin location, deepest last.
///
/// A pure function of the path and the translations, so the whole navigation
/// map is unit-testable without pumping a widget: every admin route either
/// produces a trail or is a bug.
List<Crumb> adminTrail(String location, AppLocalizations l10n) {
  final path = _normalise(location);
  final dashboard = Crumb(l10n.adminDashboardTitle, RoutePaths.admin);

  // Ordered longest-prefix-first is not needed because each branch below tests
  // its own exact shape; the dynamic `:id` cases are matched by segment count.
  final segments = path.split('/').where((s) => s.isNotEmpty).toList();

  // Anything that is not under /admin has no admin trail.
  if (segments.isEmpty || segments.first != 'admin') return const [];
  if (segments.length == 1) return [Crumb(l10n.adminDashboardTitle)];

  final section = segments[1];
  final rest = segments.sublist(2);

  switch (section) {
    case 'pages':
      final pages = Crumb(l10n.adminPagesTitle, RoutePaths.adminPages);
      return rest.isEmpty
          ? [dashboard, Crumb(l10n.adminPagesTitle)]
          : [dashboard, pages, Crumb(l10n.adminEditPage)];

    case 'site-settings':
      return [dashboard, Crumb(l10n.navSiteSettings)];

    case 'temple-profile':
      return [dashboard, Crumb(l10n.navTempleProfile)];

    case 'committee':
      final committee = Crumb(l10n.navCommittee, RoutePaths.adminCommittee);
      if (rest.isEmpty) return [dashboard, Crumb(l10n.navCommittee)];
      return [
        dashboard,
        committee,
        Crumb(rest.first == 'new' ? l10n.memberNew : l10n.memberEdit),
      ];

    case 'events':
      final events = Crumb(l10n.navEvents, RoutePaths.adminEvents);
      if (rest.isEmpty) return [dashboard, Crumb(l10n.navEvents)];
      return [
        dashboard,
        events,
        Crumb(rest.first == 'new' ? l10n.eventNew : l10n.eventEdit),
      ];

    case 'donations':
      final donations = Crumb(l10n.navDonations, RoutePaths.adminDonations);
      if (rest.isEmpty) return [dashboard, Crumb(l10n.navDonations)];
      return [
        dashboard,
        donations,
        Crumb(rest.first == 'new' ? l10n.donationNew : l10n.donationEdit),
      ];

    case 'announcements':
      final announcements = Crumb(
        l10n.announcementsTitle,
        RoutePaths.adminAnnouncements,
      );
      if (rest.isEmpty) return [dashboard, Crumb(l10n.announcementsTitle)];
      return [
        dashboard,
        announcements,
        Crumb(
          rest.first == 'new' ? l10n.announcementNew : l10n.announcementEdit,
        ),
      ];

    case 'enquiries':
      if (rest.isEmpty) return [dashboard, Crumb(l10n.enquiryInboxTitle)];
      return [
        dashboard,
        Crumb(l10n.enquiryInboxTitle, RoutePaths.adminEnquiries),
        Crumb(l10n.enquiryDetailTitle),
      ];

    case 'donation-settings':
      // The register, not the dashboard, is the parent: the settings are
      // reached from it and that is where "back" should land.
      return [
        dashboard,
        Crumb(l10n.navDonations, RoutePaths.adminDonations),
        Crumb(l10n.navDonationSettings),
      ];

    case 'media':
      final media = Crumb(l10n.navMedia, RoutePaths.adminMedia);
      if (rest.isEmpty) return [dashboard, Crumb(l10n.navMedia)];
      return [
        dashboard,
        media,
        Crumb(rest.first == 'new' ? l10n.mediaNew : l10n.mediaEdit),
      ];

    case 'albums':
      // The library, not the dashboard, is the parent: albums are reached from
      // it and that is where "back" should land.
      final media = Crumb(l10n.navMedia, RoutePaths.adminMedia);
      final albums = Crumb(l10n.navAlbums, RoutePaths.adminAlbums);
      if (rest.isEmpty) return [dashboard, media, Crumb(l10n.navAlbums)];
      return [
        dashboard,
        media,
        albums,
        Crumb(rest.first == 'new' ? l10n.albumNew : l10n.albumEdit),
      ];

    case 'users':
      final users = Crumb(l10n.navUsers, RoutePaths.adminUsers);
      if (rest.isEmpty) return [dashboard, Crumb(l10n.navUsers)];
      return [
        dashboard,
        users,
        Crumb(rest.first == 'new' ? l10n.userNew : l10n.userEdit),
      ];

    case 'roles':
      final roles = Crumb(l10n.navRoles, RoutePaths.adminRoles);
      return rest.isEmpty
          ? [dashboard, Crumb(l10n.navRoles)]
          : [dashboard, roles, Crumb(l10n.rolePermissionsTitle)];

    default:
      // An admin path with no mapping still gets a way home rather than a
      // dead end.
      return [dashboard];
  }
}

String _normalise(String location) {
  final withoutQuery = location.split('?').first;
  if (withoutQuery.length > 1 && withoutQuery.endsWith('/')) {
    return withoutQuery.substring(0, withoutQuery.length - 1);
  }
  return withoutQuery;
}

/// The breadcrumb bar shown beneath the admin app bar.
///
/// Before this existed, opening a member or a page editor left no way back
/// except the browser button — which a hard refresh or a bookmarked deep link
/// does not provide.
class AdminBreadcrumbs extends StatelessWidget {
  const AdminBreadcrumbs({super.key, required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final trail = adminTrail(location, l10n);

    if (trail.length < 2) return const SizedBox.shrink();

    // The deepest crumb that is still a link is where "back" goes.
    final parent = trail.reversed.firstWhere(
      (c) => c.isLink,
      orElse: () => const Crumb('', RoutePaths.admin),
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              key: const Key('breadcrumb-back'),
              onPressed: () => context.go(parent.route ?? RoutePaths.admin),
              icon: const Icon(Icons.arrow_back),
              iconSize: 20,
              tooltip: l10n.actionBack,
              visualDensity: VisualDensity.compact,
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var i = 0; i < trail.length; i++) ...[
                      if (i > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      _CrumbLabel(crumb: trail[i], index: i),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CrumbLabel extends StatelessWidget {
  const _CrumbLabel({required this.crumb, required this.index});

  final Crumb crumb;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!crumb.isLink) {
      return Text(
        crumb.label,
        key: Key('breadcrumb-$index'),
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      );
    }

    return InkWell(
      key: Key('breadcrumb-$index'),
      onTap: () => context.go(crumb.route!),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 2,
        ),
        child: Text(
          crumb.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
