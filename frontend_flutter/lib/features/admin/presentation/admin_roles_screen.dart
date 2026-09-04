import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_providers.dart';
import '../domain/admin_models.dart';
import 'widgets/status_chip.dart';

/// Lists the roles and how much each one is allowed to do.
class AdminRolesScreen extends ConsumerWidget {
  const AdminRolesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final roles = ref.watch(adminRolesProvider);

    return SingleChildScrollView(
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.rolesTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.rolesSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            roles.when(
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
                  onRetry: () => ref.invalidate(adminRolesProvider),
                );
              },
              data: (list) => Column(
                children: [
                  for (final role in list)
                    _RoleTile(key: Key('role-tile-${role.slug}'), role: role),
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

class _RoleTile extends StatelessWidget {
  const _RoleTile({super.key, required this.role});

  final ManagedRole role;

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
          title: Text(role.name),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (role.description != null)
                  Text(role.description!, style: theme.textTheme.bodySmall),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    StatusChip(
                      label: l10n.rolePermissionCount(role.permissions.length),
                      tone: StatusTone.info,
                    ),
                    if (role.userCount != null)
                      StatusChip(label: l10n.roleMembers(role.userCount!)),
                    if (!role.isEditable)
                      StatusChip(
                        label: l10n.roleFixed,
                        tone: StatusTone.warning,
                      ),
                  ],
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go(RoutePaths.adminRolePermissions(role.id)),
        ),
      ),
    );
  }
}
