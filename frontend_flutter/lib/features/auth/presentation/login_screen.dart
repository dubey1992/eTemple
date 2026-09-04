import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/language_switch.dart';
import '../../../core/widgets/page_container.dart';
import '../../temple/data/temple_providers.dart';
import 'auth_controller.dart';

/// Administration sign-in.
///
/// The screen holds only presentation state (in-flight flag, last error). The
/// credential check, session handling and error classification all happen in the
/// controller and repository.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _remember = false;
  bool _obscurePassword = true;
  bool _submitting = false;
  AppException? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text,
            password: _passwordController.text,
            remember: _remember,
          );

      if (mounted) context.go(RoutePaths.admin);
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
                  Text(l10n.loginTitle, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.loginSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  if (_error != null) ...[
                    _ErrorBanner(error: _error!),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  TextFormField(
                    key: const Key('login-email'),
                    controller: _emailController,
                    autofillHints: const [AutofillHints.username],
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    enabled: !_submitting,
                    decoration: InputDecoration(
                      labelText: l10n.emailLabel,
                      prefixIcon: const Icon(Icons.alternate_email),
                      // A server-reported field error takes precedence over the
                      // client rule, which is only an early convenience.
                      errorText: _error?.firstErrorFor('email'),
                    ),
                    validator: (value) =>
                        Validators.email(value)?.localizedMessage(l10n),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  TextFormField(
                    key: const Key('login-password'),
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.password],
                    obscureText: _obscurePassword,
                    enabled: !_submitting,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: l10n.passwordLabel,
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _error?.firstErrorFor('password'),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        tooltip: l10n.passwordLabel,
                      ),
                    ),
                    validator: (value) =>
                        Validators.password(value)?.localizedMessage(l10n),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  Row(
                    children: [
                      Checkbox(
                        value: _remember,
                        onChanged: _submitting
                            ? null
                            : (value) =>
                                  setState(() => _remember = value ?? false),
                      ),
                      Flexible(child: Text(l10n.rememberMe)),
                      const Spacer(),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => context.go(RoutePaths.forgotPassword),
                        child: Text(l10n.forgotPassword),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  FilledButton(
                    key: const Key('login-submit'),
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l10n.signIn),
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

/// Banner for a failed sign-in attempt.
///
/// Shows only the localized, user-safe message derived from the error code;
/// server text and technical detail are never rendered.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});

  final AppException error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarning = error.code == ErrorCode.tooManyRequests;
    final background = isWarning
        ? theme.colorScheme.tertiaryContainer
        : theme.colorScheme.errorContainer;
    final foreground = isWarning
        ? theme.colorScheme.onTertiaryContainer
        : theme.colorScheme.onErrorContainer;

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('login-error'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: foreground, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                error.localizedMessage(context.l10n),
                style: theme.textTheme.bodyMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
