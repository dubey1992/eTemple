import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../data/temple_providers.dart';
import '../domain/committee_member.dart';

/// The committee as the administration sees it: everybody, including members
/// who are unpublished or whose term has ended.
///
/// Each row states plainly whether the person is on the public site and whether
/// any of their personal details are being published, because that is the thing
/// somebody scanning this list needs to be able to check at a glance.
class AdminCommitteeScreen extends ConsumerWidget {
  const AdminCommitteeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final members = ref.watch(adminCommitteeProvider);
    final canEdit = ref
        .watch(permissionsProvider)
        .can(Permissions.templeManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 900,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.committeeAdminTitle,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.committeeAdminSubtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (canEdit)
                  FilledButton.icon(
                    key: const Key('committee-new'),
                    onPressed: () => context.go(RoutePaths.adminCommitteeNew),
                    icon: const Icon(Icons.person_add_alt, size: 18),
                    label: Text(l10n.memberNew),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            members.when(
              loading: () => const LoadingView(),
              error: (error, _) {
                final exception = error is AppException
                    ? error
                    : const AppException.unknown();

                if (exception.code == ErrorCode.forbidden) {
                  return const UnauthorizedView();
                }
                return ErrorView(
                  error: exception,
                  onRetry: () => ref.invalidate(adminCommitteeProvider),
                );
              },
              data: (data) => data.isEmpty
                  ? EmptyView(
                      key: const Key('committee-empty'),
                      message: l10n.committeeEmpty,
                      icon: Icons.groups_outlined,
                    )
                  : Column(
                      children: [
                        for (final member in data)
                          _MemberRow(member: member, canEdit: canEdit),
                      ],
                    ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({required this.member, required this.canEdit});

  final AdminCommitteeMember member;
  final bool canEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: Key('committee-member-${member.id}'),
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        title: Text(member.nameHi, style: theme.textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(member.designationHi),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  StatusChip(
                    label: member.isPublished
                        ? l10n.statusPublished
                        : l10n.memberNotPublished,
                    tone: member.isPublished
                        ? StatusTone.positive
                        : StatusTone.neutral,
                  ),
                  if (member.tenureHasEnded)
                    StatusChip(
                      label: l10n.memberTenureEnded,
                      tone: StatusTone.neutral,
                    ),
                  // The one thing worth spotting without opening the record.
                  if (member.publishesPersonalDetails)
                    StatusChip(
                      key: Key('committee-public-details-${member.id}'),
                      label: l10n.consentPublicWarning,
                      tone: StatusTone.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
        trailing: Icon(
          canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: () => context.go(RoutePaths.adminCommitteeMember(member.id)),
      ),
    );
  }
}
