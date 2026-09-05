import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/routing/route_paths.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../admin/presentation/widgets/status_chip.dart';
import '../../data/reports_providers.dart';
import '../../domain/report.dart';

/// The dashboard's at-a-glance figures.
///
/// Phase 8 §9 left the dashboard as a landing page and said Phase 10's figures
/// would go here; these are they.
///
/// **A panel this account may not see is absent, not empty.** The server omits
/// the block entirely, and so does this widget: an absent panel says "not
/// yours", an empty one says "the temple received nothing", and only one of
/// those is true.
///
/// A failure is silent for the same reason a missing panel is: the dashboard's
/// job is to open, and its cards below still work. The figures are a summary of
/// screens that each report their own errors.
class OverviewPanels extends ConsumerWidget {
  const OverviewPanels({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(overviewProvider);

    return overview.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (data) => _Panels(overview: data),
    );
  }
}

class _Panels extends StatelessWidget {
  const _Panels({required this.overview});

  final Overview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final money = overview.money;
    final trend = overview.trend;
    final events = overview.upcomingEvents;

    // Nothing to show at all — an account with reports.view and no module keys.
    if (money == null &&
        trend == null &&
        overview.enquiriesOpen == null &&
        events == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.overviewTitle,
                key: const Key('overview-title'),
                style: theme.textTheme.titleLarge,
              ),
            ),
            TextButton(
              key: const Key('overview-reports'),
              onPressed: () => context.go(RoutePaths.adminReports),
              child: Text(l10n.overviewOpenReports),
            ),
          ],
        ),
        Text(
          l10n.overviewYear(overview.financialYearLabel),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (money != null) ...[
          _MoneyRow(money: money),
          const SizedBox(height: AppSpacing.md),
        ],

        if (trend != null) ...[
          _TrendCard(trend: trend),
          const SizedBox(height: AppSpacing.md),
        ],

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (overview.enquiriesOpen != null)
              Expanded(
                child: _EnquiriesCard(
                  open: overview.enquiriesOpen!,
                  fresh: overview.enquiriesNew ?? 0,
                ),
              ),
            if (overview.enquiriesOpen != null && events != null)
              const SizedBox(width: AppSpacing.md),
            if (events != null) Expanded(child: _EventsCard(events: events)),
          ],
        ),
      ],
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.money});

  final OverviewMoney money;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: [
            _Figure(
              fieldKey: 'overview-donations',
              label: l10n.overviewDonations,
              value: money.donationsDisplay,
              note: l10n.overviewDonationCount(money.donationCount),
            ),
            _Figure(
              fieldKey: 'overview-income',
              label: l10n.overviewIncome,
              value: money.totalIncomeDisplay,
            ),
            _Figure(
              fieldKey: 'overview-expense',
              label: l10n.overviewExpense,
              value: money.totalExpenseDisplay,
            ),
            _Figure(
              fieldKey: 'overview-balance',
              label: l10n.overviewBalance,
              value: money.closingBalanceDisplay,
              strong: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.fieldKey,
    required this.label,
    required this.value,
    this.note,
    this.strong = false,
  });

  final String fieldKey;
  final String label;
  final String value;
  final String? note;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          key: Key(fieldKey),
          style: (strong
              ? theme.textTheme.titleLarge
              : theme.textTheme.titleMedium),
        ),
        if (note != null)
          Text(
            note!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}

/// Twelve months of donations, as twelve bars.
///
/// Drawn with sized boxes rather than a charting package: this project has
/// consistently not taken a dependency for something this small, and twelve
/// bars is a `Row` of `Container`s.
///
/// **Every month is present, including the empty ones.** A chart that omitted
/// them would compress the gap and show a steady trickle where there was a
/// festival and then silence.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final List<TrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final peak = trend.fold<int>(
      0,
      (a, p) => p.totalPaise > a ? p.totalPaise : a,
    );

    return Card(
      key: const Key('overview-trend'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.overviewTrend, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.md),

            if (peak == 0)
              Text(
                l10n.overviewTrendEmpty,
                key: const Key('overview-trend-empty'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              SizedBox(
                height: 132,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final point in trend)
                      Expanded(
                        child: Tooltip(
                          message: '${point.month} · ${point.display}',
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                // A month with nothing in it still draws a
                                // sliver, so the gap is visible as a gap.
                                height: peak == 0
                                    ? 2
                                    : 2 + (100 * point.totalPaise / peak),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: point.totalPaise == 0
                                      ? theme
                                            .colorScheme
                                            .surfaceContainerHighest
                                      : AppColors.gold,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                point.label,
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                                softWrap: false,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EnquiriesCard extends StatelessWidget {
  const _EnquiriesCard({required this.open, required this.fresh});

  final int open;
  final int fresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: const Key('overview-enquiries'),
      child: InkWell(
        onTap: () => context.go(RoutePaths.adminEnquiries),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.overviewEnquiries, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text('$open', style: theme.textTheme.headlineSmall),
              Text(
                l10n.overviewEnquiriesNew(fresh),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard({required this.events});

  final List<OverviewEvent> events;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: const Key('overview-events'),
      child: InkWell(
        onTap: () => context.go(RoutePaths.adminEvents),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.overviewUpcoming, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),

              if (events.isEmpty)
                Text(
                  l10n.overviewUpcomingEmpty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                for (final event in events)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          '${event.date} ${event.time}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            event.title,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        // Shown and flagged, never dropped: "the aarti is off
                        // on Tuesday" is what somebody opening this needs.
                        if (event.isCancelled) ...[
                          const SizedBox(width: AppSpacing.xs),
                          StatusChip(
                            label: l10n.overviewEventCancelled,
                            tone: StatusTone.danger,
                          ),
                        ],
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
