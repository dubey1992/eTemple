import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/files/link_opener.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../accounts/domain/account.dart' show TransactionStatuses;
import '../../admin/presentation/widgets/status_chip.dart';
import '../../content/data/content_providers.dart';
import '../data/reports_providers.dart';
import '../domain/report.dart';
import '../domain/reports_repository.dart';

/// One report: its filters, its figures, its rows, and the three files.
///
/// The export buttons are built from the **same** [ReportQuery] the table was
/// drawn with, so the file cannot carry different filters from the screen
/// (PHASE_10_PLAN assumption N1). The screen states that in a sentence, because
/// a treasurer has no way to check it and should not have to take it on faith
/// silently.
class AdminReportScreen extends ConsumerWidget {
  const AdminReportScreen({super.key, required this.reportKey});

  final String reportKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final query =
        ref.watch(reportViewProvider)[reportKey] ?? ReportQuery(key: reportKey);
    final report = ref.watch(reportProvider(query));
    final catalogue = ref.watch(reportCatalogueProvider);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 1200,
        child: report.when(
          loading: () => const LoadingView(),
          error: (error, _) {
            final exception = error is AppException
                ? error
                : const AppException.unknown();

            if (exception.code == ErrorCode.forbidden ||
                exception.code == ErrorCode.reportDisclosureRefused) {
              return const UnauthorizedView();
            }

            return ErrorView(
              error: exception,
              onRetry: () => ref.invalidate(reportProvider(query)),
            );
          },
          data: (data) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(data.title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                data.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _Filters(query: query, data: data),
              const SizedBox(height: AppSpacing.lg),

              if (data.summary.isNotEmpty) ...[
                _Figures(figures: data.summary),
                const SizedBox(height: AppSpacing.lg),
              ],

              // The disclosure switch, and only when there is something to
              // disclose and this account may do it.
              if (data.hasPersonalColumns)
                _PersonalSwitch(
                  query: query,
                  data: data,
                  mayToggle:
                      catalogue.value?.reports
                          .where((r) => r.key == reportKey)
                          .firstOrNull
                          ?.maySeePersonal ??
                      false,
                ),

              const SizedBox(height: AppSpacing.md),
              _ExportBar(
                query: query,
                mayExport: catalogue.value?.mayExport ?? false,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (data.filters.isNotEmpty) ...[
                Text(
                  l10n.reportFiltersApplied(data.filters.join(' · ')),
                  key: const Key('report-filters-applied'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              if (data.isEmpty)
                EmptyView(
                  key: const Key('report-empty'),
                  message: l10n.reportEmpty,
                  icon: Icons.insert_chart_outlined,
                )
              else
                _Table(data: data),

              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.reportRowCount(data.total),
                key: const Key('report-row-count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
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

/// The period, and the status filter where the report has one.
class _Filters extends ConsumerWidget {
  const _Filters({required this.query, required this.data});

  final ReportQuery query;
  final ReportData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(reportViewProvider.notifier);
    final now = DateTime.now();

    // April to March: the year a committee's own accounts already use.
    final currentYear = now.month >= 4 ? now.year : now.year - 1;
    final years = [for (var y = currentYear; y > currentYear - 5; y--) y];

    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(l10n.reportFilterYear),
          for (final year in years)
            ChoiceChip(
              key: Key('report-year-$year'),
              label: Text('$year–${(year + 1) % 100}'),
              selected: (query.year ?? currentYear) == year,
              onSelected: (_) => controller.update(
                query.copyWith(year: year, clearDates: true),
              ),
            ),

          // A status filter only where the report's rows have one.
          if (data.columns.any((c) => c.key == 'status')) ...[
            const SizedBox(width: AppSpacing.md),
            for (final status in <String?>[
              null,
              TransactionStatuses.pending,
              TransactionStatuses.approved,
            ])
              if (data.key == 'ledger')
                ChoiceChip(
                  key: Key('report-status-${status ?? 'all'}'),
                  label: Text(status ?? l10n.accountsAllStatuses),
                  selected: query.status == status,
                  onSelected: (_) =>
                      controller.update(query.copyWith(status: status)),
                ),
          ],
        ],
      ),
    );
  }
}

class _Figures extends StatelessWidget {
  const _Figures({required this.figures});

  final List<ReportFigure> figures;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.md,
          children: [
            for (final figure in figures)
              Column(
                key: Key('report-figure-${figure.key}'),
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    figure.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(figure.display, style: theme.textTheme.titleMedium),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The disclosure control, on the screen as well as in the API.
class _PersonalSwitch extends ConsumerWidget {
  const _PersonalSwitch({
    required this.query,
    required this.data,
    required this.mayToggle,
  });

  final ReportQuery query;
  final ReportData data;
  final bool mayToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('report-include-personal'),
              contentPadding: EdgeInsets.zero,
              value: data.includesPersonal,
              // Disabled rather than hidden: an account that may not do this
              // should still see that the report has more in it, so they can
              // ask somebody who may.
              onChanged: mayToggle
                  ? (value) => ref
                        .read(reportViewProvider.notifier)
                        .update(query.copyWith(includePersonal: value))
                  : null,
              title: Text(l10n.reportIncludePersonal),
              subtitle: Text(l10n.reportIncludePersonalHelp),
            ),
            if (data.includesPersonal)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: StatusChip(
                  key: const Key('report-personal-chip'),
                  label: l10n.reportPersonalIncluded,
                  tone: StatusTone.warning,
                ),
              ),
            if (!mayToggle)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.errorReportDisclosureRefused,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The three files.
class _ExportBar extends ConsumerWidget {
  const _ExportBar({required this.query, required this.mayExport});

  final ReportQuery query;
  final bool mayExport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (!mayExport) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(
          l10n.reportExportForbidden,
          key: const Key('report-no-export'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    void download(String format) {
      final language = ref.read(contentLanguageProvider);
      const opener = LinkOpener();
      // `openOwn`, not `open`: stripping the Referer would leave the API with
      // no way to see that the request came from this signed-in app.
      opener.openOwn(
        ref
            .read(reportsRepositoryProvider)
            .exportUrl(query, format: format, language: language),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(l10n.reportExport, style: theme.textTheme.labelLarge),
            OutlinedButton.icon(
              key: const Key('report-export-csv'),
              onPressed: () => download('csv'),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: Text(l10n.reportExportCsv),
            ),
            OutlinedButton.icon(
              key: const Key('report-export-xlsx'),
              onPressed: () => download('xlsx'),
              icon: const Icon(Icons.grid_on_outlined, size: 18),
              label: Text(l10n.reportExportXlsx),
            ),
            OutlinedButton.icon(
              key: const Key('report-export-pdf'),
              onPressed: () => download('pdf'),
              icon: const Icon(Icons.print_outlined, size: 18),
              label: Text(l10n.reportExportPdf),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // The guarantee, said out loud. A treasurer cannot verify it and should
        // not have to wonder.
        Text(
          l10n.reportExportNote,
          key: const Key('report-export-note'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The rows.
///
/// Horizontally scrollable in its own box: a report can be ten columns wide and
/// the page must never scroll sideways as a whole.
class _Table extends StatelessWidget {
  const _Table({required this.data});

  final ReportData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          key: const Key('report-table'),
          headingTextStyle: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          columns: [
            for (final column in data.columns)
              DataColumn(label: Text(column.label), numeric: column.isNumeric),
          ],
          rows: [
            for (final row in data.rows)
              DataRow(
                cells: [
                  for (final column in data.columns)
                    DataCell(Text(row[column.key]?.display ?? '—')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
