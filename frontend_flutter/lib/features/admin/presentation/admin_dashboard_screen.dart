import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';
import 'admin_destinations.dart';

/// The administration home.
///
/// Since Phase 8 the side menu carries the navigation, so this is a landing
/// page rather than a menu: it greets whoever signed in, says what role they
/// hold, and offers the same modules as shortcuts — without repeating the
/// one-line descriptions the menu's tooltips already give.
///
/// It stays because a committee member who signs in twice a year needs to see
/// what they are allowed to do, and because it is where Phase 10's at-a-glance
/// figures will go.
///
/// The entries come from [AdminDestinations] — the same list the menu reads, so
/// the two cannot disagree about what this account may open.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).value;
    final entries = AdminDestinations.visibleTo(
      l10n,
      ref.watch(permissionsProvider),
    );

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
              _ShortcutGrid(entries: entries),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  const _ShortcutGrid({required this.entries});

  final List<AdminDestination> entries;

  @override
  Widget build(BuildContext context) {
    // Denser than before: with the menu carrying the labels these are
    // shortcuts, not the only way in, so more of them fit on one screen.
    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 2,
      FormFactor.tablet => 3,
      FormFactor.desktop => 4,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSpacing.md;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final entry in entries)
              SizedBox(
                width: width,
                child: _ShortcutCard(entry: entry),
              ),
          ],
        );
      },
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({required this.entry});

  final AdminDestination entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      // The description the cards used to print. Still available to anybody who
      // wants it, without eleven paragraphs on one screen.
      message: entry.description,
      child: Card(
        key: entry.key,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          onTap: () => context.go(entry.route),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(entry.icon, color: theme.colorScheme.primary),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  entry.title,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
