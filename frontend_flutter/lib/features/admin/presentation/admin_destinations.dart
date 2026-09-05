import 'package:flutter/material.dart';

import '../../../app/routing/route_paths.dart';
import '../../../core/auth/permissions.dart';
import '../../../l10n/app_localizations.dart';

/// One module of the admin console.
class AdminDestination {
  const AdminDestination({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.route,
    required this.permissions,
  });

  /// Stable across renames and translations. Widget keys are built from it, so
  /// a test that finds `dash-donations` keeps working when the label changes.
  final String id;

  final IconData icon;
  final String title;

  /// The one-line explanation. The side menu does not show it — a menu is a
  /// list of names — but the dashboard and a tooltip do.
  final String description;

  final String route;

  /// Any one of these is enough to be offered the door.
  final List<String> permissions;

  Key get key => Key('dash-$id');

  bool isVisibleTo(PermissionSet held) => held.canAny(permissions);

  /// Whether [location] is inside this module, so the menu can mark it current.
  ///
  /// Prefix matching, so `/admin/enquiries/5` highlights `संपर्क एवं पूछताछ`.
  /// The boundary check matters: without it `/admin/media-archive` would light
  /// up `/admin/media`.
  bool matches(String location) =>
      location == route || location.startsWith('$route/');
}

/// Every module of the admin console, in the order they are offered.
///
/// **This is the only list.** It was previously written out inside the
/// dashboard, and the side menu would have needed a second copy; two copies of
/// a permission rule drift, and the day they disagree is the day somebody is
/// shown a door that will not open. The menu, the dashboard and anything later
/// all read this (PHASE_8_PLAN §9).
///
/// The permissions here are a **courtesy**, never the access control. Every one
/// of these routes is authorized again by the server, which the backend tests
/// assert by calling the API directly with roles that should be refused.
class AdminDestinations {
  const AdminDestinations._();

  static List<AdminDestination> all(AppLocalizations l10n) => [
    AdminDestination(
      id: 'pages',
      icon: Icons.article_outlined,
      title: l10n.adminPagesTitle,
      description: l10n.navPagesDesc,
      route: RoutePaths.adminPages,
      permissions: const [Permissions.contentManage],
    ),
    AdminDestination(
      id: 'site-settings',
      icon: Icons.tune_outlined,
      title: l10n.navSiteSettings,
      description: l10n.navSiteSettingsDesc,
      route: RoutePaths.adminSiteSettings,
      permissions: const [Permissions.contentManage],
    ),
    // Reading the profile and the committee needs only content.view; changing
    // them needs temple.manage. Either is reason to offer the door.
    AdminDestination(
      id: 'temple-profile',
      icon: Icons.temple_hindu_outlined,
      title: l10n.navTempleProfile,
      description: l10n.navTempleProfileDesc,
      route: RoutePaths.adminTempleProfile,
      permissions: const [Permissions.templeManage, Permissions.contentView],
    ),
    AdminDestination(
      id: 'committee',
      icon: Icons.groups_outlined,
      title: l10n.navCommittee,
      description: l10n.navCommitteeDesc,
      route: RoutePaths.adminCommittee,
      permissions: const [Permissions.templeManage, Permissions.contentView],
    ),
    AdminDestination(
      id: 'events',
      icon: Icons.event_outlined,
      title: l10n.navEvents,
      description: l10n.navEventsDesc,
      route: RoutePaths.adminEvents,
      permissions: const [Permissions.eventsManage, Permissions.contentView],
    ),
    AdminDestination(
      id: 'media',
      icon: Icons.photo_library_outlined,
      title: l10n.navMedia,
      description: l10n.navMediaDesc,
      route: RoutePaths.adminMedia,
      permissions: const [Permissions.mediaManage, Permissions.contentView],
    ),
    AdminDestination(
      id: 'announcements',
      icon: Icons.campaign_outlined,
      title: l10n.navAnnouncements,
      description: l10n.navAnnouncementsDesc,
      route: RoutePaths.adminAnnouncements,
      permissions: const [
        Permissions.announcementsManage,
        Permissions.contentView,
      ],
    ),
    // Reading the register needs donations.view; recording needs
    // donations.manage. Either is reason to offer the door — and a Content
    // Manager, who holds neither, is not shown one.
    AdminDestination(
      id: 'donations',
      icon: Icons.volunteer_activism_outlined,
      title: l10n.navDonations,
      description: l10n.navDonationsDesc,
      route: RoutePaths.adminDonations,
      permissions: const [
        Permissions.donationsView,
        Permissions.donationsManage,
      ],
    ),
    // Reading the books needs accounts.view; recording and approving need
    // accounts.manage. Either is reason to offer the door — and a Content
    // Manager, who holds neither, is not shown one: the specification says a
    // Content Manager never sees financial detail.
    AdminDestination(
      id: 'accounts',
      icon: Icons.account_balance_outlined,
      title: l10n.accountsTitle,
      description: l10n.navAccountsDesc,
      route: RoutePaths.adminAccounts,
      permissions: const [Permissions.accountsView, Permissions.accountsManage],
    ),
    // Reading the inbox and answering it are the same right: there is no
    // view-only tier for a villager's telephone number and their complaint
    // (PHASE_7_PLAN assumption N9).
    AdminDestination(
      id: 'enquiries',
      icon: Icons.mark_email_unread_outlined,
      title: l10n.navEnquiries,
      description: l10n.navEnquiriesDesc,
      route: RoutePaths.adminEnquiries,
      permissions: const [Permissions.enquiriesManage],
    ),
    AdminDestination(
      id: 'users',
      icon: Icons.group_outlined,
      title: l10n.navUsers,
      description: l10n.navUsersDesc,
      route: RoutePaths.adminUsers,
      permissions: const [Permissions.usersView],
    ),
    AdminDestination(
      id: 'roles',
      icon: Icons.verified_user_outlined,
      title: l10n.navRoles,
      description: l10n.navRolesDesc,
      route: RoutePaths.adminRoles,
      permissions: const [Permissions.rolesView],
    ),
  ];

  /// What this account may open.
  static List<AdminDestination> visibleTo(
    AppLocalizations l10n,
    PermissionSet held,
  ) =>
      all(l10n)
          .where((entry) => entry.isVisibleTo(held))
          .toList(growable: false);
}
