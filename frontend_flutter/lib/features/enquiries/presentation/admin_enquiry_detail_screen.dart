import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/enquiry_providers.dart';
import '../domain/enquiry.dart';
import 'enquiry_labels.dart';

/// One enquiry, and the two things a committee member can do about it: move it
/// along, and say who is dealing with it.
///
/// There is no reply box. Answering happens by telephone or e-mail — the
/// devotee said which they prefer, and it is shown at the top — because an
/// outbound mail system with delivery tracking is a phase of its own, and a
/// "send" button that silently fails is worse than no button
/// (PHASE_7_PLAN §9).
class AdminEnquiryDetailScreen extends ConsumerStatefulWidget {
  const AdminEnquiryDetailScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<AdminEnquiryDetailScreen> createState() =>
      _AdminEnquiryDetailScreenState();
}

class _AdminEnquiryDetailScreenState
    extends ConsumerState<AdminEnquiryDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final enquiry = ref.watch(enquiryProvider(widget.id));

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 820,
        child: enquiry.when(
          loading: () => const LoadingView(),
          error: (error, _) {
            final exception = error is AppException
                ? error
                : const AppException.unknown();

            if (exception.code == ErrorCode.forbidden) {
              return const UnauthorizedView();
            }
            if (exception.isNotFound) {
              return EmptyView(
                message: l10n.enquiryInboxEmpty,
                icon: Icons.mark_email_unread_outlined,
              );
            }
            return ErrorView(
              error: exception,
              onRetry: () => ref.invalidate(enquiryProvider(widget.id)),
            );
          },
          data: _Body.new,
        ),
      ),
    );
  }
}

/// Rendered as a plain function so the controls below can be rebuilt from the
/// refreshed enquiry without the screen holding a stale copy of it.
class _Body extends ConsumerStatefulWidget {
  const _Body(this.enquiry);

