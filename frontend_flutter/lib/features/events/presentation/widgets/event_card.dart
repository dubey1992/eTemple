import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/routing/route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../admin/presentation/widgets/status_chip.dart';
import '../../../content/data/content_providers.dart';
import '../../domain/event.dart';
import '../event_formatting.dart';

/// The public list of event occurrences.
///
/// Cards in a row are the same height, so a festival with a long description
/// does not leave the aarti beside it looking truncated.
class EventList extends StatelessWidget {
  const EventList({
    super.key,
    required this.occurrences,
    this.limit,
    required this.emptyMessage,
  });

  final List<EventOccurrence> occurrences;
  final int? limit;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (occurrences.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            emptyMessage,
            key: const Key('events-empty'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final shown = limit == null || limit! >= occurrences.length
        ? occurrences
        : occurrences.sublist(0, limit!);

    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 1,
      FormFactor.tablet => 2,
      FormFactor.desktop => 3,
    };

    final rows = <List<EventOccurrence>>[
      for (var i = 0; i < shown.length; i += columns)
        shown.sublist(i, (i + columns).clamp(0, shown.length)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: i < row.length
                        ? EventCard(occurrence: row[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          if (row != rows.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.occurrence});

  final EventOccurrence occurrence;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);

    return Card(
      key: Key('event-card-${occurrence.occurrenceKey}'),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: () => context.go(
          RoutePaths.eventDetail(occurrence.id, on: occurrence.occurrenceDate),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: EventFormatting.typeLabel(
                      occurrence.eventType,
                      l10n,
                    ),
                    tone: StatusTone.info,
                  ),
                  if (occurrence.isRecurring)
                    StatusChip(
                      label: EventFormatting.recurrenceLabel(
                        occurrence.recurrence,
                        l10n,
                      ),
                    ),
                  // A cancelled event is shown, not hidden: devotees who
                  // planned around it need to be told.
                  if (occurrence.isCancelled)
                    StatusChip(
                      key: Key('event-cancelled-${occurrence.occurrenceKey}'),
                      label: l10n.eventCancelled,
                      tone: StatusTone.danger,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                occurrence.title.orElse('—'),
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: occurrence.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 16,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      EventFormatting.when(occurrence, language),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              if (occurrence.venue.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        occurrence.venue.value!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
              if (occurrence.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  occurrence.description.value!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
