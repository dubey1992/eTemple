import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/seo/page_metadata.dart';
import '../../../core/widgets/breakpoints.dart';
import '../../../core/widgets/state_views.dart';
import '../../content/presentation/seo_scope.dart';
import '../../temple/data/temple_providers.dart';
import '../data/media_providers.dart';
import '../domain/media_item.dart';
import 'widgets/gallery_mosaic.dart';
import 'widgets/media_lightbox.dart';
import 'widgets/media_tile.dart';

/// The public gallery: photographs of the temple, and the video darshan.
///
/// Built on slivers rather than a `SingleChildScrollView` so the grid is
/// genuinely lazy — tiles are constructed as they scroll into view, not all at
/// once (PHASE_5_PLAN assumption M11). A `shrinkWrap` grid inside a scroll view
/// would build every tile immediately and defeat the whole point.
class GalleryScreen extends ConsumerStatefulWidget {
  const GalleryScreen({super.key, this.album});

  /// From `/gallery?album=janmashtami-2026`, so a link to one album is
  /// shareable.
  final String? album;

  @override
  ConsumerState<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends ConsumerState<GalleryScreen> {
  @override
  void initState() {
    super.initState();

    // A shared link decides the *initial* filter and nothing after that: once
    // the visitor taps a chip the choice is theirs, and re-applying the URL on
    // every rebuild would take it back from them.
    //
    // After the first frame rather than during it: `initState` runs inside the
    // build phase, and changing provider state there is exactly what Riverpod
    // refuses.
    final album = widget.album;
    if (album != null && album.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(galleryViewProvider.notifier).selectAlbum(album);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final view = ref.watch(galleryViewProvider);
    final templeName = ref.watch(templeNameProvider);
    final albums = ref.watch(albumsProvider).value ?? const [];

    // Each page is its own request, cached separately, so "show more" costs one
    // call and a failed page can be retried without discarding the rest.
    final pages = [
      for (var page = 1; page <= view.pages; page++)
        ref.watch(galleryProvider(view.queryFor(page))),
    ];

    final items = [for (final page in pages) ...?page.value?.items];
    final isLoading = pages.any((page) => page.isLoading);
    final failure = pages
        .where((page) => page.hasError)
        .map((page) => page.error)
        .firstOrNull;
    final hasMore = pages.lastOrNull?.value?.hasMore ?? false;

    return SeoScope(
      title: PageMetadata.compose(
        pageTitle: l10n.galleryTitle,
        siteName: templeName ?? l10n.appTitle,
      ),
      description: l10n.gallerySubtitle,
      canonicalPath: RoutePaths.gallery,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = _horizontalPadding(context, constraints.maxWidth);
          final columns = switch (Breakpoints.of(context)) {
            FormFactor.mobile => 2,
            FormFactor.tablet => 3,
            FormFactor.desktop => 4,
          };

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.xl,
                  horizontal,
                  AppSpacing.lg,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.galleryTitle,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.gallerySubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),

                      SegmentedButton<String>(
                        key: const Key('gallery-type-switch'),
                        segments: [
                          ButtonSegment(
                            value: MediaTypes.photo,
                            label: Text(l10n.galleryPhotos),
                            icon: const Icon(
                              Icons.photo_library_outlined,
                              size: 18,
                            ),
                          ),
                          ButtonSegment(
                            value: MediaTypes.video,
                            label: Text(l10n.galleryVideos),
                            icon: const Icon(
                              Icons.smart_display_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                        selected: {view.type},
                        onSelectionChanged: (selection) => ref
                            .read(galleryViewProvider.notifier)
                            .selectType(selection.first),
                      ),

                      // The album filter appears only once there is more than
                      // one thing to choose between.
                      if (albums.isNotEmpty &&
                          view.type == MediaTypes.photo) ...[
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            ChoiceChip(
                              key: const Key('album-chip-all'),
                              label: Text(l10n.galleryAllAlbums),
                              selected: view.album == null,
                              onSelected: (_) => ref
                                  .read(galleryViewProvider.notifier)
                                  .selectAlbum(null),
                            ),
                            for (final album in albums)
                              ChoiceChip(
                                key: Key('album-chip-${album.slug}'),
                                label: Text(album.title.orElse(album.slug)),
                                selected: view.album == album.slug,
                                onSelected: (_) => ref
                                    .read(galleryViewProvider.notifier)
                                    .selectAlbum(album.slug),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (failure != null && items.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverToBoxAdapter(
                    child: ErrorView(
                      error: failure is AppException
                          ? failure
                          : const AppException.unknown(),
                      onRetry: () =>
                          ref.invalidate(galleryProvider(view.queryFor(1))),
                    ),
                  ),
                )
              else if (items.isEmpty && isLoading)
                const SliverToBoxAdapter(child: LoadingView())
              else if (items.isEmpty)
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverToBoxAdapter(
                    child: _GalleryEmpty(
                      isVideo: view.type == MediaTypes.video,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: horizontal),
                  sliver: SliverGrid.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 4 / 3,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => MediaTile(
                      item: items[index],
                      onTap: () => MediaLightbox.show(context, items[index]),
                    ),
                  ),
                ),

              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontal,
                  AppSpacing.lg,
                  horizontal,
                  AppSpacing.xxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: switch ((hasMore, isLoading)) {
                      (_, true) when items.isNotEmpty => const Padding(
                        padding: EdgeInsets.all(AppSpacing.md),
                        child: CircularProgressIndicator(),
                      ),
                      (true, _) => OutlinedButton.icon(
                        key: const Key('gallery-load-more'),
                        onPressed: () =>
                            ref.read(galleryViewProvider.notifier).showMore(),
                        icon: const Icon(Icons.expand_more),
                        label: Text(l10n.galleryLoadMore),
                      ),
                      _ => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Keeps the grid inside the same reading measure as every other page while
  /// letting the scroll view itself run full width.
  double _horizontalPadding(BuildContext context, double width) {
    const maxContent = 1120.0;
    final gutter = switch (Breakpoints.of(context)) {
      FormFactor.mobile => AppSpacing.pagePaddingMobile,
      FormFactor.tablet => AppSpacing.pagePaddingTablet,
      FormFactor.desktop => AppSpacing.pagePaddingDesktop,
    };

    if (!width.isFinite || width <= maxContent) return gutter;
    return (width - maxContent) / 2;
  }
}

/// Nothing published yet.
///
/// For photographs this is the prototype's own placeholder block, because the
/// approved design *is* an empty state: its caption says the photographs "will
/// appear here" (assumption M12).
class _GalleryEmpty extends StatelessWidget {
  const _GalleryEmpty({required this.isVideo});

  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (!isVideo) {
      return const GalleryPlaceholderMosaic();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.noVideos,
          key: const Key('gallery-no-videos'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }
}
