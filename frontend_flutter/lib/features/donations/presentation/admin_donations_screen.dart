import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../content/data/content_providers.dart';
import '../data/donation_providers.dart';
import '../domain/donation.dart';
import 'donation_formatting.dart';

/// The donation register.
///
/// The totals across the top are the server's, computed over every donation
/// matching the filter. Adding up the rows in view would report the total of
/// one page as the total of everything, which for a temple's books is not a
/// rounding error but a wrong answer (PHASE_6_PLAN assumption N14).
class AdminDonationsScreen extends ConsumerStatefulWidget {
  const AdminDonationsScreen({super.key});

  @override
  ConsumerState<AdminDonationsScreen> createState() =>
      _AdminDonationsScreenState();
}

class _AdminDonationsScreenState extends ConsumerState<AdminDonationsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(donationRegisterProvider).search ?? '',
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final view = ref.watch(donationRegisterProvider);
    final register = ref.watch(donationsProvider(view.query));
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.donationsManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 1000,
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
                        l10n.donationsAdminTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.donationsAdminSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage) ...[
                  OutlinedButton.icon(
                    key: const Key('donation-settings-open'),
                    onPressed: () =>
                        context.go(RoutePaths.adminDonationSettings),
                    icon: const Icon(Icons.account_balance_outlined, size: 18),
                    label: Text(l10n.navDonationSettings),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    key: const Key('donation-new'),
                    onPressed: () => context.go(RoutePaths.adminDonationNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.donationNew),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _SummaryTiles(summary: register.value?.summary),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('donation-search'),
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.donationSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('donation-search-clear'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          ref
                              .read(donationRegisterProvider.notifier)
                              .search(null);
                          setState(() {});
                        },
                      ),
              ),
              onSubmitted: (value) {
                ref.read(donationRegisterProvider.notifier).search(value);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final status in <String?>[
                    null,
                    DonationStatuses.pending,
                    DonationStatuses.confirmed,
                    DonationStatuses.reversed,
                  ])
                    ChoiceChip(
                      key: Key('donation-filter-${status ?? 'all'}'),
                      label: Text(
                        status == null
                            ? l10n.filterAll
                            : DonationFormatting.statusLabel(status, l10n),
                      ),
                      selected: view.status == status,
                      onSelected: (_) => ref
                          .read(donationRegisterProvider.notifier)
                          .selectStatus(status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            register.when(
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
                  onRetry: () => ref.invalidate(donationsProvider(view.query)),
                );
              },
              data: (page) => page.donations.isEmpty
                  ? EmptyView(
                      key: const Key('donations-empty'),
                      message: l10n.donationsEmpty,
                      icon: Icons.volunteer_activism_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final donation in page.donations)
                          _DonationRow(donation: donation),
                        if ((page.meta?.lastPage ?? 1) > 1) ...[
                          const SizedBox(height: AppSpacing.md),
                          _Pager(page: page, view: view),
                        ],
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

/// The four figures the prototype's transparency block shows, over the register
/// rather than over the public site.
class _SummaryTiles extends StatelessWidget {
  const _SummaryTiles({required this.summary});

  final DonationSummary? summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final data = summary ?? DonationSummary.empty;

    final tiles = <(String, String, Key)>[
      (l10n.summaryReceived, data.totalFormatted, const Key('summary-total')),
      (
        l10n.summaryPending,
        data.pendingFormatted,
        const Key('summary-pending'),
      ),
      (l10n.summaryDonors, '${data.donorCount}', const Key('summary-donors')),
      (
        l10n.summaryReversed,
        '${data.reversedCount}',
        const Key('summary-reversed'),
      ),
    ];

    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 2,
      _ => 4,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.md;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value, key) in tiles)
              SizedBox(
                width: width,
                child: _StatTile(label: label, value: value, tileKey: key),
              ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.tileKey,
  });

  final String label;
  final String value;
  final Key tileKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      key: tileKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DonationRow extends ConsumerWidget {
  const _DonationRow({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);

    return Card(
      key: Key('donation-${donation.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                donation.donorName,
                style: theme.textTheme.titleMedium?.copyWith(
                  decoration: donation.isReversed
                      ? TextDecoration.lineThrough
                      : null,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              donation.amountFormatted,
              key: Key('donation-amount-${donation.id}'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: donation.isReversed
                    ? theme.colorScheme.onSurfaceVariant
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                decoration: donation.isReversed
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  DonationFormatting.date(donation.donationDate, language),
                  DonationFormatting.modeLabel(donation.paymentMode, l10n),
                  ?donation.receiptNumber,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: DonationFormatting.statusLabel(
                      donation.status,
                      l10n,
                    ),
                    tone: switch (donation.status) {
                      DonationStatuses.confirmed => StatusTone.positive,
                      DonationStatuses.reversed => StatusTone.danger,
                      _ => StatusTone.warning,
                    },
                  ),
                  StatusChip(
                    label: DonationFormatting.purposeLabel(
                      donation.purpose,
                      l10n,
                    ),
                    tone: StatusTone.info,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.go(RoutePaths.adminDonationDetail(donation.id)),
      ),
    );
  }
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.page, required this.view});

  final DonationPage page;
  final DonationRegisterView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final last = page.meta?.lastPage ?? 1;
    final current = page.currentPage;
    final controller = ref.read(donationRegisterProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          key: const Key('donations-previous'),
          onPressed: current > 1
              ? () => controller.goToPage(current - 1)
              : null,
          icon: const Icon(Icons.chevron_left, size: 18),
          label: Text(l10n.actionPrevious),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(l10n.paginationPage(current, last)),
        ),
        TextButton.icon(
          key: const Key('donations-next'),
          onPressed: current < last
              ? () => controller.goToPage(current + 1)
              : null,
          icon: const Icon(Icons.chevron_right, size: 18),
          label: Text(l10n.actionNext),
        ),
      ],
    );
  }
}
