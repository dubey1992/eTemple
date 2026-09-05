import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/data/content_providers.dart';
import '../../content/presentation/widgets/content_widgets.dart';
import '../data/accounts_providers.dart';
import '../domain/account.dart';
import 'account_labels.dart';

/// What the temple did with the money.
///
/// Aggregates only. There is no donor name, no supplier, no individual payment
/// on this page — and there is none in the response behind it either, which is
/// the half that matters (PHASE_9_PLAN assumptions N6 and N9).
///
/// When the committee has not published its books, this shows the temple's own
/// words saying so, rather than a column of zeros. Zeros would read as "the
/// temple received nothing", which is a false statement about somebody's
/// finances rather than a missing feature.
class TransparencyScreen extends ConsumerWidget {
  const TransparencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final accounts = ref.watch(transparencyProvider);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.transparencyTitle, style: theme.textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.transparencySubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            accounts.when(
              loading: () => const LoadingView(),
              error: (error, _) => ErrorView(
                error: error is AppException
                    ? error
                    : const AppException.unknown(),
                onRetry: () => ref.invalidate(transparencyProvider),
              ),
              data: (data) => data.isPublished
                  ? _PublishedAccounts(accounts: data)
                  : _NotPublished(accounts: data),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

/// The books are not open yet, and the page says so in the temple's words.
class _NotPublished extends StatelessWidget {
  const _NotPublished({required this.accounts});

  final Transparency accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return EmptyView(
      key: const Key('transparency-not-published'),
      icon: Icons.account_balance_outlined,
      // The committee's own introduction if it has written one; the standard
      // sentence otherwise. Either way this is an empty state, not an error.
      message: accounts.intro.value ?? l10n.transparencyNotPublishedBody,
    );
  }
}

class _PublishedAccounts extends ConsumerWidget {
  const _PublishedAccounts({required this.accounts});

  final Transparency accounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);
    final summary = accounts.summary;

    if (summary == null) {
      return EmptyView(
        key: const Key('transparency-empty'),
        message: l10n.transparencyEmptyYear,
        icon: Icons.account_balance_outlined,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (accounts.intro.isNotEmpty) ...[
          Text(
            accounts.intro.value!,
            key: const Key('transparency-intro'),
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        if (accounts.availableYears.length > 1) ...[
          _YearPicker(years: accounts.availableYears, selected: summary.year),
          const SizedBox(height: AppSpacing.lg),
        ],

        Text(
          l10n.transparencyYearHeading(summary.yearLabel),
          key: const Key('transparency-year'),
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),

        if (summary.isEmpty)
          EmptyView(
            key: const Key('transparency-empty-year'),
            message: l10n.transparencyEmptyYear,
            icon: Icons.account_balance_outlined,
          )
        else ...[
          _Figures(summary: summary, openingDate: accounts.openingBalanceDate),
          const SizedBox(height: AppSpacing.xl),

          _Breakdown(
            key: const Key('transparency-income-breakdown'),
            title: l10n.transparencyIncomeBreakdown,
            rows: summary.incomeByCategory,
            // Donations are the temple's largest income and are not a ledger
            // category: they are counted from their own register, so they are
            // shown here as their own line rather than left out of the picture.
            leading: (
              l10n.transparencyDonations,
              summary.donationsPaise,
              l10n.transparencyDonationCount(summary.donationCount),
            ),
            emptyMessage: l10n.transparencyNoIncome,
            language: language,
          ),
          const SizedBox(height: AppSpacing.lg),

          _Breakdown(
            key: const Key('transparency-expense-breakdown'),
            title: l10n.transparencyExpenseBreakdown,
            rows: summary.expenseByCategory,
            emptyMessage: l10n.transparencyNoExpense,
            language: language,
          ),
        ],

        const SizedBox(height: AppSpacing.xl),
        _Notes(summary: summary),
      ],
    );
  }
}

class _YearPicker extends ConsumerWidget {
  const _YearPicker({required this.years, required this.selected});

  final List<TransparencyYearOption> years;
  final int selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transparencySelectYear,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final year in years)
              ChoiceChip(
                key: Key('transparency-year-${year.year}'),
                label: Text(year.label),
                selected: year.year == selected,
                onSelected: (_) => ref
                    .read(transparencyYearProvider.notifier)
                    .select(year.year),
              ),
          ],
        ),
      ],
    );
  }
}

