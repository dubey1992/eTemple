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
import '../data/media_providers.dart';
import '../domain/media_item.dart';
import 'media_formatting.dart';

/// Albums as the committee manages them.
///
/// The count shown here includes drafts, deliberately: an editor needs to know
/// how much of an album is still unfinished, where a visitor needs to know how
/// much there is to look at.
class AdminAlbumsScreen extends ConsumerWidget {
  const AdminAlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final albums = ref.watch(adminAlbumsProvider);
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
                        l10n.albumsAdminTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.albumsAdminSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  FilledButton.icon(
                    key: const Key('album-new'),
                    onPressed: () => context.go(RoutePaths.adminAlbumNew),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.albumNew),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            albums.when(
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
                  onRetry: () => ref.invalidate(adminAlbumsProvider),
                );
              },
              data: (data) => data.isEmpty
                  ? EmptyView(
                      key: const Key('admin-albums-empty'),
                      message: l10n.albumsEmpty,
                      icon: Icons.collections_bookmark_outlined,
                    )
                  : Column(
                      children: [
                        for (final album in data)
                          _AlbumRow(album: album, canEdit: canEdit),
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

class _AlbumRow extends StatelessWidget {
  const _AlbumRow({required this.album, required this.canEdit});

  final AdminAlbum album;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: Key('admin-album-${album.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(album.titleHi, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('/${album.slug}'),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: MediaFormatting.statusLabel(album.status, l10n),
                    tone: album.isPublished
                        ? StatusTone.positive
                        : StatusTone.neutral,
                  ),
                  StatusChip(
                    label: l10n.albumItemCount(album.mediaCount),
                    tone: StatusTone.info,
                  ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.go(RoutePaths.adminAlbumEditor(album.id)),
      ),
    );
  }
}
