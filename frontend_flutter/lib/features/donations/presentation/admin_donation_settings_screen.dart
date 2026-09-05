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
import '../../media/presentation/widgets/media_picker_field.dart';
import '../data/donation_providers.dart';
import '../domain/donation.dart';

/// The UPI, bank details and QR code shown on the public donation page.
///
/// Editing needs `donations.manage`, not `content.manage`. Changing the
/// published UPI id is the single most valuable attack on this site, so it sits
/// behind the money permission: a compromised Content Manager account can
/// rewrite the About page and must not be able to redirect the temple's
/// donations (PHASE_6_PLAN assumption N6).
class AdminDonationSettingsScreen extends ConsumerWidget {
  const AdminDonationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(donationSettingsProvider);

    return settings.when(
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
          onRetry: () => ref.invalidate(donationSettingsProvider),
        );
      },
      data: (data) => _SettingsForm(settings: data),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final AdminDonationSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'upi_id',
      'bank_name',
      'account_name',
      'account_number',
      'ifsc',
      'qr_url',
      'intro_hi',
      'intro_en',
      'note_hi',
      'note_en',
    ])
      name: TextEditingController(),
  };

  late bool _published;
  bool _saving = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();

    final settings = widget.settings;
    _published = settings.isPublished;

    _fields['upi_id']!.text = settings.upiId ?? '';
    _fields['bank_name']!.text = settings.bankName ?? '';
    _fields['account_name']!.text = settings.accountName ?? '';
    _fields['account_number']!.text = settings.accountNumber ?? '';
    _fields['ifsc']!.text = settings.ifsc ?? '';
    _fields['qr_url']!.text = settings.qrUrl ?? '';
    _fields['intro_hi']!.text = settings.introHi ?? '';
    _fields['intro_en']!.text = settings.introEn ?? '';
    _fields['note_hi']!.text = settings.noteHi ?? '';
    _fields['note_en']!.text = settings.noteEn ?? '';
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _text(String name) {
    final value = _fields[name]!.text.trim();
    return value.isEmpty ? null : value;
  }

  /// True when the block is marked published but there is nothing payable in
  /// it — which would render an empty box on the public page.
  bool get _publishedButEmpty =>
      _published &&
      _text('upi_id') == null &&
      _text('bank_name') == null &&
      _text('account_number') == null &&
      _text('qr_url') == null;

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(donationRepositoryProvider)
          .saveSettings(
            DonationSettingsDraft(
              upiId: _text('upi_id'),
              bankName: _text('bank_name'),
              accountName: _text('account_name'),
              accountNumber: _text('account_number'),
              ifsc: _text('ifsc'),
              qrUrl: _text('qr_url'),
              introHi: _text('intro_hi'),
              introEn: _text('intro_en'),
              noteHi: _text('note_hi'),
              noteEn: _text('note_en'),
              isPublished: _published,
            ),
          );

      ref.invalidate(donationSettingsProvider);
      ref.invalidate(donationDetailsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.donationSettingsSaved)),
        );
        context.go(RoutePaths.adminDonations);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canEdit = ref
        .watch(permissionsProvider)
        .can(Permissions.donationsManage);
    final enabled = canEdit && !_saving;

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.donationSettingsTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.donationSettingsSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!canEdit) ...[
                _Panel(
                  panelKey: const Key('donation-settings-read-only'),
                  background: theme.colorScheme.secondaryContainer,
                  foreground: theme.colorScheme.onSecondaryContainer,
                  text: l10n.stateUnauthorizedBody,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_error != null) ...[
                _Panel(
                  panelKey: const Key('donation-settings-error'),
                  background: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                  text: _error!.localizedMessage(l10n),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              _field('upi_id', l10n.fieldUpiId, enabled),
              _field('bank_name', l10n.fieldBankName, enabled),
              _field('account_name', l10n.fieldAccountName, enabled),
              _field('account_number', l10n.fieldAccountNumber, enabled),
              _field('ifsc', l10n.fieldIfsc, enabled),

              // Chosen from the media library, and registered with the Phase 5
              // deletion guard: a QR code the donation page is showing cannot be
              // deleted out from under it.
              MediaPickerField(
                fieldKey: const ValueKey('donation-qr_url'),
                controller: _fields['qr_url']!,
                label: '${l10n.fieldQrImage} · ${l10n.fieldOptional}',
                enabled: enabled,
                errorText: _error?.firstErrorFor('qr_url'),
                onChanged: () => setState(() {}),
              ),

              _field('intro_hi', l10n.fieldDonateIntroHindi, enabled, lines: 3),
              _field(
                'intro_en',
                '${l10n.fieldDonateIntroEnglish} · ${l10n.fieldOptional}',
                enabled,
                lines: 3,
              ),
              _field('note_hi', l10n.fieldDonateNoteHindi, enabled, lines: 2),
              _field(
                'note_en',
                '${l10n.fieldDonateNoteEnglish} · ${l10n.fieldOptional}',
                enabled,
                lines: 2,
              ),

              SwitchListTile(
                key: const Key('donation-settings-publish'),
                contentPadding: EdgeInsets.zero,
                value: _published,
                onChanged: enabled
                    ? (value) => setState(() => _published = value)
                    : null,
                title: Text(l10n.fieldPublishDonationDetails),
              ),

              // Published with nothing payable in it renders an empty box on
              // the public page, which reads as a broken site rather than an
              // unconfigured one. Said here, before it is saved.
              if (_publishedButEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _Panel(
                  panelKey: const Key('donation-settings-incomplete'),
                  background: theme.colorScheme.tertiaryContainer,
                  foreground: theme.colorScheme.onTertiaryContainer,
                  text: l10n.donationSettingsIncomplete,
                ),
              ],

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (canEdit) ...[
                    Expanded(
                      child: FilledButton(
                        key: const Key('donation-settings-save'),
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
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String name, String label, bool enabled, {int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('donation-settings-$name'),
        controller: _fields[name],
        enabled: enabled,
        maxLines: lines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.panelKey,
    required this.background,
    required this.foreground,
    required this.text,
  });

  final Key panelKey;
  final Color background;
  final Color foreground;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    key: panelKey,
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
