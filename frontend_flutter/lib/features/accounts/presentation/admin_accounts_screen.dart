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
import '../../../core/widgets/page_heading.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/accounts_providers.dart';
import '../domain/account.dart';
import '../domain/accounts_repository.dart';
import 'account_labels.dart';

/// The temple's books, as the committee sees them.
///
/// Two things are deliberate about the figures above the list:
///
///  * they are **approved money only**, the same rule the public page follows,
///    so the committee never quotes a number the website disagrees with;
///  * anything still to be checked is shown **as its own line, named as
///    pending**, rather than folded in. Money nobody has verified is not the
///    temple's money yet, and a total that quietly included it would be the
///    figure somebody read out at a meeting.
class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(ledgerProvider).search ?? '',
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
    final view = ref.watch(ledgerProvider);
    final list = ref.watch(transactionsProvider(view.query));
    final permissions = ref.watch(permissionsProvider);
    final canManage = permissions.can(Permissions.accountsManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 1100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeading(
              title: l10n.accountsTitle,
              subtitle: l10n.accountsSubtitle,
              actions: [
                IconButton(
                  key: const Key('accounts-categories'),
                  onPressed: () =>
                      context.go(RoutePaths.adminAccountingCategories),
                  icon: const Icon(Icons.label_outline),
                  tooltip: l10n.navAccountingCategories,
                ),
                IconButton(
                  key: const Key('accounts-settings'),
                  onPressed: () =>
                      context.go(RoutePaths.adminAccountingSettings),
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: l10n.navAccountingSettings,
                ),
                if (canManage)
                  FilledButton.icon(
                    key: const Key('accounts-new'),
                    onPressed: () => context.go(RoutePaths.adminAccountNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.accountsNewEntry),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            _SummaryPanel(query: view.query),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('accounts-search'),
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.accountsSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref.read(ledgerProvider.notifier).search(value);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.md),

            _Filters(view: view),
            const SizedBox(height: AppSpacing.lg),

            list.when(
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
                  onRetry: () =>
                      ref.invalidate(transactionsProvider(view.query)),
                );
              },
              data: (page) => page.transactions.isEmpty
                  ? EmptyView(
                      key: const Key('accounts-empty'),
                      message: view.status == null && view.search == null
                          ? l10n.accountsEmpty
                          : l10n.accountsEmptyFiltered,
                      icon: Icons.account_balance_wallet_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final transaction in page.transactions)
                          _TransactionRow(transaction: transaction),
                        if ((page.meta?.lastPage ?? 1) > 1) ...[
                          const SizedBox(height: AppSpacing.md),
                          _Pager(page: page),
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

/// Approved income, approved expenditure, and what is still to be checked.
class _SummaryPanel extends ConsumerWidget {
  const _SummaryPanel({required this.query});

  final TransactionQuery query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final summary = ref.watch(accountsSummaryProvider(query));

    return summary.maybeWhen(
      // A failed summary is not worth an error panel of its own: the register
      // below still loads, and its own error view will say what went wrong.
      orElse: () => const SizedBox.shrink(),
      data: (data) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.xl,
                runSpacing: AppSpacing.md,
                children: [
                  _Figure(
                    fieldKey: 'accounts-income',
                    label: l10n.accountsApprovedIncome,
                    value: AccountLabels.rupees(data.incomePaise),
                  ),
                  _Figure(
                    fieldKey: 'accounts-expense',
                    label: l10n.accountsApprovedExpense,
                    value: AccountLabels.rupees(data.expensePaise),
                  ),
                  _Figure(
                    fieldKey: 'accounts-net',
                    label: l10n.accountsNet,
                    value: AccountLabels.rupees(data.netPaise),
                  ),
                ],
              ),

              // The figures above are the **ledger's**. Donations are counted
              // from their own register, so "net" here is not the temple's
              // balance — and the public page, which adds them, will show a
              // different number. Said on the screen rather than left for
              // somebody to discover in a meeting (PHASE_9_PLAN assumption N1).
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      l10n.accountsDonationsElsewhere,
                      key: const Key('accounts-ledger-only-note'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              // Named as pending, never folded into the figures above.
              if (data.hasPending) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      Icons.pending_actions_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        l10n.accountsPendingNotCounted(data.pendingCount),
                        key: const Key('accounts-pending-note'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
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
  });

  final String fieldKey;
  final String label;
  final String value;

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
        Text(value, key: Key(fieldKey), style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class _Filters extends ConsumerWidget {
  const _Filters({required this.view});

  final LedgerView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(ledgerProvider.notifier);

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final type in <String?>[
            null,
            TransactionTypes.income,
            TransactionTypes.expense,
          ])
            ChoiceChip(
              key: Key('accounts-type-${type ?? 'all'}'),
              label: Text(
                type == null
                    ? l10n.accountsAllTypes
                    : AccountLabels.type(l10n, type),
              ),
              selected: view.type == type,
              onSelected: (_) => controller.selectType(type),
            ),
          const SizedBox(width: AppSpacing.md),
          for (final status in <String?>[
            null,
            TransactionStatuses.pending,
            TransactionStatuses.approved,
            TransactionStatuses.reversed,
          ])
            ChoiceChip(
              key: Key('accounts-status-${status ?? 'all'}'),
              label: Text(
                status == null
                    ? l10n.accountsAllStatuses
                    : AccountLabels.status(l10n, status),
              ),
              selected: view.status == status,
              onSelected: (_) => controller.selectStatus(status),
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;

    final tone = switch (transaction.status) {
      TransactionStatuses.approved => StatusTone.positive,
      TransactionStatuses.reversed => StatusTone.danger,
      _ => StatusTone.warning,
    };

    return Card(
      key: Key('accounts-row-${transaction.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.go(RoutePaths.adminAccountDetail(transaction.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    transaction.isIncome ? Icons.south_west : Icons.north_east,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      transaction.category?.nameFor(language) ??
                          AccountLabels.type(l10n, transaction.type),
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    // Formatted by the server: the paise are the authority and
                    // only one side of the wire divides by a hundred.
                    transaction.amountFormatted,
                    key: Key('accounts-amount-${transaction.id}'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusChip(
                    label: AccountLabels.status(l10n, transaction.status),
                    tone: tone,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Text(
                    AccountLabels.date(transaction.transactionDate, language),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (transaction.payeeName != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        '· ${transaction.payeeName}',
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  if (transaction.hasAttachment) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Icon(
                      Icons.attach_file,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.page});

  final TransactionPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final last = page.meta?.lastPage ?? 1;
    final current = page.meta?.currentPage ?? 1;
    final controller = ref.read(ledgerProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          key: const Key('accounts-page-previous'),
          onPressed: current > 1
              ? () => controller.goToPage(current - 1)
              : null,
          child: Text(l10n.actionPrevious),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(l10n.paginationPage(current, last)),
        ),
        TextButton(
          key: const Key('accounts-page-next'),
          onPressed: current < last
              ? () => controller.goToPage(current + 1)
              : null,
          child: Text(l10n.actionNext),
        ),
      ],
    );
  }
}
