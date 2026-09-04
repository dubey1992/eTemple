import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/state_views.dart';
import '../data/admin_providers.dart';
import '../domain/admin_models.dart';
import 'widgets/status_chip.dart';

/// Recent sign-in attempts for one account, successful and failed.
///
/// Failures are shown deliberately: a run of failed attempts against an account
/// is the signal worth noticing.
class LoginHistoryView extends ConsumerWidget {
  const LoginHistoryView({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final history = ref.watch(loginHistoryProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.loginHistoryTitle, style: theme.textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),

        history.when(
          loading: () => const LoadingView(),
          error: (error, _) {
            final exception = error is AppException
                ? error
                : const AppException.unknown();

            // Login history needs its own permission, so a reader without it
            // sees the unauthorized state rather than an error.
            if (exception.code == ErrorCode.forbidden) {
              return const UnauthorizedView();
            }
            return ErrorView(
              error: exception,
              onRetry: () => ref.invalidate(loginHistoryProvider(userId)),
            );
          },
          data: (attempts) => attempts.isEmpty
              ? Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      l10n.loginHistoryEmpty,
                      key: const Key('login-history-empty'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : Card(
                  key: const Key('login-history-list'),
                  child: Column(
                    children: [
                      for (final attempt in attempts)
                        _AttemptRow(
                          key: Key('login-attempt-${attempt.id}'),
                          attempt: attempt,
                          isLast: attempt == attempts.last,
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _AttemptRow extends StatelessWidget {
  const _AttemptRow({super.key, required this.attempt, required this.isLast});

  final LoginAttempt attempt;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    final when = attempt.at == null
        ? '—'
        : DateFormat.yMMMd(locale).add_Hm().format(attempt.at!.toLocal());

    return Column(
      children: [
        ListTile(
          leading: Icon(
            attempt.successful
                ? Icons.check_circle_outline
                : Icons.error_outline,
            color: attempt.successful
                ? theme.colorScheme.secondary
                : theme.colorScheme.error,
          ),
          title: Text(when),
          subtitle: Text(
            attempt.ipAddress ?? '—',
            style: theme.textTheme.bodySmall,
          ),
          trailing: StatusChip(
            label: attempt.successful ? l10n.loginSuccess : l10n.loginFailed,
            tone: attempt.successful ? StatusTone.positive : StatusTone.danger,
          ),
        ),
        if (!isLast) const Divider(height: 1),
      ],
    );
  }
}
