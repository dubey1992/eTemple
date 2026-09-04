import 'package:flutter/material.dart';

import '../../app/localization/locale_controller.dart';
import '../../app/localization/message_translations.dart';
import '../../app/theme/app_spacing.dart';
import '../errors/app_exception.dart';
import '../errors/error_code.dart';

/// The four states every API-driven screen must be able to show.
///
/// Centralised so each phase renders loading, empty, error and unauthorized the
/// same way, and so the wording stays localized.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? context.l10n.stateLoading;

    return Semantics(
      liveRegion: true,
      label: text,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              Text(text, style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, this.message, this.icon = Icons.inbox_outlined});

  final String? message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _MessagePanel(icon: icon, title: message ?? context.l10n.stateEmpty);
  }
}

/// Renders an [AppException] as a user-safe, localized message.
///
/// The exception's technical detail is never shown; only the mapped message and
/// an optional retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});

  final AppException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _MessagePanel(
      icon: error.code == ErrorCode.network
          ? Icons.wifi_off_outlined
          : Icons.error_outline,
      title: error.localizedMessage(l10n),
      action: onRetry == null
          ? null
          : FilledButton.tonalIcon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.stateRetry),
            ),
    );
  }
}

class UnauthorizedView extends StatelessWidget {
  const UnauthorizedView({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return _MessagePanel(
      icon: Icons.lock_outline,
      title: l10n.stateUnauthorizedTitle,
      body: l10n.stateUnauthorizedBody,
      action: action,
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    required this.icon,
    required this.title,
    this.body,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
