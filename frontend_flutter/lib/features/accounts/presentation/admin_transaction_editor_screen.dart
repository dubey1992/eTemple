import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/auth/permissions.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/files/file_chooser.dart';
import '../../../core/files/link_opener.dart';
import '../../../core/files/picked_file.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../donations/domain/donation.dart' show PaymentModes;
import '../../donations/presentation/donation_formatting.dart';
import '../data/accounts_providers.dart';
import '../domain/account.dart';
import '../domain/accounts_repository.dart';
import 'account_labels.dart';

/// Recording one movement of the temple's money, and deciding what happens to
/// it.
///
/// The screen is arranged around the fact that **approval is the point of no
/// return**. Save and the form sit together; approve and reverse sit below a
/// divider with the consequence written out, because after approval the figure
/// is in a total the village reads and only the description can be changed.
class AdminTransactionEditorScreen extends ConsumerStatefulWidget {
  const AdminTransactionEditorScreen({super.key, this.transactionId});

  /// Null for a new entry.
  final int? transactionId;

  @override
  ConsumerState<AdminTransactionEditorScreen> createState() =>
      _AdminTransactionEditorScreenState();
}

class _AdminTransactionEditorScreenState
    extends ConsumerState<AdminTransactionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _payee = TextEditingController();
  final _description = TextEditingController();

  String _type = TransactionTypes.expense;
  int? _categoryId;
  String _paymentMode = PaymentModes.cash;
  DateTime _date = DateTime.now();

  PickedFile? _bill;
  bool _saving = false;
  bool _loaded = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _payee.dispose();
    _description.dispose();
    super.dispose();
  }

  bool get _isNew => widget.transactionId == null;

  /// Fills the form from the server's copy, once.
  ///
  /// Once only: re-seeding on every rebuild would throw away what the treasurer
  /// had typed the moment any provider above refreshed.
  void _seed(Transaction transaction) {
    if (_loaded) return;
    _loaded = true;

    _amount.text = (transaction.amountPaise / 100).toStringAsFixed(2);
    _reference.text = transaction.referenceNumber ?? '';
    _payee.text = transaction.payeeName ?? '';
    _description.text = transaction.description ?? '';
    _type = transaction.type;
    _categoryId = transaction.categoryId;
    _paymentMode = transaction.paymentMode;
    _date = DateTime.tryParse(transaction.transactionDate) ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    if (_isNew) {
      return _form(context, null);
    }

    final transaction = ref.watch(transactionProvider(widget.transactionId!));

    return transaction.when(
      loading: () => const LoadingView(),
      error: (error, _) => ErrorView(
        error: error is AppException ? error : const AppException.unknown(),
        onRetry: () =>
            ref.invalidate(transactionProvider(widget.transactionId!)),
      ),
      data: (data) {
        _seed(data);
        return _form(context, data);
      },
    );
  }

  Widget _form(BuildContext context, Transaction? existing) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = Localizations.localeOf(context).languageCode;
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.accountsManage);

    final locked = existing?.isLocked ?? false;
    final reversed = existing?.isReversed ?? false;
    final editable = canManage && !reversed;

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isNew ? l10n.accountsNewEntry : l10n.accountsEditEntry,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (existing != null)
                    StatusChip(
                      label: AccountLabels.status(l10n, existing.status),
                      tone: switch (existing.status) {
                        TransactionStatuses.approved => StatusTone.positive,
                        TransactionStatuses.reversed => StatusTone.danger,
                        _ => StatusTone.warning,
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // The state of the record, before the fields it governs.
              if (reversed && existing != null)
                _Notice(
                  fieldKey: 'accounts-reversed-notice',
                  icon: Icons.undo,
                  tone: StatusTone.danger,
                  text: [
                    l10n.accountsReversedOn(
                      AccountLabels.timestamp(existing.reversedAt, language),
                    ),
                    if (existing.reversedByName != null)
                      l10n.accountsReversedBy(existing.reversedByName!),
                    if (existing.reversalReason != null)
                      existing.reversalReason!,
                  ].join(' · '),
                )
              else if (locked)
                _Notice(
                  fieldKey: 'accounts-locked-notice',
                  icon: Icons.lock_outline,
                  tone: StatusTone.info,
                  text: l10n.accountsLockedNotice,
                )
              else if (existing != null)
                _Notice(
                  fieldKey: 'accounts-pending-notice',
                  icon: Icons.pending_actions_outlined,
                  tone: StatusTone.warning,
                  text: l10n.accountsPendingNotice,
                ),

              const SizedBox(height: AppSpacing.lg),

              _CategoryField(
                type: _type,
                categoryId: _categoryId,
                enabled: editable && !locked,
                onChanged: (category) => setState(() {
                  _categoryId = category?.id;
                  // The category decides the side of the books; the form
                  // follows it rather than offering a contradiction the server
                  // would only refuse.
                  if (category != null) _type = category.type;
                }),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                key: const Key('accounts-amount-field'),
                controller: _amount,
                enabled: editable && !locked,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.accountsFieldAmount,
                  prefixText: '₹ ',
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              _DateField(
                value: _date,
                enabled: editable && !locked,
                label: l10n.accountsFieldDate,
                language: language,
                onChanged: (value) => setState(() => _date = value),
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                key: const Key('accounts-mode-field'),
                initialValue: _paymentMode,
                decoration: InputDecoration(
                  labelText: l10n.accountsFieldPaymentMode,
                ),
                items: [
                  for (final mode in PaymentModes.all)
                    DropdownMenuItem(
                      value: mode,
                      child: Text(DonationFormatting.modeLabel(mode, l10n)),
                    ),
                ],
                onChanged: editable && !locked
                    ? (value) => setState(
                        () => _paymentMode = value ?? PaymentModes.cash,
                      )
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Required for everything but cash, which is the only mode that
              // leaves nothing to match against a statement.
              if (PaymentModes.requiresReference(_paymentMode)) ...[
                TextFormField(
                  key: const Key('accounts-reference-field'),
                  controller: _reference,
                  enabled: editable && !locked,
                  decoration: InputDecoration(
                    labelText: l10n.accountsFieldReference,
                  ),
                  validator: (value) =>
                      PaymentModes.requiresReference(_paymentMode) &&
                          (value == null || value.trim().isEmpty)
                      ? l10n.validationRequired
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              TextFormField(
                key: const Key('accounts-payee-field'),
                controller: _payee,
                enabled: editable && !locked,
                decoration: InputDecoration(
                  labelText: l10n.accountsFieldPayee,
                  helperText: l10n.accountsPayeeHelp,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              TextFormField(
                key: const Key('accounts-description-field'),
                controller: _description,
                // Editable even once approved: it is a note about the entry,
                // not the entry itself.
                enabled: editable,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.accountsFieldDescription,
                  helperText: l10n.accountsDescriptionHelp,
                  helperMaxLines: 2,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _BillField(
                existing: existing,
                picked: _bill,
                // A bill on an approved entry is evidence for a published
                // figure; replacing it is not an edit to a note.
                enabled: editable && !locked,
                onChoose: _chooseBill,
              ),

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Notice(
                  fieldKey: 'accounts-error',
                  icon: Icons.error_outline,
                  tone: StatusTone.danger,
                  text: _error!,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  FilledButton(
                    key: const Key('accounts-save'),
                    onPressed: editable && !_saving ? _save : null,
                    child: Text(l10n.actionSave),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  TextButton(
                    key: const Key('accounts-cancel'),
                    onPressed: () => context.go(RoutePaths.adminAccounts),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),

              // Approve and reverse are below a divider and on their own: one
              // puts a figure into a total the village reads, and the other is
              // the only undo there is.
              if (existing != null && canManage && !reversed) ...[
                const SizedBox(height: AppSpacing.xl),
                const Divider(),
                const SizedBox(height: AppSpacing.lg),
                _Decisions(
                  transaction: existing,
                  busy: _saving,
                  onApprove: _approve,
                  onReverse: _reverse,
                ),
              ],

              if (existing != null) ...[
                const SizedBox(height: AppSpacing.xl),
                _Provenance(transaction: existing, language: language),
              ],

              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _chooseBill() async {
    const chooser = FileChooser();
    final file = await chooser.pickFile(
      // A convenience for the person choosing and nothing more: the server
      // decides the type by reading the bytes it receives.
      accept: const [
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf',
      ],
    );

    if (file != null && mounted) setState(() => _bill = file);
  }

  TransactionDraft _draft() => TransactionDraft(
    amount: _amount.text.trim(),
    transactionDate: _date.toIso8601String().split('T').first,
    categoryId: _categoryId ?? 0,
    type: _type,
    paymentMode: _paymentMode,
    referenceNumber: _reference.text.trim(),
    payeeName: _payee.text.trim(),
    description: _description.text.trim(),
  );

  AttachmentUpload? _upload() {
    final bill = _bill;
    if (bill == null) return null;

    return AttachmentUpload(
      bytes: bill.bytes,
      filename: bill.name,
      contentType: bill.mimeType,
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_categoryId == null) {
      setState(() => _error = context.l10n.accountsFieldCategory);
      return;
    }

    await _run(() async {
      final repository = ref.read(accountsRepositoryProvider);

      if (_isNew) {
        final created = await repository.record(_draft(), bill: _upload());
        if (mounted) {
          context.go(RoutePaths.adminAccountDetail(created.id));
        }
      } else {
        await repository.save(widget.transactionId!, _draft(), bill: _upload());
        if (mounted) context.go(RoutePaths.adminAccounts);
      }
    });
  }

  Future<void> _approve() async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      title: l10n.accountsApproveTitle,
      body: l10n.accountsApproveBody,
      action: l10n.accountsApprove,
      keyPrefix: 'accounts-approve',
    );
    if (confirmed != true) return;

    await _run(() async {
      await ref.read(accountsRepositoryProvider).approve(widget.transactionId!);
      if (mounted) context.go(RoutePaths.adminAccounts);
    });
  }

  Future<void> _reverse() async {
    // The dialogue asks for the reason itself: it is required, and collecting
    // it afterwards would mean a reversal could be started without one.
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => const _ReversalDialog(),
    );

    if (reason == null || reason.trim().isEmpty) return;

    await _run(() async {
      await ref
          .read(accountsRepositoryProvider)
          .reverse(widget.transactionId!, reason.trim());
      if (mounted) context.go(RoutePaths.adminAccounts);
    });
  }

  Future<bool?> _confirm({
    required String title,
    required String body,
    required String action,
    required String keyPrefix,
  }) {
    final l10n = context.l10n;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: Key('$keyPrefix-dialog'),
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: Key('$keyPrefix-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await action();
      _invalidate();
    } on AppException catch (error) {
      if (mounted) {
        setState(() => _error = error.localizedMessage(context.l10n));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _invalidate() {
    ref.invalidate(transactionsProvider);
    ref.invalidate(accountsSummaryProvider);
    if (widget.transactionId != null) {
      ref.invalidate(transactionProvider(widget.transactionId!));
    }
  }
}

/// The heading picker, which is also what decides the side of the books.
class _CategoryField extends ConsumerWidget {
  const _CategoryField({
    required this.type,
    required this.categoryId,
    required this.enabled,
    required this.onChanged,
  });

  final String type;
  final int? categoryId;
  final bool enabled;
  final ValueChanged<AccountingCategory?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final categories = ref.watch(activeCategoriesProvider);

    return categories.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, _) => Text(l10n.errorServer),
      data: (all) {
        // A category the entry already uses may have been deactivated since;
        // it stays selectable so the row still reads correctly.
        final selected = all.where((c) => c.id == categoryId).firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<int>(
              key: const Key('accounts-category-field'),
              initialValue: selected?.id,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.accountsFieldCategory,
              ),
              items: [
                for (final category in all)
                  DropdownMenuItem(
                    value: category.id,
                    child: Text(
                      '${AccountLabels.type(l10n, category.type)} · '
                      '${category.nameFor(language)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: enabled
                  ? (value) =>
                        onChanged(all.where((c) => c.id == value).firstOrNull)
                  : null,
              validator: (value) =>
                  value == null ? l10n.validationRequired : null,
            ),
            const SizedBox(height: AppSpacing.xs),
            // Said here rather than discovered through a refusal: a treasurer
            // looking for "दान" in this list needs to know where it went.
            Text(
              l10n.accountsDonationsElsewhere,
              key: const Key('accounts-donations-elsewhere'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.enabled,
    required this.label,
    required this.language,
    required this.onChanged,
  });

  final DateTime value;
  final bool enabled;
  final String label;
  final String language;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('accounts-date-field'),
      onTap: enabled
          ? () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: value,
                firstDate: DateTime.now().subtract(const Duration(days: 366)),
                // Money cannot move in the future, and the server refuses a
                // date that claims it did.
                lastDate: DateTime.now(),
              );
              if (picked != null) onChanged(picked);
            }
          : null,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
          enabled: enabled,
        ),
        child: Text(
          AccountLabels.date(
            value.toIso8601String().split('T').first,
            language,
          ),
        ),
      ),
    );
  }
}

/// The bill: what is attached, what is about to be, and how to look at it.
class _BillField extends ConsumerWidget {
  const _BillField({
    required this.existing,
    required this.picked,
    required this.enabled,
    required this.onChoose,
  });

  final Transaction? existing;
  final PickedFile? picked;
  final bool enabled;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final has = existing?.hasAttachment ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.accountsBill, style: theme.textTheme.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('accounts-choose-bill'),
              onPressed: enabled ? onChoose : null,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(
                has ? l10n.accountsReplaceBill : l10n.accountsAttachBill,
              ),
            ),
            if (has) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton.icon(
                key: const Key('accounts-view-bill'),
                onPressed: () {
                  // Opened in a new tab rather than rendered inline: the server
                  // sends it as a download with `nosniff`, so nothing that got
                  // past the byte check can execute in this origin.
                  const opener = LinkOpener();
                  // `openOwn`: the bill is on our own authenticated endpoint,
                  // and a stripped Referer makes the request anonymous.
                  opener.openOwn(
                    ref
                        .read(accountsRepositoryProvider)
                        .attachmentUrl(existing!.id),
                  );
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text(l10n.accountsViewBill),
              ),
            ],
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                picked?.name ?? existing?.attachmentName ?? l10n.accountsNoBill,
                key: const Key('accounts-bill-name'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          enabled ? l10n.accountsBillHelp : l10n.accountsBillLocked,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Approve and reverse, with what each one does written beside it.
class _Decisions extends StatelessWidget {
  const _Decisions({
    required this.transaction,
    required this.busy,
    required this.onApprove,
    required this.onReverse,
  });

  final Transaction transaction;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReverse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!transaction.isApproved) ...[
          Text(l10n.accountsApproveBody, style: theme.textTheme.bodySmall),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            key: const Key('accounts-approve'),
            onPressed: busy ? null : onApprove,
            icon: const Icon(Icons.check, size: 18),
            label: Text(l10n.accountsApprove),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        Text(l10n.accountsReverseBody, style: theme.textTheme.bodySmall),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('accounts-reverse'),
          onPressed: busy ? null : onReverse,
          icon: const Icon(Icons.undo, size: 18),
          label: Text(l10n.accountsReverse),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

/// Who did what, and when. The row's own audit trail.
class _Provenance extends StatelessWidget {
  const _Provenance({required this.transaction, required this.language});

  final Transaction transaction;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (transaction.createdByName != null)
          Text(
            l10n.accountsRecordedBy(transaction.createdByName!),
            style: style,
          ),
        if (transaction.approvedAt != null)
          Text(
            l10n.accountsApprovedOn(
              AccountLabels.timestamp(transaction.approvedAt, language),
            ),
            style: style,
          ),
        if (transaction.approvedByName != null)
          Text(
            l10n.accountsApprovedBy(transaction.approvedByName!),
            style: style,
          ),
      ],
    );
  }
}

/// Reversal asks for its reason in the dialogue, not afterwards.
///
/// The confirm button stays disabled until something is written: the reason is
/// the whole explanation of why a figure that was once counted no longer is,
/// and an empty one would be worse than no reversal at all.
class _ReversalDialog extends StatefulWidget {
  const _ReversalDialog();

  @override
  State<_ReversalDialog> createState() => _ReversalDialogState();
}

class _ReversalDialogState extends State<_ReversalDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = _reason.text.trim().length >= 3;

    return AlertDialog(
      key: const Key('accounts-reverse-dialog'),
      title: Text(l10n.accountsReverseTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.accountsReverseBody),
          const SizedBox(height: AppSpacing.md),
          TextField(
            key: const Key('accounts-reverse-reason'),
            controller: _reason,
            autofocus: true,
            maxLines: 2,
            decoration: InputDecoration(labelText: l10n.accountsReverseReason),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('accounts-reverse-confirm'),
          onPressed: ready
              ? () => Navigator.of(context).pop(_reason.text)
              : null,
          child: Text(l10n.accountsReverse),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.fieldKey,
    required this.icon,
    required this.tone,
    required this.text,
  });

  final String fieldKey;
  final IconData icon;
  final StatusTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final colour = switch (tone) {
      StatusTone.danger => theme.colorScheme.error,
      StatusTone.warning => theme.colorScheme.tertiary,
      _ => theme.colorScheme.primary,
    };

    return Container(
      key: Key(fieldKey),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colour.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colour),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }
}
