import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';

/// How a chip should read at a glance.
enum StatusTone { neutral, positive, warning, info, danger }

/// A small labelled chip used across the admin screens.
///
/// The neutral and danger tones come from the colour scheme, so the admin area
/// followed two complete repaints — Marigold & Maroon to Rose & Peacock, and
/// Rose & Peacock to Maroon & Gold — without an edit here.
///
/// The other three are fixed tokens rather than scheme roles. Borrowing
/// `primaryContainer` and `secondaryContainer` made "published" and the event
/// type chip identical the moment the palette changed, because the seed
/// generator produced the same colour for both: a status has to stay legible
/// as a status, not follow whatever the brand happens to be.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    this.tone = StatusTone.neutral,
  });

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (background, foreground) = switch (tone) {
      StatusTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      StatusTone.positive => (
        AppColors.positiveSurface,
        AppColors.onPositiveSurface,
      ),
      StatusTone.warning => (
        AppColors.warningSurface,
        AppColors.onWarningSurface,
      ),
      StatusTone.info => (AppColors.infoSurface, AppColors.onInfoSurface),
      StatusTone.danger => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: foreground),
      ),
    );
  }
}
