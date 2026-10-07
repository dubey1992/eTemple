import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../domain/content_highlight.dart';
import '../../domain/localized_value.dart';
import '../../domain/markup.dart';

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
/// Content is stored as text (PHASE_1_PLAN assumption B6) and is read for the
/// small Markdown subset in [Markup] — headings, bold, italic, bullets — because
/// that is what the committee writes. Nothing here interprets HTML, so no markup
/// an editor types can put a tag, a script or a link into the page.
class ContentBody extends StatelessWidget {
  const ContentBody({super.key, required this.content, this.emptyMessage});

  final LocalizedValue content;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocks = Markup.parse(content.value);

    if (blocks.isEmpty) {
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
        for (final (index, block) in blocks.indexed) ...[
          if (index > 0)
            SizedBox(
              // A heading opens a new part of the page and needs the air to
              // show it; between paragraphs the old spacing is right.
              height: block is MarkupHeading ? AppSpacing.lg : AppSpacing.md,
            ),
          _MarkupBlockView(block: block),
        ],
      ],
    );
  }
}

/// One parsed block, drawn with the app's own type scale.
class _MarkupBlockView extends StatelessWidget {
  const _MarkupBlockView({required this.block});

  final MarkupBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge;

    switch (block) {
      case MarkupHeading(:final level, :final spans):
        // The page's own title is already headlineMedium, so a heading inside
        // the body starts below it however many hashes the author used.
        final style = switch (level) {
          1 => theme.textTheme.headlineSmall,
          2 => theme.textTheme.titleLarge,
          3 => theme.textTheme.titleMedium,
          _ => theme.textTheme.titleSmall,
        };
        // Bold at every level, explicitly. Material's `titleMedium` is the
        // same size as body text and only one weight above it, so a `###`
        // heading drawn with the scale alone reads as a slightly odd
        // paragraph rather than as the heading somebody typed.
        final heading = style?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        );
        return Text.rich(_inline(spans, heading), style: heading);

      case MarkupParagraph(:final spans):
        return Text.rich(_inline(spans, body), style: body);

      case MarkupBullets(:final items):
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A real bullet rather than the typed hyphen, and sized
                    // with the text so it stays aligned at any scale factor.
                    Text('•  ', style: body),
                    Expanded(
                      child: Text.rich(_inline(item, body), style: body),
                    ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  TextSpan _inline(List<MarkupSpan> spans, TextStyle? base) => TextSpan(
    children: [
      for (final span in spans)
        TextSpan(
          text: span.text,
          style: base?.copyWith(
            fontWeight: span.bold ? FontWeight.w700 : null,
            fontStyle: span.italic ? FontStyle.italic : null,
          ),
        ),
    ],
  );
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
