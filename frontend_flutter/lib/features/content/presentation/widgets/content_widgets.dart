import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
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
            ?trailing,
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
