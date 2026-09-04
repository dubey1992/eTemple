import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/language_switch.dart';
import '../../../core/widgets/page_container.dart';
import '../../temple/data/temple_providers.dart';
import '../data/auth_providers.dart';

/// Completes the password reset started by the forgot-password e-mail.
///
/// The token and address arrive in the link's query string; the visitor only
/// chooses a password. This closes the flow Phase 0 opened.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  final String token;
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure = true;
  bool _submitting = false;
  bool _done = false;
  AppException? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .resetPassword(
            token: widget.token,
            email: widget.email,
            password: _password.text,
          );

      if (mounted) setState(() => _done = true);
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    // A link that lost its parameters cannot work; say so instead of showing a
    // form that is guaranteed to fail.
    final linkIsBroken = widget.token.isEmpty || widget.email.isEmpty;

    return Scaffold(
      appBar: AppBar(
        // The temple names its own sign-in page; the ARB string only
        // stands in while the profile is loading.
        title: Text(ref.watch(templeNameProvider) ?? l10n.appTitle),
        actions: const [
          LanguageSwitch(compact: true),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: PageContainer(
            maxWidth: 460,
            verticalPadding: AppSpacing.xl,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.resetPasswordTitle,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.resetPasswordSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (linkIsBroken)
                    _Notice(
                      key: const Key('reset-link-invalid'),
                      message: l10n.resetLinkInvalid,
                      isError: true,
                    )
                  else if (_done)
                    _Notice(
                      key: const Key('reset-done'),
                      message: l10n.resetPasswordDone,
                      isError: false,
                    )
                  else ...[
                    if (_error != null) ...[
                      _Notice(
                        key: const Key('reset-error'),
                        message:
                            _error!.firstErrorFor('token') ??
                            _error!.firstErrorFor('password') ??
                            _error!.localizedMessage(l10n),
                        isError: true,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    TextFormField(
                      key: const Key('reset-password'),
                      controller: _password,
                      obscureText: _obscure,
                      enabled: !_submitting,
                      decoration: InputDecoration(
                        labelText: l10n.fieldNewPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          tooltip: l10n.fieldNewPassword,
                        ),
                      ),
                      validator: (v) =>
                          Validators.password(v)?.localizedMessage(l10n),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    TextFormField(
                      key: const Key('reset-confirm'),
                      controller: _confirm,
                      obscureText: _obscure,
                      enabled: !_submitting,
                      decoration: InputDecoration(
                        labelText: l10n.fieldConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        final base = Validators.password(value)
                            ?.localizedMessage(l10n);
                        if (base != null) return base;
                        return value == _password.text
                            ? null
                            : l10n.passwordsDoNotMatch;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    FilledButton(
                      key: const Key('reset-submit'),
                      onPressed: _submitting ? null : _submit,
                      child: _submitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.actionSave),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.go(RoutePaths.login),
                    child: Text(l10n.backToLogin),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isError
        ? scheme.errorContainer
        : scheme.secondaryContainer;
    final foreground = isError
        ? scheme.onErrorContainer
        : scheme.onSecondaryContainer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
