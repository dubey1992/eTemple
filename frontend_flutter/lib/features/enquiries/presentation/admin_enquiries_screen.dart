import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/enquiry_providers.dart';
import '../domain/enquiry.dart';
import '../domain/enquiry_repository.dart';
import 'enquiry_labels.dart';

/// The committee's enquiry inbox.
///
/// Ordered by what still needs doing rather than by what arrived last: a
/// message from three weeks ago that nobody has answered is more urgent than
/// one from this morning that somebody already has. That order comes from the
/// server, so paging through the inbox cannot reshuffle it.
class AdminEnquiriesScreen extends ConsumerStatefulWidget {
  const AdminEnquiriesScreen({super.key});

  @override
  ConsumerState<AdminEnquiriesScreen> createState() =>
      _AdminEnquiriesScreenState();
}

class _AdminEnquiriesScreenState extends ConsumerState<AdminEnquiriesScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(enquiryInboxProvider).search ?? '',
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
    final view = ref.watch(enquiryInboxProvider);
    final inbox = ref.watch(enquiriesProvider(view.query));
    final summary = ref.watch(enquirySummaryProvider(view.query));

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 1000,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enquiryInboxTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.enquiryInboxSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('enquiry-search'),
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.enquirySearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        key: const Key('enquiry-search-clear'),
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          ref.read(enquiryInboxProvider.notifier).search(null);
                          setState(() {});
                        },
                      ),
              ),
              onSubmitted: (value) {
                ref.read(enquiryInboxProvider.notifier).search(value);
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
                  for (final status in <String?>[null, ...EnquiryStatuses.all])
                    ChoiceChip(
                      key: Key('enquiry-filter-${status ?? 'all'}'),
                      label: Text(
                        _chipLabel(
                          status,
                          summary.value ?? EnquirySummary.empty,
                          l10n,
                        ),
                      ),
                      selected: view.status == status,
                      onSelected: (_) => ref
                          .read(enquiryInboxProvider.notifier)
                          .selectStatus(status),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            inbox.when(
              loading: () => const LoadingView(),
              error: (error, _) {
                final exception = error is AppException
                    ? error
                    : const AppException.unknown();

                // The one screen in the admin console a Treasurer or a Viewer
                // is refused outright, so it must say so rather than looking
                // broken (PHASE_7_PLAN assumption N9).
                if (exception.code == ErrorCode.forbidden) {
                  return const UnauthorizedView();
                }
                return ErrorView(
                  error: exception,
                  onRetry: () => ref.invalidate(enquiriesProvider(view.query)),
                );
              },
              data: (page) => page.enquiries.isEmpty
                  ? EmptyView(
                      key: const Key('enquiries-empty'),
                      message: l10n.enquiryInboxEmpty,
                      icon: Icons.mark_email_unread_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final enquiry in page.enquiries)
                          _EnquiryRow(enquiry: enquiry),
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

  /// The tab label, with the count beside it where there is one to show.
  String _chipLabel(
    String? status,
    EnquirySummary summary,
    AppLocalizations l10n,
  ) {
    final label = status == null
        ? l10n.filterAll
        : EnquiryLabels.status(l10n, status);
    final count = summary.forStatus(status);

    return count == 0 ? label : '$label ($count)';
  }
}

/// One message in the list: enough to triage it without opening it.
class _EnquiryRow extends StatelessWidget {
  const _EnquiryRow({required this.enquiry});

  final Enquiry enquiry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: Key('enquiry-row-${enquiry.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () => context.go(RoutePaths.adminEnquiryDetail(enquiry.id)),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      enquiry.name,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  StatusChip(
                    label: EnquiryLabels.status(l10n, enquiry.status),
                    tone: switch (enquiry.status) {
                      EnquiryStatuses.isNew => StatusTone.info,
                      EnquiryStatuses.inProgress => StatusTone.warning,
                      EnquiryStatuses.resolved => StatusTone.positive,
                      _ => StatusTone.neutral,
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                enquiry.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    enquiry.reference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    EnquiryLabels.category(
                      l10n,
                      enquiry.category,
                      fallback: enquiry.categoryLabel,
                    ),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (enquiry.assignedToName != null)
                    Text(
                      '${l10n.enquiryAssignedTo}: ${enquiry.assignedToName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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
  const _Pager({required this.page, required this.view});

  final EnquiryPage page;
  final EnquiryInboxView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final last = page.meta?.lastPage ?? 1;
    final current = page.currentPage;
    final controller = ref.read(enquiryInboxProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          key: const Key('enquiry-page-previous'),
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
          key: const Key('enquiry-page-next'),
          onPressed: current < last
              ? () => controller.goToPage(current + 1)
              : null,
          child: Text(l10n.actionNext),
        ),
      ],
    );
  }
}
