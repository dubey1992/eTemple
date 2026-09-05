import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../domain/content_highlight.dart';
import '../../domain/localized_value.dart';

/// Shown when the visitor asked for English but the committee has only written
/// the Hindi version.
///
/// The specification allows the Hindi fallback but requires it to be a *clear*
/// rule — so it is stated, once per page, rather than left to look like a
/// translation failure.
class FallbackNotice extends StatelessWidget {
  const FallbackNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: Container(
        key: const Key('fallback-notice'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          children: [
            Icon(
              Icons.translate,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                context.l10n.fallbackNotice,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders CMS body text.
///
/// Content is stored as plain text (PHASE_1_PLAN assumption B6), so this splits
/// on blank lines rather than parsing markup — which also means nothing an
/// editor types can inject HTML into the page.
class ContentBody extends StatelessWidget {
  const ContentBody({super.key, required this.content, this.emptyMessage});

  final LocalizedValue content;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paragraphs = content.paragraphs;

    if (paragraphs.isEmpty) {
      return Text(
        emptyMessage ?? context.l10n.contentComingSoon,
        key: const Key('content-empty'),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs) ...[
          Text(paragraph, style: theme.textTheme.bodyLarge),
          if (paragraph != paragraphs.last)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

/// A titled section on the public site.
class ContentSection extends StatelessWidget {
  const ContentSection({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final Widget child;

  /// The line under the heading. The prototype gives most sections one; it is
  /// optional here because several sections in this app have nothing to add to
  /// their own title.
  final String? subtitle;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // The heading's own action — "see all photographs" — has to give
            // way on a phone, where the title needs the whole width.
            if (!Breakpoints.of(context).isCompact) ?trailing,
          ],
        ),
        if (Breakpoints.of(context).isCompact && trailing != null)
          Align(alignment: AlignmentDirectional.centerStart, child: trailing!),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// The card grid the approved design opens the About section with.
///
/// The cards are paragraphs of the CMS body — see [ContentHighlight] for the
/// convention — so the committee adds, edits or removes one by editing the
/// page. Cards in a row are the same height, so a long sentence does not leave
/// the card beside it looking truncated.
class HighlightGrid extends StatelessWidget {
  const HighlightGrid({super.key, required this.highlights});

  final List<ContentHighlight> highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights.isEmpty) return const SizedBox.shrink();

    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 1,
      FormFactor.tablet => 2,
      FormFactor.desktop => 3,
    };

    final rows = <List<ContentHighlight>>[
      for (var i = 0; i < highlights.length; i += columns)
        highlights.sublist(i, (i + columns).clamp(0, highlights.length)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final row in rows) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: i < row.length
                        ? _HighlightCard(highlight: row[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          if (row != rows.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.highlight});

  final ContentHighlight highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (highlight.emblem != null) ...[
              Text(highlight.emblem!, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              highlight.heading,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              highlight.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
