import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../admin/data/admin_providers.dart';
import '../data/audit_providers.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_repository.dart';

/// Who did what, and when.
///
/// **Read only, and that is the whole screen.** There is no edit, no delete and
/// no download: the trail is append-only, and it carries donor names and
/// enquiry references, so a copy of it leaving as a spreadsheet would be a
/// personal-data leak with an official-sounding name (PHASE_11_PLAN S5).
///
/// Hiding the screen is a courtesy, never the access control — the server
/// refuses `audit.view` to everyone but the Super Admin regardless, which
/// `AuditTrailTest` proves by calling the endpoint directly.
class AdminAuditScreen extends ConsumerWidget {
  const AdminAuditScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // A courtesy, never the access control: the server refuses `audit.view`
    // to everyone but the Super Admin regardless.
    if (!ref.watch(canProvider(Permissions.auditView))) {
      return EmptyView(
        key: const Key('audit-unauthorized'),
        icon: Icons.lock_outline,
        message: l10n.stateUnauthorizedBody,
      );
    }

    final query = ref.watch(auditFilterProvider);
    final page = ref.watch(auditEntriesProvider(query));

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 1120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.auditTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.auditSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            const _Filters(),
            const SizedBox(height: AppSpacing.lg),

            page.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error is AppException
                    ? error
                    : const AppException.unknown(),
                onRetry: () => ref.invalidate(auditEntriesProvider(query)),
              ),
              data: (data) => data.entries.isEmpty
                  ? EmptyView(
                      key: const Key('audit-empty'),
                      icon: Icons.history,
                      message: l10n.auditEmpty,
                    )
                  : _Entries(page: data, query: query),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final query = ref.watch(auditFilterProvider);
    final actions = ref.watch(auditActionsProvider).value ?? const [];

    // A Card, and not only for looks: the filters sit above the page's own
    // scroll view rather than inside a Scaffold body, and a Material ancestor
    // is what a dropdown needs to draw its menu.
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: DropdownButtonFormField<String?>(
                key: const Key('audit-action-filter'),
                initialValue: query.action,
                isExpanded: true,
                decoration: InputDecoration(labelText: l10n.auditFilterAction),
                items: [
                  DropdownMenuItem(value: null, child: Text(l10n.filterAll)),
                  for (final action in actions)
                    DropdownMenuItem(
                      value: action.key,
                      child: Text(action.label),
                    ),
                ],
                onChanged: (value) =>
                    ref.read(auditFilterProvider.notifier).selectAction(value),
              ),
            ),
            if (query.action != null || query.from != null || query.to != null)
              TextButton.icon(
                key: const Key('audit-clear-filters'),
                onPressed: () => ref.read(auditFilterProvider.notifier).clear(),
                icon: const Icon(Icons.close, size: 18),
                label: Text(l10n.filterClear),
              ),
          ],
        ),
      ),
    );
  }
}

class _Entries extends StatelessWidget {
  const _Entries({required this.page, required this.query});

  final AuditPage page;
  final AuditQuery query;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text(
            l10n.auditEntryCount(page.total),
            key: const Key('audit-count'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final entry in page.entries) ...[
          _EntryCard(entry: entry),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (page.hasMore)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              // Deliberately not an infinite scroll: this is a record somebody
              // reads with a question in mind, and the answer is nearly always
              // reached by narrowing rather than by scrolling further.
              l10n.auditNarrowHint,
              key: const Key('audit-more'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class _EntryCard extends ConsumerWidget {
  const _EntryCard({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final isCompact = Breakpoints.of(context).isCompact;

    return Card(
      key: Key('audit-entry-${entry.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StatusChip(label: entry.actionLabel, tone: StatusTone.info),
                Text(
                  _when(entry.recordedAt, language),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Text(
              // The name copied onto the row, so an entry still says who took
              // the action after the account has gone.
              entry.actorName ?? l10n.auditUnknownActor,
              style: theme.textTheme.titleSmall,
            ),
            if (entry.entityLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  entry.entityLabel!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (entry.context != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  entry.context!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

            if (entry.hasDiff) ...[
              const SizedBox(height: AppSpacing.md),
              _Diff(entry: entry, isCompact: isCompact),
            ],

            if (entry.ipAddress != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${l10n.auditFrom}: ${entry.ipAddress}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _when(DateTime? at, String language) {
    if (at == null) return '—';

    return DateFormat.yMMMd(language).add_jm().format(at.toLocal());
  }
}

/// What changed, field by field.
///
/// Only the fields that changed reach the client at all — the server keeps the
/// diff, not the record — so this renders everything it was given.
class _Diff extends StatelessWidget {
  const _Diff({required this.entry, required this.isCompact});

  final AuditEntry entry;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final field in entry.changedFields) ...[
            Text(
              field,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            // Old above new on a phone, side by side on a desktop: a diff read
            // on one line is a diff nobody reads.
            // Nothing existed before — a record being created, not edited. A
            // column of em dashes beside it would read as though every field
            // had moved, so the "before" side is not drawn at all.
            if (entry.before.isEmpty)
              _Value(label: l10n.auditRecordedAs, value: entry.after[field])
            else if (isCompact)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Value(label: l10n.auditBefore, value: entry.before[field]),
                  const SizedBox(height: AppSpacing.xs),
                  _Value(label: l10n.auditAfter, value: entry.after[field]),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Value(
                      label: l10n.auditBefore,
                      value: entry.before[field],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _Value(
                      label: l10n.auditAfter,
                      value: entry.after[field],
                    ),
                  ),
                ],
              ),
            if (field != entry.changedFields.last)
              const Divider(height: AppSpacing.lg),
          ],
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value});

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            // An absent value is shown as an em dash rather than as the word
            // "null", which means nothing to a treasurer.
            text: value == null ? '—' : '$value',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
