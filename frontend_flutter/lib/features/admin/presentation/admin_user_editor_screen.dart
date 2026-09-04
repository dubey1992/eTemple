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
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/domain/auth_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/admin_providers.dart';
import '../domain/admin_models.dart';
import 'login_history_view.dart';

/// Creates or edits one committee account.
///
/// There is no password field by design: a new member sets their own password
/// through a mailed link, so a plaintext password never travels through the
/// committee. The server enforces the same rule.
class AdminUserEditorScreen extends ConsumerWidget {
  const AdminUserEditorScreen({super.key, this.userId});

  /// Null when creating a new account.
  final int? userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roles = ref.watch(adminRolesProvider);

    return roles.when(
      loading: () => const LoadingView(),
      error: (error, _) => _errorView(
        context,
        ref,
        error,
        () => ref.invalidate(adminRolesProvider),
      ),
      data: (roleList) {
        if (userId == null) {
          return _UserForm(roles: roleList);
        }

        final user = ref.watch(adminUserProvider(userId!));
        return user.when(
          loading: () => const LoadingView(),
          error: (error, _) => _errorView(
            context,
            ref,
            error,
            () => ref.invalidate(adminUserProvider(userId!)),
          ),
          data: (data) => _UserForm(
            key: ValueKey(data.id),
            roles: roleList,
            existing: data,
          ),
        );
      },
    );
  }

  Widget _errorView(
    BuildContext context,
    WidgetRef ref,
    Object error,
    VoidCallback retry,
  ) {
    final exception = error is AppException
        ? error
        : const AppException.unknown();

    if (exception.code == ErrorCode.forbidden) return const UnauthorizedView();

    return ErrorView(error: exception, onRetry: retry);
  }
}

class _UserForm extends ConsumerStatefulWidget {
  const _UserForm({super.key, required this.roles, this.existing});

  final List<ManagedRole> roles;
  final AdminUser? existing;

  @override
  ConsumerState<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<_UserForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _mobile;

  late int _roleId;
  late AccountStatus _status;

  bool _saving = false;
  AppException? _error;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _firstName = TextEditingController(text: existing?.firstName ?? '');
    _lastName = TextEditingController(text: existing?.lastName ?? '');
    _email = TextEditingController(text: existing?.email ?? '');
    _mobile = TextEditingController(text: existing?.mobile ?? '');

    _roleId = existing?.role?.id ?? widget.roles.last.id;
    _status = existing?.status ?? AccountStatus.active;
  }

  @override
  void dispose() {
    for (final c in [_firstName, _lastName, _email, _mobile]) {
      c.dispose();
    }
    super.dispose();
  }

  AdminUserDraft _draft() => AdminUserDraft(
    firstName: _firstName.text,
    lastName: _lastName.text,
    email: _email.text,
    mobile: _mobile.text,
    roleId: _roleId,
    status: _status,
  );

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(adminRepositoryProvider);
      final l10n = context.l10n;

      if (_isNew) {
        await repository.createUser(_draft());
        ref.invalidate(adminUsersProvider);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.userCreated)));
          context.go(RoutePaths.adminUsers);
        }
        return;
      }

      await repository.updateUser(widget.existing!.id, _draft());
      ref.invalidate(adminUsersProvider);
      ref.invalidate(adminUserProvider(widget.existing!.id));
      // The editor may have changed their own profile, and a role change
      // anywhere alters what the signed-in account may do, so re-read the
      // session rather than trusting the permissions already in memory.
      await ref.read(authControllerProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.saveSuccess)));
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _sendReset() async {
    final l10n = context.l10n;
    try {
      await ref
          .read(adminRepositoryProvider)
          .sendPasswordReset(widget.existing!.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.userResetSent)));
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canManage = ref.watch(canProvider(Permissions.usersManage));
    final canSeeHistory = ref.watch(canProvider(Permissions.securityView));

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? l10n.userNew : l10n.userEdit,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.userPasswordHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_error != null) ...[
                _ErrorBanner(error: _error!),
                const SizedBox(height: AppSpacing.md),
              ],

              _Field(
                fieldKey: const Key('user-first-name'),
                controller: _firstName,
                label: l10n.fieldFirstName,
                enabled: canManage && !_saving,
                serverError: _error?.firstErrorFor('first_name'),
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _Field(
                fieldKey: const Key('user-last-name'),
                controller: _lastName,
                label: '${l10n.fieldLastName} · ${l10n.fieldOptional}',
                enabled: canManage && !_saving,
                serverError: _error?.firstErrorFor('last_name'),
              ),
              _Field(
                fieldKey: const Key('user-email'),
                controller: _email,
                label: l10n.emailLabel,
                enabled: canManage && !_saving,
                keyboardType: TextInputType.emailAddress,
                serverError: _error?.firstErrorFor('email'),
                validator: (v) => Validators.email(v)?.localizedMessage(l10n),
              ),
              _Field(
                fieldKey: const Key('user-mobile'),
                controller: _mobile,
                label: '${l10n.fieldMobile} · ${l10n.fieldOptional}',
                enabled: canManage && !_saving,
                keyboardType: TextInputType.phone,
                serverError: _error?.firstErrorFor('mobile'),
              ),

              DropdownButtonFormField<int>(
                key: const Key('user-role'),
                initialValue: _roleId,
                decoration: InputDecoration(
                  labelText: l10n.fieldRole,
                  errorText: _error?.firstErrorFor('role_id'),
                ),
                items: [
                  for (final role in widget.roles)
                    DropdownMenuItem(value: role.id, child: Text(role.name)),
                ],
                onChanged: (canManage && !_saving)
                    ? (value) => setState(() => _roleId = value ?? _roleId)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<AccountStatus>(
                key: const Key('user-status'),
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: l10n.fieldStatus,
                  errorText: _error?.firstErrorFor('status'),
                ),
                items: [
                  DropdownMenuItem(
                    value: AccountStatus.active,
                    child: Text(l10n.statusActive),
                  ),
                  DropdownMenuItem(
                    value: AccountStatus.inactive,
                    child: Text(l10n.statusInactive),
                  ),
                  DropdownMenuItem(
                    value: AccountStatus.blocked,
                    child: Text(l10n.statusBlocked),
                  ),
                ],
                onChanged: (canManage && !_saving)
                    ? (value) => setState(() => _status = value ?? _status)
                    : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (canManage)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        key: const Key('user-save'),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(_isNew ? l10n.userCreate : l10n.actionSave),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => context.go(RoutePaths.adminUsers),
                      child: Text(l10n.actionCancel),
                    ),
                  ],
                ),

              if (!_isNew && canManage) ...[
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('user-send-reset'),
                  onPressed: _saving ? null : _sendReset,
                  icon: const Icon(Icons.mail_outline),
                  label: Text(l10n.userSendReset),
                ),
              ],

              if (!_isNew && canSeeHistory) ...[
                const SizedBox(height: AppSpacing.xxl),
                LoginHistoryView(userId: widget.existing!.id),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('user-error'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Text(
        // A guard refusal ("you cannot deactivate your own account") arrives as
        // a field error, so show the server's specific reason when there is one
        // rather than the generic "some information is invalid".
        error.firstErrorFor('status') ??
            error.firstErrorFor('role_id') ??
            error.localizedMessage(context.l10n),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.enabled,
    this.keyboardType,
    this.serverError,
    this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? serverError;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(labelText: label, errorText: serverError),
        validator: validator,
      ),
    );
  }
}
