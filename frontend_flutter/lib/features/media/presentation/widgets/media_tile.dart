import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/media_item.dart';
import 'media_image.dart';

/// One photograph or video poster in a grid.
///
/// Memory-conscious by construction (PHASE_5_PLAN assumption M11):
///
/// * it asks the API for [MediaItem.previewUrl], the 480-pixel variant, so a
///   grid never downloads full-size photographs;
/// * it passes `cacheWidth`, so the **decoded** bitmap matches the size on
///   screen rather than the size of the file. Without it a 1920-pixel image in
///   a 300-pixel tile costs about 15 MB of RAM, and twenty of those on a phone
///   is the end of the page.
///
/// It also renders its own loading and failed states: a gallery on village
/// mobile data will meet both, and a blank grey square tells the reader
/// nothing.
class MediaTile extends StatelessWidget {
  const MediaTile({
    super.key,
    required this.item,
    this.onTap,
    this.fit = BoxFit.cover,
    this.showCaption = true,
  });

  final MediaItem item;
  final VoidCallback? onTap;
  final BoxFit fit;
  final bool showCaption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // The decode budget: the widest this tile can be, in device pixels.
        final logicalWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 480.0;
        final cacheWidth =
            (logicalWidth * MediaQuery.devicePixelRatioOf(context))
                .clamp(64, 1080)
                .round();

        return Material(
          color: AppColors.creamBand,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            key: Key('media-tile-${item.id}'),
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Preview(item: item, fit: fit, cacheWidth: cacheWidth),

                // A video is not obviously a video from its poster frame.
                if (item.isVideo)
                  Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                  ),

                if (showCaption && item.title.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC1A0A10)],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          item.title.value!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.item,
    required this.fit,
    required this.cacheWidth,
  });

  final MediaItem item;
  final BoxFit fit;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    final url = item.previewUrl;

    if (url == null) return const _TilePlaceholder(glyph: '🛕');

    return MediaImage(
      url: url,
      fit: fit,
      cacheWidth: cacheWidth,
      loading: (_) => const _TileLoading(),
      // A missing file must not take the whole gallery down; the tile says so
      // and the rest of the page carries on.
      error: (_) => const _TileBroken(),
    );
  }
}

class _TileLoading extends StatelessWidget {
  const _TileLoading();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: AppColors.creamBand,
    child: Center(
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}

class _TileBroken extends StatelessWidget {
  const _TileBroken();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.creamBand,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.imageUnavailable,
                key: const Key('media-tile-broken'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The prototype's gallery tile: a single glyph on the gold gradient.
///
/// Used for the empty gallery (assumption M12) and for a row with no image
/// at all.
class _TilePlaceholder extends StatelessWidget {
  const _TilePlaceholder({required this.glyph});

  final String glyph;

  @override
  Widget build(BuildContext context) => GalleryPlaceholderTile(glyph: glyph);
}

/// One of the prototype's five placeholder tiles.
///
/// The approved design shows emoji on a warm gradient under the words "photos …
/// will appear here", which *is* an empty state — so it is built as one rather
/// than faked with invented photographs in the database.
class GalleryPlaceholderTile extends StatelessWidget {
  const GalleryPlaceholderTile({
    super.key,
    required this.glyph,
    this.fontSize = 56,
  });

  final String glyph;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFD98D), Color(0xFFEF9A57)],
        ),
        boxShadow: AppColors.panelShadow,
      ),
      child: Center(
        child: Text(glyph, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
}
