import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/admin_destinations.dart';

/// The admin console's side menu.
///
/// One click to any module from anywhere, which the card grid could not do: it
/// cost a round trip back to the dashboard for every switch, and with eleven
/// modules that had stopped scaling.
///
/// It shows only what the signed-in account may open, from the same
/// [AdminDestinations] list the dashboard reads — a courtesy so nobody is
/// offered a door that will not open, never the access control, which is the
/// server's and is asserted by calling the API directly.
class AdminMenu extends ConsumerWidget {
  const AdminMenu({super.key, required this.location, this.onNavigate});

  final String location;

  /// Called after a destination is chosen, so the drawer can close itself on a
  /// phone. Null in the fixed rail, which has nothing to close.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final entries = AdminDestinations.visibleTo(
      l10n,
      ref.watch(permissionsProvider),
    );

    // `/admin` itself is a destination too — the landing page — and is marked
    // current only on an exact match, or every module would light it up.
    final atDashboard = location == RoutePaths.admin;

    return ListView(
      primary: false,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        _MenuTile(
          key: const Key('menu-dashboard'),
          icon: Icons.dashboard_outlined,
          label: l10n.adminDashboardTitle,
          selected: atDashboard,
          onTap: () {
            context.go(RoutePaths.admin);
            onNavigate?.call();
          },
        ),
        Divider(
          height: AppSpacing.md,
          indent: AppSpacing.md,
          endIndent: AppSpacing.md,
          color: theme.dividerColor,
        ),
        for (final entry in entries)
          _MenuTile(
            key: Key('menu-${entry.id}'),
            icon: entry.icon,
            label: entry.title,
            tooltip: entry.description,
            selected: entry.matches(location),
            onTap: () {
              context.go(entry.route);
              onNavigate?.call();
            },
          ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final String? tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = ListTile(
      dense: true,
      selected: selected,
      selectedColor: theme.colorScheme.primary,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      leading: Icon(icon, size: 20),
      title: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
      ),
      onTap: onTap,
    );

    return tooltip == null
        ? tile
        : Tooltip(
            message: tooltip!,
            waitDuration: const Duration(seconds: 1),
            child: tile,
          );
  }
}
