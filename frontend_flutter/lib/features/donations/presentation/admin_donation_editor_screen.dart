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
import '../../../core/files/link_opener.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../../admin/presentation/widgets/status_chip.dart';
import '../../content/data/content_providers.dart';
import '../data/donation_providers.dart';
import '../domain/donation.dart';
import 'donation_formatting.dart';

/// Records a donation, and is the page for one that already exists.
///
/// One screen rather than two, because a donation's own life decides what it
/// is: while it is pending it is a form, and once a receipt has been issued it
/// is a document with a notes box. Splitting them would duplicate every field
/// and make the transition invisible.
class AdminDonationEditorScreen extends ConsumerWidget {
  const AdminDonationEditorScreen({super.key, this.donationId, this.opener});

  final int? donationId;

  /// Injectable so the "print the receipt" path is testable off a browser.
  final LinkOpener? opener;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = donationId;
    if (id == null) return _DonationForm(opener: opener);

    final donation = ref.watch(donationProvider(id));

    return donation.when(
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
          onRetry: () => ref.invalidate(donationProvider(id)),
        );
      },
      data: (data) => _DonationForm(donation: data, opener: opener),
    );
  }
}

class _DonationForm extends ConsumerStatefulWidget {
  const _DonationForm({this.donation, this.opener});

  final Donation? donation;
  final LinkOpener? opener;

  @override
  ConsumerState<_DonationForm> createState() => _DonationFormState();
}

