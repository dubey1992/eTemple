import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/breakpoints.dart';
import '../../../content/presentation/widgets/content_widgets.dart';
import '../../domain/committee_member.dart';

/// The public committee, laid out as cards.
///
/// A member's phone, e-mail or photograph appears only when the API sent it,
/// which it does only where consent is on record. There is no client-side
/// "should we show this?" decision to get wrong.
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
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.md;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final member in shown)
                  SizedBox(
                    width: width,
                    child: _MemberCard(member: member),
                  ),
              ],
            );
          },
        ),
      ],
    );
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
                if (member.photoUrl != null)
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    foregroundImage: NetworkImage(member.photoUrl!),
                    // A broken image URL must not blank the card.
                    onForegroundImageError: (_, _) {},
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  )
                else
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
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

            if (member.hasPublicContact) ...[
              const SizedBox(height: AppSpacing.md),
              if (member.phone != null)
                _ContactLine(
                  icon: Icons.call_outlined,
                  label: l10n.contactPhone,
                  value: member.phone!,
                ),
              if (member.email != null)
                _ContactLine(
                  icon: Icons.mail_outline,
                  label: l10n.contactEmail,
                  value: member.email!,
                ),
            ],
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

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              semanticsLabel: '$label: $value',
            ),
          ),
        ],
      ),
    );
  }
}
