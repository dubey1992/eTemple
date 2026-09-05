import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/reports_providers.dart';
import '../domain/report.dart';

/// The report catalogue.
///
/// **Only what this account may actually run.** The server filters the list, so
/// the console never offers a door that will not open — the same courtesy the
/// admin menu extends, and, as there, never the access control.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final catalogue = ref.watch(reportCatalogueProvider);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.reportsTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.reportsSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            catalogue.when(
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
                  onRetry: () => ref.invalidate(reportCatalogueProvider),
                );
              },
              data: (data) => data.reports.isEmpty
                  ? EmptyView(
                      key: const Key('reports-empty'),
                      message: l10n.reportsEmpty,
                      icon: Icons.insert_chart_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final report in data.reports)
                          _ReportRow(report: report),

                        const SizedBox(height: AppSpacing.md),
                        // Said once here rather than on every report: a Viewer
                        // needs to know why the buttons are missing before they
                        // open one and wonder.
                        if (!data.mayExport)
                          Text(
                            l10n.reportExportForbidden,
                            key: const Key('reports-no-export'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          )
                        else
                          Text(
                            l10n.reportExportLimit(data.exportLimit),
                            key: const Key('reports-export-limit'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
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

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report});

  final ReportListing report;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;

    return Card(
      key: Key('report-row-${report.key}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.go(RoutePaths.adminReport(report.key)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      report.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (report.hasPersonalColumns && isCompact) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: StatusChip(
                          label: l10n.reportHasPersonal,
                          tone: StatusTone.warning,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Flagged on the row so a committee member knows before opening
              // it that this is a report holding somebody's details. On a phone
              // the chip goes under the title rather than squeezing it: the
              // warning is worth reading, and so is the report's name.
              if (report.hasPersonalColumns && !isCompact) ...[
                const SizedBox(width: AppSpacing.sm),
                StatusChip(
                  label: l10n.reportHasPersonal,
                  tone: StatusTone.warning,
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
