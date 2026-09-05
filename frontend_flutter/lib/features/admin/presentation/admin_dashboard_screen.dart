import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';

/// The administration home, showing only what this account may actually do.
///
/// Entries are hidden when the server would refuse them — a courtesy so the
/// committee is not offered doors that will not open, never the access control
/// itself.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).value;
    final permissions = ref.watch(permissionsProvider);

    final entries = <_Entry>[
      if (permissions.can(Permissions.contentManage))
        _Entry(
          key: const Key('dash-pages'),
          icon: Icons.article_outlined,
          title: l10n.adminPagesTitle,
          description: l10n.navPagesDesc,
          route: RoutePaths.adminPages,
        ),
      if (permissions.can(Permissions.contentManage))
        _Entry(
          key: const Key('dash-site-settings'),
          icon: Icons.tune_outlined,
          title: l10n.navSiteSettings,
          description: l10n.navSiteSettingsDesc,
          route: RoutePaths.adminSiteSettings,
        ),
      // Reading the profile and committee needs only content.view; changing
      // them needs temple.manage. Either is reason to offer the door.
      if (permissions.canAny(const [
        Permissions.templeManage,
        Permissions.contentView,
      ]))
        _Entry(
          key: const Key('dash-temple-profile'),
          icon: Icons.temple_hindu_outlined,
          title: l10n.navTempleProfile,
          description: l10n.navTempleProfileDesc,
          route: RoutePaths.adminTempleProfile,
        ),
      if (permissions.canAny(const [
        Permissions.templeManage,
        Permissions.contentView,
      ]))
        _Entry(
          key: const Key('dash-committee'),
          icon: Icons.groups_outlined,
          title: l10n.navCommittee,
          description: l10n.navCommitteeDesc,
          route: RoutePaths.adminCommittee,
        ),
      if (permissions.canAny(const [
        Permissions.eventsManage,
        Permissions.contentView,
      ]))
        _Entry(
          key: const Key('dash-events'),
          icon: Icons.event_outlined,
          title: l10n.navEvents,
          description: l10n.navEventsDesc,
          route: RoutePaths.adminEvents,
        ),
      if (permissions.canAny(const [
        Permissions.mediaManage,
        Permissions.contentView,
      ]))
        _Entry(
          key: const Key('dash-media'),
          icon: Icons.photo_library_outlined,
          title: l10n.navMedia,
          description: l10n.navMediaDesc,
          route: RoutePaths.adminMedia,
        ),
      // Reading the register needs donations.view; recording needs
      // donations.manage. Either is reason to offer the door — and a Content
      // Manager, who holds neither, is not shown one.
      if (permissions.canAny(const [
        Permissions.donationsView,
        Permissions.donationsManage,
      ]))
        _Entry(
          key: const Key('dash-donations'),
          icon: Icons.volunteer_activism_outlined,
          title: l10n.navDonations,
          description: l10n.navDonationsDesc,
          route: RoutePaths.adminDonations,
        ),
      // Reading the inbox and answering it are the same right: there is no
      // view-only tier for a villager's telephone number and their complaint
      // (PHASE_7_PLAN assumption N9).
      if (permissions.can(Permissions.enquiriesManage))
        _Entry(
          key: const Key('dash-enquiries'),
          icon: Icons.mark_email_unread_outlined,
          title: l10n.navEnquiries,
          description: l10n.navEnquiriesDesc,
          route: RoutePaths.adminEnquiries,
        ),
      if (permissions.can(Permissions.usersView))
        _Entry(
          key: const Key('dash-users'),
          icon: Icons.group_outlined,
          title: l10n.navUsers,
          description: l10n.navUsersDesc,
          route: RoutePaths.adminUsers,
        ),
      if (permissions.can(Permissions.rolesView))
        _Entry(
          key: const Key('dash-roles'),
          icon: Icons.verified_user_outlined,
          title: l10n.navRoles,
          description: l10n.navRolesDesc,
          route: RoutePaths.adminRoles,
        ),
    ];

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user == null
                  ? l10n.dashboardWelcome
                  : l10n.adminWelcome(user.displayName),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.roleLabel}: ${user?.role?.name ?? '—'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.dashboardSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            if (entries.isEmpty)
              Card(
                key: const Key('dash-no-access'),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    l10n.dashboardNoAccess,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              )
            else
              _EntryGrid(entries: entries),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({
    required this.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
  });

  final Key key;
  final IconData icon;
  final String title;
  final String description;
  final String route;
}

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.entries});

  final List<_Entry> entries;

  @override
  Widget build(BuildContext context) {
    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 1,
      FormFactor.tablet => 2,
      FormFactor.desktop => 3,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = AppSpacing.md;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in entries)
              SizedBox(
                width: width,
                child: _EntryCard(entry: entry),
              ),
          ],
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: entry.key,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.go(entry.route),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(entry.icon, color: theme.colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(entry.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(
                entry.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
