import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/routing/route_paths.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../content/presentation/widgets/content_widgets.dart';
import '../../data/accounts_providers.dart';
import '../../domain/account.dart';
import '../account_labels.dart';

/// The four figures the approved design puts on the home page: what came in as
/// donations, what went out, what is left, and how many people gave.
///
/// The prototype prints `₹1,25,500` into the HTML. These come from the same
/// service as the `/transparency` page and the income & expenditure statement,
/// so the front page cannot disagree with the accounts behind it.
///
/// **Nothing is rendered at all** while the figures are loading, when the
/// committee has not published its books, or when the request fails. A band of
/// zeros on the front page would read as "the temple received nothing", which
/// is a false statement about somebody's finances rather than a missing
/// feature; and a red error box about the accounts is not what a devotee opened
/// the page for. The full page states all of this properly.
class TransparencyBand extends ConsumerWidget {
  const TransparencyBand({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final accounts = ref.watch(accountsForHomeProvider);

    final summary = accounts?.summary;
    if (summary == null || summary.isEmpty) return const SizedBox.shrink();

    return ContentSection(
      key: const Key('home-transparency'),
      title: l10n.homeAccountsTitle,
      subtitle: l10n.homeAccountsSubtitle,
      trailing: TextButton(
        key: const Key('transparency-see-all'),
        onPressed: () => context.go(RoutePaths.transparency),
        child: Text(l10n.viewTransparency),
      ),
      child: _Figures(summary: summary),
    );
  }
}

/// The published accounts, or null for every reason the band shows nothing.
///
/// A provider rather than a `when` inside the widget so "what makes this band
/// disappear" is one readable expression and can be tested on its own.
final accountsForHomeProvider = Provider<Transparency?>((ref) {
  final accounts = ref.watch(transparencyProvider).value;

  return (accounts != null && accounts.isPublished) ? accounts : null;
});

class _Figures extends StatelessWidget {
  const _Figures({required this.summary});

  final TransparencyYear summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final figures = <(String, String)>[
      (
        l10n.statDonationsReceived,
        AccountLabels.rupees(summary.donationsPaise),
      ),
      (l10n.statTotalExpense, AccountLabels.rupees(summary.totalExpensePaise)),
      (
        l10n.statAvailableBalance,
        AccountLabels.rupees(summary.closingBalancePaise),
      ),
      (l10n.statDonors, '${summary.donationCount}'),
    ];

    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 2,
      FormFactor.tablet => 2,
      FormFactor.desktop => 4,
    };

    final rows = <List<(String, String)>>[
      for (var i = 0; i < figures.length; i += columns)
        figures.sublist(i, (i + columns).clamp(0, figures.length)),
    ];

    return Column(
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
                        ? _FigureCard(label: row[i].$1, value: row[i].$2)
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

class _FigureCard extends StatelessWidget {
  const _FigureCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              child: Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
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
