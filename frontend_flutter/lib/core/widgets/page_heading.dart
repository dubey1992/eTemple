import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'breakpoints.dart';

/// A screen's title, its explanation, and the things you can do on it.
///
/// Every list and editor in the console opened with the same hand-written
/// `Row` — title on the left, buttons on the right — and every one of them
/// overflowed on a 360px phone, because a row cannot make a button smaller
/// than its label. The console had only ever been tested at 1024px wide
/// (PHASE_12_PLAN §C), and a village committee's members mostly have phones.
///
/// So: a row on a tablet or a desktop, and on a phone the title with the
/// actions **wrapped underneath it**, where there is room for them. The actions
/// keep their order, so the primary one is still first.
class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;

  /// Buttons, in priority order. Rendered right-aligned beside the title on a
  /// wide screen and wrapped below it on a narrow one.
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = Breakpoints.of(context).isCompact;

    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: theme.textTheme.headlineSmall),
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
    );

    if (actions.isEmpty) {
      return Align(alignment: AlignmentDirectional.centerStart, child: heading);
    }

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          heading,
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: actions,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: heading),
        for (final action in actions) ...[
          const SizedBox(width: AppSpacing.sm),
          action,
        ],
      ],
    );
  }
}
