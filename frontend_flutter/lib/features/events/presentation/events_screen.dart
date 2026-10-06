import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/seo/seo_metadata_service.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/presentation/seo_scope.dart';
import '../../content/presentation/widgets/content_widgets.dart';
import '../../temple/data/temple_providers.dart';
import '../data/event_providers.dart';
import '../domain/event_repository.dart';
import 'widgets/event_card.dart';

/// The public calendar: what is on today, what is coming, and what has been.
///
/// The list is of dated *occurrences*, not stored rows — the daily aarti is one
/// record and appears here every day. That expansion is the server's, so the
/// two never disagree about which dates exist, and so is the division into the
/// three tabs: asking the server for `today` rather than filtering a list here
/// means the page cannot drift from the temple's own clock and timezone.
class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final view = ref.watch(eventViewProvider);
    final compact = Breakpoints.of(context).isCompact;
    final events = ref.watch(eventsProvider(EventQuery(view: view)));
    final templeName = ref.watch(templeNameProvider);

    return SeoScope(
      title: PageMetadata.compose(
        pageTitle: l10n.eventsTitle,
        siteName: templeName ?? l10n.appTitle,
      ),
      description: l10n.eventsSubtitle,
      canonicalPath: RoutePaths.events,
      child: SingleChildScrollView(
        child: PageContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.eventsTitle,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.eventsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Horizontally scrollable because three Hindi labels — आज,
              // आगामी, पूर्व कार्यक्रम — are wider than a phone, and a
              // SegmentedButton overflows rather than wrapping.
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<EventView>(
                  key: const Key('events-view-switch'),
                  // The icons go on the narrow layout: with three segments they
                  // cost more width than they explain.
                  showSelectedIcon: !compact,
                  segments: [
                    ButtonSegment(
                      value: EventView.today,
                      label: Text(l10n.viewToday),
                      icon: compact
                          ? null
                          : const Icon(Icons.today_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: EventView.afterToday,
                      label: Text(l10n.viewUpcoming),
                      icon: compact
                          ? null
                          : const Icon(Icons.upcoming_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: EventView.past,
                      label: Text(l10n.viewPast),
                      icon: compact
                          ? null
                          : const Icon(Icons.history, size: 18),
                    ),
                  ],
                  selected: {view},
                  onSelectionChanged: (selection) => ref
                      .read(eventViewProvider.notifier)
                      .select(selection.first),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              events.when(
                loading: () => const LoadingView(),
                error: (error, _) => ErrorView(
                  error: error is AppException
                      ? error
                      : const AppException.unknown(),
                  onRetry: () =>
                      ref.invalidate(eventsProvider(EventQuery(view: view))),
                ),
                data: (data) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data.any(
                      (o) => o.title.fallbackUsed || o.description.fallbackUsed,
                    )) ...[
                      const FallbackNotice(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    EventList(
                      occurrences: data,
                      emptyMessage: switch (view) {
                        EventView.today => l10n.noEventsToday,
                        EventView.past => l10n.noPastEvents,
                        _ => l10n.noUpcomingEvents,
                      },
                    ),

                    // Today is where the page opens, and at a village temple
                    // there are quiet days. Rather than leave the visitor on an
                    // empty page, point them at the next thing happening.
                    if (view == EventView.today && data.isEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FilledButton.tonalIcon(
                          key: const Key('events-see-upcoming'),
                          onPressed: () => ref
                              .read(eventViewProvider.notifier)
                              .select(EventView.afterToday),
                          icon: const Icon(Icons.upcoming_outlined, size: 18),
                          label: Text(l10n.seeUpcomingEvents),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
