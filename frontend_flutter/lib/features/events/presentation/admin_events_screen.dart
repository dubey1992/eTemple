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
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../content/data/content_providers.dart';
import '../data/event_providers.dart';
import '../domain/event.dart';
import 'event_formatting.dart';

/// The calendar as the administration sees it: everything, including drafts,
/// cancelled entries and events that have already happened.
///
/// A repeating event appears once — it is a rule, not a list of dates — which
/// is the point the committee needs to understand when they edit it.
class AdminEventsScreen extends ConsumerStatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  ConsumerState<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends ConsumerState<AdminEventsScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final events = ref.watch(adminEventsProvider(_status));
    final canEdit = ref
        .watch(permissionsProvider)
        .can(Permissions.eventsManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.eventsAdminTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.eventsAdminSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  FilledButton.icon(
                    key: const Key('event-new'),
                    onPressed: () => context.go(RoutePaths.adminEventNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.eventNew),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final status in <String?>[
                    null,
                    EventStatuses.published,
                    EventStatuses.draft,
                    EventStatuses.cancelled,
                  ])
                    ChoiceChip(
                      key: Key('event-filter-${status ?? 'all'}'),
                      label: Text(
                        status == null
                            ? l10n.filterAll
                            : EventFormatting.statusLabel(status, l10n),
                      ),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            events.when(
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
                  onRetry: () => ref.invalidate(adminEventsProvider(_status)),
                );
              },
              data: (data) => data.isEmpty
                  ? EmptyView(
                      key: const Key('admin-events-empty'),
                      message: l10n.eventsEmpty,
                      icon: Icons.event_outlined,
                    )
                  : Column(
                      children: [
                        for (final event in data)
                          _EventRow(event: event, canEdit: canEdit),
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

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.event, required this.canEdit});

  final AdminEvent event;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);

    final repeats = EventFormatting.repeats(
      event.recurrence,
      event.recurrenceDays,
      l10n,
    );

    return Card(
      key: Key('admin-event-${event.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(event.titleHi, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${EventFormatting.date(event.startAt, language)}'
                ' · ${EventFormatting.time(event.startAt, language)}',
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: EventFormatting.typeLabel(event.eventType, l10n),
                    tone: StatusTone.info,
                  ),
                  StatusChip(
                    label: EventFormatting.statusLabel(event.status, l10n),
                    tone: switch (event.status) {
                      EventStatuses.published => StatusTone.positive,
                      EventStatuses.cancelled => StatusTone.danger,
                      _ => StatusTone.neutral,
                    },
                  ),
                  if (repeats != null)
                    StatusChip(
                      key: Key('admin-event-repeats-${event.id}'),
                      label: repeats,
                      tone: StatusTone.warning,
                    ),
                  if (event.isFeatured)
                    StatusChip(
                      label: l10n.fieldFeatured,
                      tone: StatusTone.info,
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.go(RoutePaths.adminEventEditor(event.id)),
      ),
    );
  }
}
