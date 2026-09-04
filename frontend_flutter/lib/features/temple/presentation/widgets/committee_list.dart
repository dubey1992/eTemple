import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../content/presentation/widgets/content_widgets.dart';
import '../../domain/committee_member.dart';

/// The public committee, laid out as equal-height cards.
///
/// A member's phone, e-mail or photograph appears only when the API sent it,
/// which it does only where consent is on record. There is no client-side
/// "should we show this?" decision to get wrong — a detail the server withheld
/// is rendered as "not available", which says nothing about the person.
class CommitteeList extends StatelessWidget {
  const CommitteeList({
    super.key,
    required this.members,
    this.limit,
    this.emptyMessage,
  });

  final List<CommitteeMember> members;

  /// Show at most this many, for the home page preview.
  final int? limit;

  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    if (members.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            emptyMessage ?? l10n.committeeComingSoon,
            key: const Key('committee-coming-soon'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    final shown = limit == null || limit! >= members.length
        ? members
        : members.sublist(0, limit!);

    final usesFallback = shown.any(
      (m) => m.name.fallbackUsed || m.designation.fallbackUsed,
    );

    final columns = switch (Breakpoints.of(context)) {
      FormFactor.mobile => 1,
      FormFactor.tablet => 2,
      FormFactor.desktop => 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (usesFallback) ...[
          const FallbackNotice(),
          const SizedBox(height: AppSpacing.md),
        ],
        // Rows are built by hand rather than with Wrap so that every card in a
        // row is the same height. Wrap sizes each child independently, which
        // left cards ragged whenever one member had a bio and another did not.
        for (final row in _rows(shown, columns)) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    // The last row can be short; the empty slots keep the cards
                    // that are there the same width as in a full row.
                    child: i < row.length
                        ? _MemberCard(member: row[i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
          if (row != _rows(shown, columns).last)
            const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  static List<List<CommitteeMember>> _rows(
    List<CommitteeMember> members,
    int columns,
  ) {
    return [
      for (var i = 0; i < members.length; i += columns)
        members.sublist(i, (i + columns).clamp(0, members.length)),
    ];
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({required this.member});

  final CommitteeMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: Key('committee-card-${member.id}'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(photoUrl: member.photoUrl),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name.orElse('—'),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        member.designation.orElse(''),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (member.bio.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                member.bio.value!,
                style: theme.textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (_tenure(context) != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _tenure(context)!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            // Both lines are always present so every card has the same shape.
            // A withheld detail reads "not available", which reveals nothing
            // about the member — the server decided it, not this widget.
            const SizedBox(height: AppSpacing.md),
            _ContactLine(
              icon: Icons.call_outlined,
              label: l10n.contactPhone,
              value: member.phone,
            ),
            _ContactLine(
              icon: Icons.mail_outline,
              label: l10n.contactEmail,
              value: member.email,
            ),
          ],
        ),
      ),
    );
  }

  String? _tenure(BuildContext context) {
    final l10n = context.l10n;
    final start = member.tenureStart;
    if (start == null) return null;

    final end = member.tenureEnd;
    return end == null ? l10n.tenureSince(start) : l10n.tenureRange(start, end);
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.photoUrl});

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Icon(
      Icons.person_outline,
      color: scheme.onSecondaryContainer,
    );

    if (photoUrl == null) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: scheme.secondaryContainer,
        child: placeholder,
      );
    }

    return CircleAvatar(
      radius: 24,
      backgroundColor: scheme.secondaryContainer,
      foregroundImage: NetworkImage(photoUrl!),
      // A broken image URL must not blank the card.
      onForegroundImageError: (_, _) {},
      child: placeholder,
    );
  }
}

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;

  /// Null when the server withheld the detail, which is not the same thing as
  /// the member not having one — the label says "not available", not "none".
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = value ?? context.l10n.valueNotAvailable;
    final isMissing = value == null;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: isMissing
                ? theme.colorScheme.onSurfaceVariant
                : theme.colorScheme.secondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMissing ? theme.colorScheme.onSurfaceVariant : null,
                fontStyle: isMissing ? FontStyle.italic : null,
              ),
              semanticsLabel: '$label: $text',
            ),
          ),
        ],
      ),
    );
  }
}
