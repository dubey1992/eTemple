import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../app/localization/message_translations.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/media_providers.dart';
import '../domain/media_item.dart';
import 'media_formatting.dart';
import 'widgets/media_image.dart';

/// The media library: every photograph and video, including drafts.
///
/// Ordering is editable here rather than in the editor, because the order is a
/// property of the gallery as a whole and is only meaningful next to the items
/// it is being compared with.
class AdminMediaScreen extends ConsumerStatefulWidget {
  const AdminMediaScreen({super.key});

  @override
  ConsumerState<AdminMediaScreen> createState() => _AdminMediaScreenState();
}

class _AdminMediaScreenState extends ConsumerState<AdminMediaScreen> {
  String? _status;
  String? _type;
  bool _reordering = false;

  AdminMediaQuery get _query => AdminMediaQuery(status: _status, type: _type);

  Future<void> _move(List<AdminMedia> items, int index, int delta) async {
    final target = index + delta;
    if (target < 0 || target >= items.length) return;

    final ids = items.map((item) => item.id).toList();
    final moved = ids.removeAt(index);
    ids.insert(target, moved);

    setState(() => _reordering = true);
    try {
      // The whole arrangement is sent, not one move: a dropped request then
      // leaves the previous order intact rather than half of a new one.
      await ref.read(mediaRepositoryProvider).reorder(ids);
      ref.invalidate(adminMediaProvider(_query));

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.mediaOrderSaved)));
      }
    } on AppException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.localizedMessage(context.l10n))),
        );
      }
    } finally {
      if (mounted) setState(() => _reordering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final media = ref.watch(adminMediaProvider(_query));
    final canEdit = ref.watch(permissionsProvider).can(Permissions.mediaManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 900,
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
                        l10n.mediaAdminTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.mediaAdminSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit) ...[
                  OutlinedButton.icon(
                    key: const Key('albums-open'),
                    onPressed: () => context.go(RoutePaths.adminAlbums),
                    icon: const Icon(
                      Icons.collections_bookmark_outlined,
                      size: 18,
                    ),
                    label: Text(l10n.navAlbums),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton.icon(
                    key: const Key('media-new'),
                    onPressed: () => context.go(RoutePaths.adminMediaNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.mediaNew),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final status in <String?>[
                    null,
                    MediaStatuses.published,
                    MediaStatuses.draft,
                  ])
                    ChoiceChip(
                      key: Key('media-filter-${status ?? 'all'}'),
                      label: Text(
                        status == null
                            ? l10n.filterAll
                            : MediaFormatting.statusLabel(status, l10n),
                      ),
                      selected: _status == status,
                      onSelected: (_) => setState(() => _status = status),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  for (final type in <String?>[
                    MediaTypes.photo,
                    MediaTypes.video,
                  ])
                    ChoiceChip(
                      key: Key('media-type-filter-$type'),
                      label: Text(MediaFormatting.typeLabel(type!, l10n)),
                      selected: _type == type,
                      // Tapping the selected type clears it, so "both" needs no
                      // third chip.
                      onSelected: (selected) =>
                          setState(() => _type = selected ? type : null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            media.when(
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
                  onRetry: () => ref.invalidate(adminMediaProvider(_query)),
                );
              },
              data: (data) => data.isEmpty
                  ? EmptyView(
                      key: const Key('admin-media-empty'),
                      message: l10n.mediaEmpty,
                      icon: Icons.photo_library_outlined,
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < data.length; i++)
                          _MediaRow(
                            item: data[i],
                            canEdit: canEdit,
                            // Reordering only makes sense against an unfiltered
                            // list: moving an item "up" past rows the filter is
                            // hiding would produce an order nobody asked for.
                            canReorder:
                                canEdit &&
                                !_reordering &&
                                _status == null &&
                                _type == null,
                            isFirst: i == 0,
                            isLast: i == data.length - 1,
                            onMove: (delta) => _move(data, i, delta),
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

class _MediaRow extends StatelessWidget {
  const _MediaRow({
    required this.item,
    required this.canEdit,
    required this.canReorder,
    required this.isFirst,
    required this.isLast,
    required this.onMove,
  });

  final AdminMedia item;
  final bool canEdit;
  final bool canReorder;
  final bool isFirst;
  final bool isLast;
  final void Function(int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final dimensions = MediaFormatting.dimensions(item.width, item.height);

    return Card(
      key: Key('admin-media-${item.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: _Thumbnail(item: item),
        title: Text(item.titleHi, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  MediaFormatting.fileSize(item.byteSize),
                  ?dimensions,
                  ?item.originalName,
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
                    label: MediaFormatting.typeLabel(item.mediaType, l10n),
                    tone: StatusTone.info,
                  ),
                  StatusChip(
                    label: MediaFormatting.statusLabel(item.status, l10n),
                    tone: item.isPublished
                        ? StatusTone.positive
                        : StatusTone.neutral,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canReorder) ...[
              IconButton(
                key: Key('media-up-${item.id}'),
                onPressed: isFirst ? null : () => onMove(-1),
                icon: const Icon(Icons.arrow_upward),
                iconSize: 18,
                tooltip: l10n.mediaMoveUp,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                key: Key('media-down-${item.id}'),
                onPressed: isLast ? null : () => onMove(1),
                icon: const Icon(Icons.arrow_downward),
                iconSize: 18,
                tooltip: l10n.mediaMoveDown,
                visualDensity: VisualDensity.compact,
              ),
            ],
            Icon(
              canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        onTap: () => context.go(RoutePaths.adminMediaEditor(item.id)),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item});

  final AdminMedia item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = item.previewUrl;

    return SizedBox(
      width: 56,
      height: 56,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: url == null
            ? ColoredBox(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  item.isVideo
                      ? Icons.smart_display_outlined
                      : Icons.image_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : MediaImage(
                url: url,
                // 56 logical pixels at up to 3× — a library of eighty rows must
                // not decode eighty full-size bitmaps.
                cacheWidth: 168,
                error: (_) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
      ),
    );
  }
}