  final Enquiry enquiry;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final enquiry = widget.enquiry;
    final canSeeMembers = ref
        .watch(permissionsProvider)
        .can(Permissions.usersView);
    final me = ref.watch(authControllerProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(enquiry.name, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    enquiry.reference,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: EnquiryLabels.status(l10n, enquiry.status),
              tone: switch (enquiry.status) {
                EnquiryStatuses.isNew => StatusTone.info,
                EnquiryStatuses.inProgress => StatusTone.warning,
                EnquiryStatuses.resolved => StatusTone.positive,
                _ => StatusTone.neutral,
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // How to answer, before what was asked: whoever opens this is
                // about to pick up a telephone.
                if (enquiry.mobile != null)
                  _Line(
                    icon: Icons.call_outlined,
                    label: l10n.fieldMobile,
                    value: enquiry.mobile,
                  ),
                if (enquiry.email != null)
                  _Line(
                    icon: Icons.mail_outline,
                    label: l10n.fieldEmail,
                    value: enquiry.email,
                  ),
                if (enquiry.mobile == null && enquiry.email == null)
                  Text(
                    l10n.enquiryNoReplyChannel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                _Line(
                  icon: Icons.translate,
                  label: l10n.enquiryReplyIn,
                  value: EnquiryLabels.language(
                    l10n,
                    enquiry.preferredLanguage,
                  ),
                ),
                _Line(
                  icon: Icons.label_outline,
                  label: l10n.fieldEnquiryCategory,
                  value: EnquiryLabels.category(
                    l10n,
                    enquiry.category,
                    fallback: enquiry.categoryLabel,
                  ),
                ),
                _Line(
                  icon: Icons.person_outline,
                  label: l10n.enquiryAssignedTo,
                  value: enquiry.assignedToName ?? l10n.enquiryUnassigned,
                ),
                if (enquiry.createdAt != null)
                  _Line.note(
                    icon: Icons.schedule,
                    text: l10n.enquiryReceivedOn(
                      _formatDate(enquiry.createdAt!),
                    ),
                  ),
                if (enquiry.resolvedAt != null)
                  _Line.note(
                    icon: Icons.task_alt,
                    text: [
                      l10n.enquiryResolvedOn(_formatDate(enquiry.resolvedAt!)),
                      ?enquiry.resolvedByName,
                    ].join(' · '),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fieldEnquiryMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                SelectableText(
                  enquiry.message,
                  key: const Key('enquiry-message-body'),
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),

        if (enquiry.isSpam) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.enquirySpamNotice,
            key: const Key('enquiry-spam-notice'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),
        Text(l10n.fieldStatus, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final status in EnquiryStatuses.all)
              ChoiceChip(
                key: Key('enquiry-set-$status'),
                label: Text(EnquiryLabels.status(l10n, status)),
                selected: enquiry.status == status,
                onSelected: _busy || enquiry.status == status
                    ? null
                    : (_) => _run(
                        () => ref
                            .read(enquiryRepositoryProvider)
                            .updateStatus(enquiry.id, status),
                        l10n.enquiryStatusUpdated,
                      ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),
        Text(l10n.enquiryAssignedTo, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (me != null && enquiry.assignedTo != me.id)
              FilledButton.tonalIcon(
                key: const Key('enquiry-assign-me'),
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => ref
                            .read(enquiryRepositoryProvider)
                            .assign(enquiry.id, me.id),
                        l10n.enquiryAssignmentUpdated,
                      ),
                icon: const Icon(Icons.person_add_alt, size: 18),
                label: Text(l10n.enquiryAssignToMe),
              ),
            if (enquiry.assignedTo != null)
              OutlinedButton.icon(
                key: const Key('enquiry-unassign'),
                onPressed: _busy
                    ? null
                    : () => _run(
                        () => ref
                            .read(enquiryRepositoryProvider)
                            .assign(enquiry.id, null),
                        l10n.enquiryAssignmentUpdated,
                      ),
                icon: const Icon(Icons.person_remove_alt_1_outlined, size: 18),
                label: Text(l10n.enquiryUnassign),
              ),

            // Handing it to somebody else needs the member list, which lives
            // behind `users.view` — a permission `enquiries.manage` does not
            // imply. A Content Manager can still take a message and answer it;
            // they simply cannot pass it on.
            if (canSeeMembers)
              _AssignToMember(
                enabled: !_busy,
                onPick: (id) => _run(
                  () => ref
                      .read(enquiryRepositoryProvider)
                      .assign(enquiry.id, id),
                  l10n.enquiryAssignmentUpdated,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  /// Runs one change, reports it, and refreshes the enquiry from the server
  /// rather than guessing what the row now looks like.
  Future<void> _run(Future<Enquiry> Function() action, String success) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);

    try {
      await action();
      ref.invalidate(enquiryProvider(widget.enquiry.id));
      ref.invalidate(enquiriesProvider);
      ref.invalidate(enquirySummaryProvider);

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } on AppException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(error.localizedMessage(l10n))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static String _formatDate(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';
}

/// Handing the enquiry to another member, for whoever can see the member list.
///
/// The list is filtered by nothing here: which members may hold an enquiry is
/// the server's decision, and it refuses a Treasurer with a message saying
/// exactly why (PHASE_7_PLAN assumption N11). Guessing at it client-side would
/// duplicate the permission matrix in the browser and drift from it.
class _AssignToMember extends ConsumerWidget {
  const _AssignToMember({required this.enabled, required this.onPick});

  final bool enabled;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(adminUsersProvider);

    return members.maybeWhen(
      data: (users) => DropdownButton<int>(
        key: const Key('enquiry-assign-member'),
        hint: Text(context.l10n.enquiryChooseMember),
        items: [
          for (final user in users)
            DropdownMenuItem(
              value: user.id,
              child: Text(user.fullName ?? user.firstName),
            ),
        ],
        onChanged: enabled ? (id) => id == null ? null : onPick(id) : null,
      ),
      // Absent while loading, or if the list is refused: this is a second way
      // to do something that can already be done with the buttons beside it.
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.value});

  /// A line that is all label and no value — a date, or a note.
  const _Line.note({required this.icon, required String text})
    : label = text,
      value = null;

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value == null ? label : '$label: ',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (value != null)
                    TextSpan(text: value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