/// The five figures, in the order a person reads a set of accounts.
class _Figures extends StatelessWidget {
  const _Figures({required this.summary, this.openingDate});

  final TransparencyYear summary;
  final String? openingDate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FigureRow(
              fieldKey: 'transparency-opening',
              label: l10n.transparencyOpeningBalance,
              paise: summary.openingBalancePaise,
              note: openingDate == null
                  ? null
                  : l10n.transparencyOpeningBalanceOn(openingDate!),
            ),
            const Divider(height: AppSpacing.lg),

            _FigureRow(
              fieldKey: 'transparency-income',
              label: l10n.transparencyTotalIncome,
              paise: summary.totalIncomePaise,
              emphasis: true,
            ),
            const SizedBox(height: AppSpacing.xs),
            _FigureRow(
              fieldKey: 'transparency-expense',
              label: l10n.transparencyTotalExpense,
              paise: summary.totalExpensePaise,
              emphasis: true,
            ),

            const Divider(height: AppSpacing.lg),
            _FigureRow(
              fieldKey: 'transparency-closing',
              label: l10n.transparencyClosingBalance,
              paise: summary.closingBalancePaise,
              emphasis: true,
              strong: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({
    required this.fieldKey,
    required this.label,
    required this.paise,
    this.note,
    this.emphasis = false,
    this.strong = false,
  });

  final String fieldKey;
  final String label;
  final int paise;
  final String? note;
  final bool emphasis;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final labelStyle = strong
        ? theme.textTheme.titleMedium
        : theme.textTheme.bodyLarge;
    final valueStyle =
        (strong
                ? theme.textTheme.titleLarge
                : emphasis
                ? theme.textTheme.titleMedium
                : theme.textTheme.bodyLarge)
            ?.copyWith(fontWeight: FontWeight.w600);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              if (note != null)
                Text(
                  note!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          AccountLabels.rupees(paise),
          key: Key(fieldKey),
          style: valueStyle,
        ),
      ],
    );
  }
}

/// One side of the books, broken down by heading and largest first.
class _Breakdown extends StatelessWidget {
  const _Breakdown({
    super.key,
    required this.title,
    required this.rows,
    required this.emptyMessage,
    required this.language,
    this.leading,
  });

  final String title;
  final List<CategoryTotal> rows;
  final String emptyMessage;
  final String language;

  /// A line that is not a ledger category — donations, which come from their
  /// own register. `(label, paise, note)`.
  final (String, int, String)? leading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final head = leading;
    final showsNothing = rows.isEmpty && (head == null || head.$2 == 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        // The server resolved each heading's language and said whether it had
        // to fall back. The reader is told once, the same way the calendar and
        // the gallery tell them — never shown Hindi as though it were English.
        if (language == 'en' && rows.any((row) => row.name.fallbackUsed)) ...[
          const FallbackNotice(),
          const SizedBox(height: AppSpacing.sm),
        ],

        if (showsNothing)
          Text(
            emptyMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Column(
                children: [
                  if (head != null && head.$2 > 0)
                    _BreakdownRow(
                      label: head.$1,
                      note: head.$3,
                      paise: head.$2,
                    ),
                  for (final row in rows)
                    _BreakdownRow(
                      label: row.name.orElse(row.code),
                      paise: row.totalPaise,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.label, required this.paise, this.note});

  final String label;
  final int paise;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyLarge),
                if (note != null)
                  Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            AccountLabels.rupees(paise),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// The two sentences that tell a reader how to read the figures above.
///
/// They are on the page rather than in a help article because a total without
/// them invites the wrong conclusion: that everything the temple has been given
/// is in it, and that a name might be found behind one of these lines.
class _Notes extends StatelessWidget {
  const _Notes({required this.summary});

  final TransparencyYear summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.transparencyOnlyApprovedNote,
          key: const Key('transparency-approved-note'),
          style: style,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.transparencyNoNamesNote,
          key: const Key('transparency-names-note'),
          style: style,
        ),
        if (summary.asOf != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.transparencyAsOf(
              AccountLabels.timestamp(
                summary.asOf,
                Localizations.localeOf(context).languageCode,
              ),
            ),
            style: style,
          ),
        ],
      ],
    );
  }
}
