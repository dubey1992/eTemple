import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/seo/seo_metadata_service.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../content/data/content_providers.dart';
import '../../content/presentation/seo_scope.dart';
import '../../content/presentation/widgets/content_widgets.dart';
import '../../shell/presentation/not_found_screen.dart';
import '../../temple/data/temple_providers.dart';
import '../data/event_providers.dart';
import '../domain/event.dart';
import 'event_formatting.dart';

/// One event, and when it happens next.
///
/// [on] names the occurrence the visitor arrived at, so a shared link to "the
/// aarti on the 12th" still opens on the 12th rather than on today.
class EventDetailScreen extends ConsumerWidget {
  const EventDetailScreen({super.key, required this.eventId, this.on});

  final int eventId;
  final String? on;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = EventDetailRequest(eventId, on: on);
    final detail = ref.watch(eventDetailProvider(request));

    return detail.when(
      loading: () => const LoadingView(),
      error: (error, _) {
        final exception = error is AppException
            ? error
            : const AppException.unknown();

        // A draft and an unknown id are indistinguishable by design, and both
        // mean "there is no such event" to a visitor.
        if (exception.isNotFound) return const NotFoundScreen();

        return ErrorView(
          error: exception,
          onRetry: () => ref.invalidate(eventDetailProvider(request)),
        );
      },
      data: (data) {
        final event = data.event;
        if (event == null) return const NotFoundScreen();

        return _EventBody(event: event, upcoming: data.occurrences);
      },
    );
  }
}

class _EventBody extends ConsumerWidget {
  const _EventBody({required this.event, required this.upcoming});

  final EventOccurrence event;
  final List<EventOccurrence> upcoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);
    final templeName = ref.watch(templeNameProvider);

    return SeoScope(
      title: PageMetadata.compose(
        pageTitle: event.title.value,
        siteName: templeName ?? l10n.appTitle,
      ),
      description: event.description.value ?? event.venue.value,
      canonicalPath: RoutePaths.eventDetail(event.id),
      child: SingleChildScrollView(
        child: PageContainer(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: EventFormatting.typeLabel(event.eventType, l10n),
                    tone: StatusTone.info,
                  ),
                  if (event.isRecurring)
                    StatusChip(
                      label: EventFormatting.recurrenceLabel(
                        event.recurrence,
                        l10n,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              Text(
                event.title.orElse('—'),
                key: const Key('event-title'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: event.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (event.isCancelled) ...[
                Container(
                  key: const Key('event-cancelled-notice'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.event_busy_outlined,
                        size: 20,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.eventCancelledNotice,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (event.title.fallbackUsed ||
                  event.description.fallbackUsed) ...[
                const FallbackNotice(),
                const SizedBox(height: AppSpacing.md),
              ],

              _DetailRow(
                icon: Icons.event_outlined,
                text: EventFormatting.when(event, language),
              ),
              if (event.venue.isNotEmpty)
                _DetailRow(
                  icon: Icons.place_outlined,
                  text: '${l10n.eventVenue}: ${event.venue.value}',
                ),

              if (event.description.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                ContentBody(content: event.description),
              ],

              // Only useful for a repeating event: for a one-off this list is
              // just the date already shown above.
              if (event.isRecurring && upcoming.length > 1) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  l10n.eventUpcomingDates,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final occurrence in upcoming.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      EventFormatting.when(occurrence, language),
                      key: Key('event-occurrence-${occurrence.occurrenceKey}'),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
              ],

              const SizedBox(height: AppSpacing.xl),
              TextButton.icon(
                key: const Key('event-back'),
                onPressed: () => context.go(RoutePaths.events),
                icon: const Icon(Icons.arrow_back, size: 18),
                label: Text(l10n.eventsTitle),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
  }
}