class _DonationFormState extends ConsumerState<_DonationForm> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'donor_name',
      'donor_phone',
      'donor_address',
      'amount',
      'reference_number',
      'notes',
    ])
      name: TextEditingController(),
  };

  /// Held for the life of the screen rather than created inside the dialogue.
  ///
  /// A controller disposed the moment `showDialog` returns is still attached to
  /// the text field while the dialogue animates out, and Flutter asserts on the
  /// use of a disposed controller.
  final _reasonController = TextEditingController();

  late String _mode;
  late String _purpose;
  late DateTime _date;
  late bool _anonymous;

  bool _saving = false;
  AppException? _error;

  Donation? get _donation => widget.donation;

  bool get _isNew => _donation == null;

  /// A receipt has been issued, so only the notes may change from here.
  bool get _isLocked => _donation?.isLocked ?? false;

  @override
  void initState() {
    super.initState();

    final donation = _donation;
    _mode = donation?.paymentMode ?? PaymentModes.cash;
    _purpose = donation?.purpose ?? DonationPurposes.general;
    _anonymous = donation?.isAnonymous ?? false;
    _date = DateTime.tryParse(donation?.donationDate ?? '') ?? DateTime.now();

    if (donation != null) {
      _fields['donor_name']!.text = donation.donorName;
      _fields['donor_phone']!.text = donation.donorPhone ?? '';
      _fields['donor_address']!.text = donation.donorAddress ?? '';
      // The unformatted figure, so editing does not have to strip a ₹ and
      // commas back out of it.
      _fields['amount']!.text = (donation.amountPaise / 100).toStringAsFixed(2);
      _fields['reference_number']!.text = donation.referenceNumber ?? '';
      _fields['notes']!.text = donation.notes ?? '';
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    _reasonController.dispose();
    super.dispose();
  }

  String? _text(String name) {
    final value = _fields[name]!.text.trim();
    return value.isEmpty ? null : value;
  }

  String get _isoDate =>
      '${_date.year.toString().padLeft(4, '0')}-'
      '${_date.month.toString().padLeft(2, '0')}-'
      '${_date.day.toString().padLeft(2, '0')}';

  DonationDraft _draft() => DonationDraft(
    donorName: _fields['donor_name']!.text,
    donorPhone: _text('donor_phone'),
    donorAddress: _text('donor_address'),
    // The string the treasurer typed, sent as typed. Parsing it into paise
    // happens in exactly one place, on the server.
    amount: _fields['amount']!.text,
    donationDate: _isoDate,
    paymentMode: _mode,
    referenceNumber: _text('reference_number'),
    purpose: _purpose,
    notes: _text('notes'),
    isAnonymous: _anonymous,
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      // The same bounds the server enforces, so the picker cannot produce a
      // date the API will refuse.
      firstDate: DateTime.now().subtract(const Duration(days: 366)),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(donationRepositoryProvider);
      final donation = _donation;

      if (donation == null) {
        await repository.record(_draft());
      } else {
        await repository.save(donation.id, _draft());
        ref.invalidate(donationProvider(donation.id));
      }

      _refreshRegister();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              donation == null
                  ? context.l10n.donationRecorded
                  : context.l10n.saveSuccess,
            ),
          ),
        );
        context.go(RoutePaths.adminDonations);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirm() async {
    final donation = _donation;
    if (donation == null || _saving) return;

    final l10n = context.l10n;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('donation-confirm-dialog'),
        title: Text(l10n.donationConfirmTitle),
        content: Text(l10n.donationConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('donation-confirm-accept'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.donationConfirm),
          ),
        ],
      ),
    );

    if (agreed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final confirmed = await ref
          .read(donationRepositoryProvider)
          .confirm(donation.id);
      ref.invalidate(donationProvider(donation.id));
      _refreshRegister();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.l10n.donationConfirmed(confirmed.receiptNumber ?? '—'),
            ),
          ),
        );
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _reverse() async {
    final donation = _donation;
    if (donation == null || _saving) return;

    final l10n = context.l10n;
    _reasonController.clear();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('donation-reverse-dialog'),
        title: Text(l10n.donationReverseTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.donationReverseBody),
            const SizedBox(height: AppSpacing.md),
            TextField(
              key: const Key('donation-reverse-reason'),
              controller: _reasonController,
              autofocus: true,
              maxLength: 500,
              decoration: InputDecoration(labelText: l10n.fieldReversalReason),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('donation-reverse-accept'),
            onPressed: () => Navigator.of(context).pop(_reasonController.text),
            child: Text(l10n.donationReverse),
          ),
        ],
      ),
    );

    if (reason == null || reason.trim().isEmpty || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(donationRepositoryProvider).reverse(donation.id, reason);
      ref.invalidate(donationProvider(donation.id));
      _refreshRegister();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.donationReversed)));
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _printReceipt() {
    final donation = _donation;
    if (donation == null) return;

    // A new tab rather than an in-app view: the receipt is a document the
    // browser prints, and the browser is also what shapes the Devanagari in a
    // donor's name correctly.
    // `openOwn`: the receipt is our own authenticated endpoint, and a
    // stripped Referer makes the request anonymous.
    (widget.opener ?? const LinkOpener()).openOwn(
      ref.read(donationRepositoryProvider).receiptUrl(donation.id),
    );
  }

  /// The register is filtered four ways and carries totals, so every view of it
  /// is refreshed rather than just the one in front of us.
  void _refreshRegister() => ref.invalidate(donationsProvider);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);
    // Watched, not read: the session resolves after the first build.
    final canManage = ref
        .watch(permissionsProvider)
        .can(Permissions.donationsManage);
    final donation = _donation;
    final editable = canManage && !_saving && !_isLocked;

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
                      _isNew ? l10n.donationNew : l10n.donationEdit,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                  if (donation != null)
                    StatusChip(
                      label: DonationFormatting.statusLabel(
                        donation.status,
                        l10n,
                      ),
                      tone: switch (donation.status) {
                        DonationStatuses.confirmed => StatusTone.positive,
                        DonationStatuses.reversed => StatusTone.danger,
                        _ => StatusTone.warning,
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (donation != null) ...[
                _ReceiptLine(donation: donation),
                const SizedBox(height: AppSpacing.md),
              ],

              if (!canManage) ...[
                _Notice(
                  noticeKey: const Key('donation-read-only'),
                  background: theme.colorScheme.secondaryContainer,
                  foreground: theme.colorScheme.onSecondaryContainer,
                  text: l10n.stateUnauthorizedBody,
                ),
                const SizedBox(height: AppSpacing.md),
              ] else if (_isLocked && !(donation?.isReversed ?? false)) ...[
                _Notice(
                  noticeKey: const Key('donation-locked'),
                  background: theme.colorScheme.secondaryContainer,
                  foreground: theme.colorScheme.onSecondaryContainer,
                  text: l10n.donationLockedNotice,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (donation?.isReversed ?? false) ...[
                _Notice(
                  noticeKey: const Key('donation-reversed'),
                  background: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                  text: l10n.donationReversedNotice(
                    DonationFormatting.timestamp(
                      donation!.reversedAt,
                      language,
                    ),
                    donation.reversalReason ?? '—',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_error != null) ...[
                _Notice(
                  noticeKey: const Key('donation-error'),
                  background: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                  text: _error!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              _field(
                'donor_name',
                l10n.fieldDonorName,
                editable,
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _field(
                'amount',
                '${l10n.fieldAmount} · ${l10n.amountHint}',
                editable,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),

              _DateField(
                label: l10n.fieldDonationDate,
                value: DonationFormatting.date(_isoDate, language),
                error: _error?.firstErrorFor('donation_date'),
                onPick: editable ? _pickDate : null,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                key: const Key('donation-mode'),
                initialValue: _mode,
                decoration: InputDecoration(
                  labelText: l10n.fieldPaymentMode,
                  errorText: _error?.firstErrorFor('payment_mode'),
                ),
                items: [
                  for (final mode in PaymentModes.all)
                    DropdownMenuItem(
                      // Keyed so a test can choose an option without tapping
                      // its translated label.
                      key: Key('donation-mode-$mode'),
                      value: mode,
                      child: Text(DonationFormatting.modeLabel(mode, l10n)),
                    ),
                ],
                onChanged: editable
                    ? (value) => setState(() => _mode = value ?? _mode)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Only for the modes it means anything for. Cash leaves nothing
              // to match against a statement, which is why it is the one mode
              // allowed to arrive without a reference.
              if (PaymentModes.requiresReference(_mode)) ...[
                _field(
                  'reference_number',
                  l10n.fieldReferenceNumber,
                  editable,
                  validator: (v) =>
                      Validators.notEmpty(v)?.localizedMessage(l10n),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.referenceHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],

              DropdownButtonFormField<String>(
                key: const Key('donation-purpose'),
                initialValue: _purpose,
                decoration: InputDecoration(labelText: l10n.fieldPurpose),
                items: [
                  for (final purpose in DonationPurposes.all)
                    DropdownMenuItem(
                      key: Key('donation-purpose-$purpose'),
                      value: purpose,
                      child: Text(
                        DonationFormatting.purposeLabel(purpose, l10n),
                      ),
                    ),
                ],
                onChanged: editable
                    ? (value) => setState(() => _purpose = value ?? _purpose)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              _field(
                'donor_phone',
                '${l10n.fieldDonorPhone} · ${l10n.fieldOptional}',
                editable,
                keyboardType: TextInputType.phone,
              ),
              _field(
                'donor_address',
                '${l10n.fieldDonorAddress} · ${l10n.fieldOptional}',
                editable,
                lines: 2,
              ),

              // The notes stay editable after a receipt is issued: they are the
              // one field that is about the record rather than on it.
              _field(
                'notes',
                '${l10n.fieldNotes} · ${l10n.fieldOptional}',
                canManage && !_saving,
                lines: 3,
              ),

              SwitchListTile(
                key: const Key('donation-anonymous'),
                contentPadding: EdgeInsets.zero,
                value: _anonymous,
                onChanged: editable
                    ? (value) => setState(() => _anonymous = value)
                    : null,
                title: Text(l10n.fieldAnonymous),
                subtitle: Text(l10n.anonymousHint),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (canManage) ...[
                    Expanded(
                      child: FilledButton(
                        key: const Key('donation-save'),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l10n.actionSave),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  TextButton(
                    onPressed: _saving
                        ? null
                        : () => context.go(RoutePaths.adminDonations),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),

              if (donation != null) ...[
                const SizedBox(height: AppSpacing.xl),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  children: [
                    if (canManage && donation.isPending)
                      FilledButton.tonalIcon(
                        key: const Key('donation-confirm'),
                        onPressed: _saving ? null : _confirm,
                        icon: const Icon(Icons.verified_outlined, size: 18),
                        label: Text(l10n.donationConfirm),
                      ),
                    if (donation.isLocked)
                      OutlinedButton.icon(
                        key: const Key('donation-print'),
                        onPressed: _printReceipt,
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: Text(l10n.donationPrintReceipt),
                      ),
                    if (canManage && !donation.isReversed)
                      TextButton.icon(
                        key: const Key('donation-reverse'),
                        onPressed: _saving ? null : _reverse,
                        icon: Icon(
                          Icons.undo,
                          size: 18,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          l10n.donationReverse,
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String name,
    String label,
    bool enabled, {
    TextInputType? keyboardType,
    int lines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('donation-$name'),
        controller: _fields[name],
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: lines,
        validator: enabled ? validator : null,
        decoration: InputDecoration(
          labelText: label,
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}

/// The receipt number, or what it is waiting for.
class _ReceiptLine extends ConsumerWidget {
  const _ReceiptLine({required this.donation});

  final Donation donation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final language = ref.watch(contentLanguageProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.fieldReceiptNumber,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            donation.receiptNumber ?? l10n.receiptNotIssued,
            key: const Key('donation-receipt-number'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontStyle: donation.receiptNumber == null
                  ? FontStyle.italic
                  : null,
              color: donation.receiptNumber == null
                  ? theme.colorScheme.onSurfaceVariant
                  : null,
            ),
          ),
          if (donation.confirmedAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${l10n.confirmedByLabel}: '
              '${DonationFormatting.timestamp(donation.confirmedAt, language)}'
              '${donation.confirmedBy == null ? '' : ' · ${donation.confirmedBy}'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A read-only field that opens the date picker.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
    this.error,
  });

  final String label;
  final String value;
  final String? error;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('donation-date'),
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
        ),
        child: Text(value),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.noticeKey,
    required this.background,
    required this.foreground,
    required this.text,
  });

  final Key noticeKey;
  final Color background;
  final Color foreground;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    key: noticeKey,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium
          ?.copyWith(color: foreground),
    ),
  );
}
