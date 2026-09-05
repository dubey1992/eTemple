import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../data/announcement_providers.dart';
import '../domain/announcement.dart';
import 'admin_announcements_screen.dart' show formatAnnouncementDate;
import 'announcement_labels.dart';
import 'widgets/send_announcement_dialog.dart';

/// Writing a notice, publishing it, and — separately — sending it.
///
/// The three buttons are not three settings. Saving can be corrected;
/// publishing can be archived; **sending cannot be undone and can only happen
/// once**, so it sits apart, is confirmed on its own, and disappears entirely
/// once it has been used (PHASE_8_PLAN assumption N1).
class AdminAnnouncementEditorScreen extends ConsumerStatefulWidget {
  const AdminAnnouncementEditorScreen({super.key, this.announcementId});

  /// Null when writing a new notice.
  final int? announcementId;

  @override
  ConsumerState<AdminAnnouncementEditorScreen> createState() =>
      _AdminAnnouncementEditorScreenState();
}

class _AdminAnnouncementEditorScreenState
    extends ConsumerState<AdminAnnouncementEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleHi = TextEditingController();
  final _titleEn = TextEditingController();
  final _messageHi = TextEditingController();
  final _messageEn = TextEditingController();
  final _linkUrl = TextEditingController();

  String _priority = AnnouncementPriorities.normal;
  DateTime? _startAt;
  DateTime? _endAt;

  bool _loaded = false;
  bool _busy = false;
  AppException? _error;

  @override
  void dispose() {
    for (final controller in [
      _titleHi,
      _titleEn,
      _messageHi,
      _messageEn,
      _linkUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.announcementsManage);

    if (widget.announcementId == null) {
      return _form(context, null, canManage);
    }

    final announcement = ref.watch(
      announcementProvider(widget.announcementId!),
    );

    return announcement.when(
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
          onRetry: () =>
              ref.invalidate(announcementProvider(widget.announcementId!)),
        );
      },
      data: (data) {
        // Filled once. Re-filling on every rebuild would throw away whatever
        // the editor had typed since.
        if (!_loaded) {
          _titleHi.text = data.titleHi;
          _titleEn.text = data.titleEn ?? '';
          _messageHi.text = data.messageHi;
          _messageEn.text = data.messageEn ?? '';
          _linkUrl.text = data.linkUrl ?? '';
          _priority = data.priority;
          _startAt = data.startAt;
          _endAt = data.endAt;
          _loaded = true;
        }

        return _form(context, data, canManage);
      },
    );
  }

  Widget _form(BuildContext context, Announcement? existing, bool canManage) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 820,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? l10n.announcementNew : l10n.announcementEdit,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.lg),

              if (_error != null) ...[
                _ErrorBanner(message: _error!.localizedMessage(l10n)),
                const SizedBox(height: AppSpacing.md),
              ],

              // Stated before the buttons, not after: the editor should know
              // this notice is already out before they wonder why they cannot
              // send it again.
              if (existing?.wasSent ?? false) ...[
                _SentPanel(announcement: existing!),
                const SizedBox(height: AppSpacing.md),
              ],

              _field(
                key: 'announcement-title-hi',
                controller: _titleHi,
                label: l10n.fieldAnnouncementTitleHindi,
                enabled: canManage,
                required: true,
              ),
              _field(
                key: 'announcement-title-en',
                controller: _titleEn,
                label: l10n.fieldAnnouncementTitleEnglish,
                enabled: canManage,
              ),
              _field(
                key: 'announcement-message-hi',
                controller: _messageHi,
                label: l10n.fieldAnnouncementMessageHindi,
                enabled: canManage,
                required: true,
                lines: 4,
              ),
              _field(
                key: 'announcement-message-en',
                controller: _messageEn,
                label: l10n.fieldAnnouncementMessageEnglish,
                enabled: canManage,
                lines: 4,
              ),

              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                key: const Key('announcement-priority'),
                initialValue: _priority,
                decoration: InputDecoration(
                  labelText: l10n.fieldAnnouncementPriority,
                ),
                items: [
                  for (final priority in AnnouncementPriorities.all)
                    DropdownMenuItem(
                      value: priority,
                      child: Text(AnnouncementLabels.priority(l10n, priority)),
                    ),
                ],
                onChanged: canManage
                    ? (value) => setState(
                        () =>
                            _priority = value ?? AnnouncementPriorities.normal,
                      )
                    : null,
              ),

              const SizedBox(height: AppSpacing.md),
              _DateRow(
                label: l10n.fieldAnnouncementStart,
                value: _startAt,
                enabled: canManage,
                onPick: (value) => setState(() => _startAt = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              _DateRow(
                label: l10n.fieldAnnouncementEnd,
                value: _endAt,
                enabled: canManage,
                clearable: true,
                onPick: (value) => setState(() => _endAt = value),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.fieldAnnouncementEndHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: AppSpacing.md),
              _field(
                key: 'announcement-link',
                controller: _linkUrl,
                label: l10n.fieldAnnouncementLink,
                enabled: canManage,
              ),

              if (canManage) ...[
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    FilledButton.icon(
                      key: const Key('announcement-save'),
                      onPressed: _busy ? null : () => _save(existing),
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(l10n.actionSave),
                    ),
                    if (existing != null && !existing.isPublished)
                      OutlinedButton.icon(
                        key: const Key('announcement-publish'),
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => ref
                                    .read(announcementRepositoryProvider)
                                    .publish(existing.id),
                                l10n.announcementPublished,
                              ),
                        icon: const Icon(Icons.public, size: 18),
                        label: Text(l10n.actionPublish2),
                      ),
                    if (existing != null && !existing.isArchived)
                      OutlinedButton.icon(
                        key: const Key('announcement-archive'),
                        onPressed: _busy
                            ? null
                            : () => _run(
                                () => ref
                                    .read(announcementRepositoryProvider)
                                    .archive(existing.id),
                                l10n.announcementArchived,
                              ),
                        icon: const Icon(Icons.inventory_2_outlined, size: 18),
                        label: Text(l10n.actionArchive),
                      ),
                  ],
                ),

                // Apart from the others, and only when it can actually be
                // done. A draft shows the reason instead of a dead button.
                if (existing != null) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  if (existing.canBeSent)
                    FilledButton.tonalIcon(
                      key: const Key('announcement-send'),
                      onPressed: _busy ? null : () => _send(existing),
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: Text(l10n.announcementSend),
                    )
                  else if (!existing.wasSent)
                    Text(
                      l10n.announcementPublishBeforeSending,
                      key: const Key('announcement-publish-first'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String key,
    required TextEditingController controller,
    required String label,
    required bool enabled,
    bool required = false,
    int lines = 1,
  }) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key(key),
        controller: controller,
        enabled: enabled,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          errorText: _error?.firstErrorFor(
            key.replaceFirst('announcement-', ''),
          ),
        ),
        validator: required
            ? (value) => (value == null || value.trim().isEmpty)
                  ? l10n.validationRequired
                  : null
            : null,
      ),
    );
  }

  AnnouncementDraft get _draft => AnnouncementDraft(
    titleHi: _titleHi.text.trim(),
    titleEn: _titleEn.text.trim().isEmpty ? null : _titleEn.text.trim(),
    messageHi: _messageHi.text.trim(),
    messageEn: _messageEn.text.trim().isEmpty ? null : _messageEn.text.trim(),
    priority: _priority,
    startAt: _startAt,
    endAt: _endAt,
    linkUrl: _linkUrl.text.trim().isEmpty ? null : _linkUrl.text.trim(),
  );

  Future<void> _save(Announcement? existing) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final l10n = context.l10n;
    final repository = ref.read(announcementRepositoryProvider);

    await _run(
      () => existing == null
          ? repository.create(_draft)
          : repository.save(existing.id, _draft),
      l10n.announcementSaved,
      onCreated: (announcement) =>
          context.go(RoutePaths.adminAnnouncementEditor(announcement.id)),
    );
  }

  Future<void> _send(Announcement announcement) async {
    final l10n = context.l10n;

    // Its own dialogue, saying in plain words that this cannot be undone and
    // can only happen once — and requiring a channel to be chosen, because a
    // default would mean this could happen without anybody choosing it.
    final channels = await showSendAnnouncementDialog(context);
    if (channels == null || channels.isEmpty || !mounted) return;

    await _run(
      () => ref
          .read(announcementRepositoryProvider)
          .send(announcement.id, channels),
      l10n.announcementSaved,
      onCreated: (sent) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(l10n.announcementSent(sent.recipientCount ?? 0)),
          ),
        );
      },
    );
  }

  Future<void> _run(
    Future<Announcement> Function() action,
    String success, {
    void Function(Announcement)? onCreated,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final result = await action();

      if (widget.announcementId != null) {
        ref.invalidate(announcementProvider(widget.announcementId!));
      }
      ref.invalidate(announcementsProvider);
      ref.invalidate(currentAnnouncementsProvider);

      if (!mounted) return;

      if (onCreated != null) {
        onCreated(result);
      } else {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

/// What is already true about a sent notice, stated where it cannot be missed.
class _SentPanel extends StatelessWidget {
  const _SentPanel({required this.announcement});

  final Announcement announcement;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Container(
      key: const Key('announcement-sent-panel'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.announcementSentNotice,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            [
              if (announcement.sentAt != null)
                l10n.announcementSentOn(
                  formatAnnouncementDate(announcement.sentAt!),
                ),
              if (announcement.recipientCount != null)
                l10n.announcementSent(announcement.recipientCount!),
              ...announcement.channelLabels,
            ].join(' · '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onPick,
    this.clearable = false,
  });

  final String label;
  final DateTime? value;
  final bool enabled;
  final bool clearable;
  final ValueChanged<DateTime?> onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            '$label: ${value == null ? '—' : formatAnnouncementDate(value!)}',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        TextButton(
          onPressed: enabled
              ? () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: value ?? now,
                    firstDate: now.subtract(const Duration(days: 365)),
                    lastDate: now.add(const Duration(days: 730)),
                  );
                  if (picked != null) onPick(picked);
                }
              : null,
          child: const Icon(Icons.event, size: 18),
        ),
        if (clearable && value != null)
          IconButton(
            onPressed: enabled ? () => onPick(null) : null,
            icon: const Icon(Icons.close, size: 18),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('announcement-error'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
