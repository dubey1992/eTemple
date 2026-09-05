import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/page_container.dart';
import '../../data/announcement_providers.dart';
import '../../domain/announcement.dart';

/// The temple's current notice, across the top of the home page.
///
/// **One** notice, not a stack. A page whose top third is a pile of banners is
/// a page nobody reads, so the loudest currently-showing announcement gets the
/// space and the rest wait their turn (PHASE_8_PLAN assumption N9).
///
/// Which announcements are "currently showing" is never decided here. The
/// server filters by its own clock; if this widget did the filtering, the
/// schedule would be true on screen and false at the API, and anybody calling
/// the endpoint directly would read next week's news.
class AnnouncementBanner extends ConsumerWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcement = ref.watch(bannerAnnouncementProvider);

    // No notice, or one the visitor has closed. Nothing is rendered at all —
    // not an empty band, which would leave a gap above the hero.
    if (announcement == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final tone = _toneFor(announcement.priority, theme.colorScheme);

    final title = announcement.title.value;
    final message = announcement.message.value;
    if (title == null && message == null) return const SizedBox.shrink();

    return Material(
      key: const Key('announcement-banner'),
      color: tone.background,
      child: PageContainer(
        verticalPadding: AppSpacing.md,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tone.icon, color: tone.foreground, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: tone.foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  if (title != null && message != null)
                    const SizedBox(height: AppSpacing.xs),
                  if (message != null)
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tone.foreground,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              key: const Key('announcement-dismiss'),
              onPressed: () => ref
                  .read(dismissedAnnouncementsProvider.notifier)
                  .dismiss(announcement.id),
              icon: Icon(Icons.close, color: tone.foreground, size: 20),
              tooltip: l10n.announcementBannerDismiss,
            ),
          ],
        ),
      ),
    );
  }

  /// Priority decides how loud the band looks, and nothing else.
  ///
  /// Urgent borrows the error colours, which are the only ones in the scheme
  /// that a person reads as "stop and look" — a temple's colours are warm by
  /// design, and a cancellation has to escape them.
  static _BannerTone _toneFor(String priority, ColorScheme scheme) =>
      switch (priority) {
        AnnouncementPriorities.urgent => _BannerTone(
          background: scheme.errorContainer,
          foreground: scheme.onErrorContainer,
          icon: Icons.warning_amber_rounded,
        ),
        AnnouncementPriorities.important => _BannerTone(
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
          icon: Icons.campaign_outlined,
        ),
        _ => _BannerTone(
          background: scheme.surfaceContainerHighest,
          foreground: scheme.onSurfaceVariant,
          icon: Icons.info_outline,
        ),
      };
}

class _BannerTone {
  const _BannerTone({
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final IconData icon;
}
