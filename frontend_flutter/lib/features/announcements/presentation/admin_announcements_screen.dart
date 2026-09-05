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
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/announcement_providers.dart';
import '../domain/announcement.dart';
import '../domain/announcement_repository.dart';
import 'announcement_labels.dart';

/// The temple's notices, as the committee sees them.
///
/// Each row answers three questions at a glance: what it says, where it stands
/// right now — showing, waiting, finished — and whether it has been sent. The
/// third matters most, because it is the only one that cannot be changed.
class AdminAnnouncementsScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  ConsumerState<AdminAnnouncementsScreen> createState() =>
      _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState
    extends ConsumerState<AdminAnnouncementsScreen> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: ref.read(announcementListProvider).search ?? '',
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
    final view = ref.watch(announcementListProvider);
    final list = ref.watch(announcementsProvider(view.query));
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.announcementsManage);

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
                        l10n.announcementsTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.announcementsSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  FilledButton.icon(
                    key: const Key('announcement-new'),
                    onPressed: () =>
                        context.go(RoutePaths.adminAnnouncementNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.announcementNew),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            TextField(
              key: const Key('announcement-search'),
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.announcementSearchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (value) {
                ref.read(announcementListProvider.notifier).search(value);
                setState(() {});
              },
            ),
            const SizedBox(height: AppSpacing.md),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final status in <String?>[
                    null,
                    AnnouncementStatuses.draft,
                    AnnouncementStatuses.published,
                  ])
                    ChoiceChip(
                      key: Key('announcement-filter-${status ?? 'all'}'),
                      label: Text(
                        status == null
                            ? l10n.filterAll
                            : AnnouncementLabels.status(l10n, status),
                      ),
                      selected: view.status == status,
                      onSelected: (_) => ref
                          .read(announcementListProvider.notifier)
                          .selectStatus(status),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  // Archived notices are kept and reachable, not deleted.
                  FilterChip(
                    key: const Key('announcement-show-archived'),
                    label: Text(l10n.announcementShowArchived),
                    selected: view.includeArchived,
                    onSelected: (value) => ref
                        .read(announcementListProvider.notifier)
                        .showArchived(value),
                  ),
                ],
              ),
            ),
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
                      ref.invalidate(announcementsProvider(view.query)),
                );
              },
              data: (page) => page.announcements.isEmpty
                  ? EmptyView(
                      key: const Key('announcements-empty'),
                      message: l10n.announcementsEmpty,
                      icon: Icons.campaign_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final announcement in page.announcements)
                          _AnnouncementRow(announcement: announcement),
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

class _AnnouncementRow extends StatelessWidget {
  const _AnnouncementRow({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: Key('announcement-row-${announcement.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () =>
            context.go(RoutePaths.adminAnnouncementEditor(announcement.id)),
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
                      announcement.titleHi,
                      style: theme.textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (announcement.priority != AnnouncementPriorities.normal)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: StatusChip(
                        label: AnnouncementLabels.priority(
                          l10n,
                          announcement.priority,
                        ),
                        tone:
                            announcement.priority ==
                                AnnouncementPriorities.urgent
                            ? StatusTone.danger
                            : StatusTone.warning,
                      ),
                    ),
                  StatusChip(
                    label: AnnouncementLabels.state(
                      l10n,
                      announcement,
                      formatAnnouncementDate,
                    ),
                    tone: announcement.isShowing
                        ? StatusTone.positive
                        : StatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                announcement.messageHi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),

              // The one fact that cannot be changed, on the row rather than
              // buried in the editor.
              if (announcement.wasSent) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      Icons.send_outlined,
                      size: 15,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      announcement.sentAt == null
                          ? l10n.announcementSentNotice
                          : l10n.announcementSentOn(
                              formatAnnouncementDate(announcement.sentAt!),
                            ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

/// Day/month/year, which is how a date is written in Bihar.
///
/// Shared with the editor so the two screens never disagree about what a date
/// looks like.
String formatAnnouncementDate(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/'
      '${local.month.toString().padLeft(2, '0')}/${local.year}';
}

class _Pager extends ConsumerWidget {
  const _Pager({required this.page});

  final AnnouncementPage page;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final last = page.meta?.lastPage ?? 1;
    final current = page.currentPage;
    final controller = ref.read(announcementListProvider.notifier);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          key: const Key('announcement-page-previous'),
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
          key: const Key('announcement-page-next'),
          onPressed: current < last
              ? () => controller.goToPage(current + 1)
              : null,
          child: Text(l10n.actionNext),
        ),
      ],
    );
  }
}
