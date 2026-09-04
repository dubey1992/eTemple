import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/auth_user.dart';
import '../data/admin_providers.dart';
import '../domain/admin_models.dart';
import 'widgets/status_chip.dart';

/// Lists committee accounts.
class AdminUsersScreen extends ConsumerWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final users = ref.watch(adminUsersProvider);
    final canManage = ref.watch(canProvider(Permissions.usersManage));

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.usersTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.usersSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  FilledButton.icon(
                    key: const Key('users-new'),
                    onPressed: () => context.go(RoutePaths.adminUserNew),
                    icon: const Icon(Icons.person_add_alt),
                    label: Text(l10n.userNew),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            users.when(
              loading: () => const LoadingView(),
              error: (error, _) {
                final exception = error is AppException
                    ? error
                    : const AppException.unknown();

                if (exception.code == ErrorCode.forbidden) {
                  return const UnauthorizedView();
                }
                return ErrorView(
                  error: exception,
                  onRetry: () => ref.invalidate(adminUsersProvider),
                );
              },
              data: (list) => list.isEmpty
                  ? const EmptyView()
                  : Column(
                      children: [
                        for (final user in list)
                          _UserTile(
                            key: Key('user-tile-${user.id}'),
                            user: user,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({super.key, required this.user});

  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              user.displayName.characters.first,
              style: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            ),
          ),
          title: Text(user.displayName),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(user.email, style: theme.textTheme.bodySmall),
                if (user.role != null)
                  StatusChip(label: user.role!.name, tone: StatusTone.neutral),
                StatusChip(
                  label: switch (user.status) {
                    AccountStatus.active => l10n.statusActive,
                    AccountStatus.inactive => l10n.statusInactive,
                    AccountStatus.blocked => l10n.statusBlocked,
                  },
                  tone: user.isActive
                      ? StatusTone.positive
                      : StatusTone.warning,
                ),
                // A member who has not followed their invitation link yet is
                // worth surfacing: it usually means the e-mail never arrived.
                if (user.hasNeverSignedIn)
                  StatusChip(
                    label: l10n.userNeverSignedIn,
                    tone: StatusTone.info,
                  ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(RoutePaths.adminUserEditor(user.id)),
        ),
      ),
    );
  }
}
