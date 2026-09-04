import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';
import '../domain/admin_models.dart';

/// The permission matrix for one role.
///
/// Super Admin renders read-only: its set is fixed on the server so that no
/// edit here can leave the temple without an administrator.
class AdminRolePermissionsScreen extends ConsumerWidget {
  const AdminRolePermissionsScreen({super.key, required this.roleId});

  final int roleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(adminRolesProvider);
    final catalogue = ref.watch(permissionCatalogueProvider);

    Widget failure(Object error, VoidCallback retry) {
      final exception = error is AppException
          ? error
          : const AppException.unknown();
      if (exception.code == ErrorCode.forbidden) {
        return const UnauthorizedView();
      }
      return ErrorView(error: exception, onRetry: retry);
    }

    return roles.when(
      loading: () => const LoadingView(),
      error: (e, _) => failure(e, () => ref.invalidate(adminRolesProvider)),
      data: (list) {
        final role = list.where((r) => r.id == roleId).firstOrNull;
        if (role == null) return const EmptyView();

        return catalogue.when(
          loading: () => const LoadingView(),
          error: (e, _) =>
              failure(e, () => ref.invalidate(permissionCatalogueProvider)),
          data: (data) => _MatrixForm(
            key: ValueKey('${role.id}-${role.permissions.length}'),
            role: role,
            catalogue: data,
          ),
        );
      },
    );
  }
}

class _MatrixForm extends ConsumerStatefulWidget {
  const _MatrixForm({super.key, required this.role, required this.catalogue});

  final ManagedRole role;
  final PermissionCatalogue catalogue;

  @override
  ConsumerState<_MatrixForm> createState() => _MatrixFormState();
}

class _MatrixFormState extends ConsumerState<_MatrixForm> {
  late Set<String> _selected;
  bool _saving = false;
  AppException? _error;

  /// The phases delivered so far. Keys beyond this are grantable but not yet
  /// enforced anywhere, and the UI says so instead of implying otherwise.
  static const int _deliveredThroughPhase = 2;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.role.permissions};
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(adminRepositoryProvider)
          .updateRolePermissions(widget.role.id, _selected);

      ref.invalidate(adminRolesProvider);
      // Changing a role changes what its members may do, including possibly the
      // person doing the editing, so the session is re-read rather than trusted.
      await ref.read(authControllerProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.permissionsSaved)));
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // Watched, not read: the session (and therefore the permissions) resolves
    // after the first frame, and a read would leave the form permanently
    // read-only for a user who is in fact allowed to edit it.
    final editable =
        widget.role.isEditable &&
        ref.watch(permissionsProvider).can(Permissions.rolesManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 860,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.role.name, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.rolePermissionsTitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            if (!widget.role.isEditable) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                key: const Key('role-fixed-notice'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: theme.colorScheme.onTertiaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.roleFixed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                key: const Key('matrix-error'),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  _error!.firstErrorFor('permissions') ??
                      _error!.localizedMessage(l10n),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            for (final module in widget.catalogue.modules)
              _ModuleCard(
                key: Key('module-${module.module}'),
                module: module,
                selected: _selected,
                enabled: editable && !_saving,
                pending: module.phase > _deliveredThroughPhase,
                onChanged: (key, value) => setState(() {
                  value ? _selected.add(key) : _selected.remove(key);
                }),
              ),

            if (editable) ...[
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('matrix-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.actionSave),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.go(RoutePaths.adminRoles),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    super.key,
    required this.module,
    required this.selected,
    required this.enabled,
    required this.pending,
    required this.onChanged,
  });

  final PermissionModule module;
  final Set<String> selected;
  final bool enabled;
  final bool pending;
  final void Function(String key, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      module.label,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (pending)
                    Text(
                      l10n.modulePhasePending(module.phase),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              for (final permission in module.permissions)
                CheckboxListTile(
                  key: Key('perm-${permission.key}'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: selected.contains(permission.key),
                  onChanged: enabled
                      ? (value) => onChanged(permission.key, value ?? false)
                      : null,
                  title: Text(permission.label),
                  subtitle: Text(
                    permission.key,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
