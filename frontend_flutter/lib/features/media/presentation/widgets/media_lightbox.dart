import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/files/link_opener.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../domain/media_item.dart';
import 'media_image.dart';

/// The full-screen view of one gallery item.
///
/// Which image it asks for depends on the screen (assumption M11): a phone gets
/// the 1080-pixel `medium`, a desktop the 1920-pixel `large`. Sending a phone
/// the large one would be four times the bytes for a picture it cannot show at
/// that size, on the connection least able to afford it.
///
/// A video is not embedded. Playing it inline would mean putting a third-party
/// iframe on the temple's own origin, and the visitor is instead sent to the
/// provider in a new tab — a decision recorded in the phase report rather than
/// hidden here.
class MediaLightbox extends StatelessWidget {
  const MediaLightbox({super.key, required this.item, this.opener});

  final MediaItem item;

  /// Injectable so the "open on YouTube" path is testable off the browser.
  final LinkOpener? opener;

  static Future<void> show(BuildContext context, MediaItem item) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.86),
      builder: (context) => MediaLightbox(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;

    final imageUrl = item.isVideo
        ? item.thumbnailUrl
        : (isCompact ? item.mediumUrl : item.fullUrl);

    return Dialog(
      key: const Key('media-lightbox'),
      insetPadding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              key: const Key('lightbox-close'),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close, color: Colors.white),
              tooltip: l10n.actionClose,
            ),
          ),
          Flexible(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: imageUrl == null
                  ? const SizedBox.shrink()
                  : MediaImage(
                      url: imageUrl,
                      fit: BoxFit.contain,
                      loading: (_) => const Padding(
                        padding: EdgeInsets.all(AppSpacing.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_) => Padding(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Text(
                          l10n.imageUnavailable,
                          key: const Key('lightbox-broken'),
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (item.title.isNotEmpty)
            Text(
              item.title.value!,
              key: const Key('lightbox-title'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          if (item.caption.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.caption.value!,
              key: const Key('lightbox-caption'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.82),
              ),
            ),
          ],
          if (item.isVideo && item.externalUrl != null) ...[
            const SizedBox(height: AppSpacing.md),
            Center(
              child: FilledButton.icon(
                key: const Key('lightbox-watch'),
                onPressed: () =>
                    (opener ?? const LinkOpener()).open(item.externalUrl!),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(l10n.openInYoutube),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.videoDarshanNotice,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
