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
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../data/temple_providers.dart';
import '../domain/committee_member.dart';

/// Creates or edits one committee member.
///
/// The consent block is the part that matters. The three visibility switches
/// are inert until consent is recorded, and turning consent off turns all three
/// off here as well — mirroring what the server does, so the editor sees the
/// same outcome the API will produce rather than a form that looks like it
/// disagrees with the result.
///
/// The mirroring is a courtesy, not the control: the server refuses the
/// combination regardless of what this form sends.
class AdminCommitteeMemberScreen extends ConsumerWidget {
  const AdminCommitteeMemberScreen({super.key, this.memberId});

  final int? memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = memberId;
    if (id == null) return const _MemberForm(member: null);

    final member = ref.watch(adminCommitteeMemberProvider(id));

    return member.when(
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
          onRetry: () => ref.invalidate(adminCommitteeMemberProvider(id)),
        );
      },
      data: (data) => _MemberForm(member: data),
    );
  }
}

class _MemberForm extends ConsumerStatefulWidget {
  const _MemberForm({required this.member});

  final AdminCommitteeMember? member;

  @override
  ConsumerState<_MemberForm> createState() => _MemberFormState();
}

class _MemberFormState extends ConsumerState<_MemberForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;

  late bool _isPublished;
  late bool _hasConsent;
  late bool _showPhone;
  late bool _showEmail;
  late bool _showPhoto;

  bool _saving = false;
  AppException? _error;

  bool get _isNew => widget.member == null;

  @override
  void initState() {
    super.initState();
    final m = widget.member;

    _fields = {
      'name_hi': TextEditingController(text: m?.nameHi ?? ''),
      'name_en': TextEditingController(text: m?.nameEn ?? ''),
      'designation_hi': TextEditingController(text: m?.designationHi ?? ''),
      'designation_en': TextEditingController(text: m?.designationEn ?? ''),
      'bio_hi': TextEditingController(text: m?.bioHi ?? ''),
      'bio_en': TextEditingController(text: m?.bioEn ?? ''),
      'phone': TextEditingController(text: m?.phone ?? ''),
      'email': TextEditingController(text: m?.email ?? ''),
      'photo_url': TextEditingController(text: m?.photoUrl ?? ''),
      'tenure_start': TextEditingController(text: m?.tenureStart ?? ''),
      'tenure_end': TextEditingController(text: m?.tenureEnd ?? ''),
      'sort_order': TextEditingController(text: '${m?.sortOrder ?? 0}'),
    };

    // A new member starts unpublished and unconsented. Publishing a person is
    // a decision somebody has to make on purpose.
    _isPublished = m?.isPublished ?? false;
    _hasConsent = m?.hasConsent ?? false;
    _showPhone = m?.showPhonePublicly ?? false;
    _showEmail = m?.showEmailPublicly ?? false;
    _showPhoto = m?.showPhotoPublicly ?? false;
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _setConsent(bool value) {
    setState(() {
      _hasConsent = value;
      if (!value) {
        // Withdrawal clears all three, exactly as the server does.
        _showPhone = false;
        _showEmail = false;
        _showPhoto = false;
      }
    });
  }

  CommitteeMemberDraft _draft() => CommitteeMemberDraft(
    nameHi: _fields['name_hi']!.text,
    nameEn: _fields['name_en']!.text,
    designationHi: _fields['designation_hi']!.text,
    designationEn: _fields['designation_en']!.text,
    bioHi: _fields['bio_hi']!.text,
    bioEn: _fields['bio_en']!.text,
    phone: _fields['phone']!.text,
    email: _fields['email']!.text,
    photoUrl: _fields['photo_url']!.text,
    tenureStart: _fields['tenure_start']!.text,
    tenureEnd: _fields['tenure_end']!.text,
    isPublished: _isPublished,
    hasConsent: _hasConsent,
    showPhonePublicly: _showPhone,
    showEmailPublicly: _showEmail,
    showPhotoPublicly: _showPhoto,
    sortOrder: int.tryParse(_fields['sort_order']!.text.trim()) ?? 0,
  );

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(templeRepositoryProvider);
      final member = widget.member;

      if (member == null) {
        await repository.createMember(_draft());
      } else {
        await repository.saveMember(member.id, _draft());
        ref.invalidate(adminCommitteeMemberProvider(member.id));
      }

      ref.invalidate(adminCommitteeProvider);
      // The public committee page reads the same records.
      ref.invalidate(committeeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              member == null
                  ? context.l10n.memberCreated
                  : context.l10n.saveSuccess,
            ),
          ),
        );
        context.go(RoutePaths.adminCommittee);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final member = widget.member;
    if (member == null || _saving) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('member-delete-dialog'),
        title: Text(l10n.memberDeleteConfirmTitle),
        content: Text(l10n.memberDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('member-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(templeRepositoryProvider).deleteMember(member.id);
      ref.invalidate(adminCommitteeProvider);
      ref.invalidate(committeeProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.memberDeleted)));
        context.go(RoutePaths.adminCommittee);
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
    // Watched, not read — the session resolves after the first build.
    final canEdit = ref
        .watch(permissionsProvider)
        .can(Permissions.templeManage);
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
                _isNew ? l10n.memberCreate : l10n.memberEdit,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.hindiRequiredHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (!canEdit) ...[
                Container(
                  key: const Key('member-read-only'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    l10n.stateUnauthorizedBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_error != null) ...[
                Container(
                  key: const Key('member-error'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!.localizedMessage(l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      // A refusal against a consent switch has no text field to
                      // attach itself to, so it would otherwise be reduced to
                      // the generic "there is an error in what you entered".
                      for (final message in _errorsWithoutAField())
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            message,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              _field(
                'name_hi',
                '${l10n.fieldName} (हिन्दी)',
                enabled,
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _field(
                'name_en',
                '${l10n.fieldName} (English) · ${l10n.fieldOptional}',
                enabled,
              ),
              _field(
                'designation_hi',
                '${l10n.fieldDesignation} (हिन्दी)',
                enabled,
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _field(
                'designation_en',
                '${l10n.fieldDesignation} (English) · ${l10n.fieldOptional}',
                enabled,
              ),
              _field(
                'bio_hi',
                '${l10n.fieldBio} (हिन्दी) · ${l10n.fieldOptional}',
                enabled,
                lines: 4,
              ),
              _field(
                'bio_en',
                '${l10n.fieldBio} (English) · ${l10n.fieldOptional}',
                enabled,
                lines: 4,
              ),

              const SizedBox(height: AppSpacing.sm),
              Text(l10n.sectionTenure, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),
              _field(
                'tenure_start',
                '${l10n.fieldTenureStart} · ${l10n.dateHint}',
                enabled,
              ),
              _field(
                'tenure_end',
                '${l10n.fieldTenureEnd} · ${l10n.dateHint}',
                enabled,
              ),
              _field(
                'sort_order',
                l10n.fieldSortOrder,
                enabled,
                keyboardType: TextInputType.number,
              ),

              SwitchListTile(
                key: const Key('member-published'),
                contentPadding: EdgeInsets.zero,
                value: _isPublished,
                onChanged: enabled
                    ? (v) => setState(() => _isPublished = v)
                    : null,
                title: Text(l10n.fieldPublished),
              ),

              const SizedBox(height: AppSpacing.lg),
              _ConsentSection(
                enabled: enabled,
                hasConsent: _hasConsent,
                consentRecordedAt: widget.member?.consentRecordedAt,
                showPhone: _showPhone,
                showEmail: _showEmail,
                showPhoto: _showPhoto,
                onConsentChanged: _setConsent,
                onShowPhoneChanged: (v) => setState(() => _showPhone = v),
                onShowEmailChanged: (v) => setState(() => _showEmail = v),
                onShowPhotoChanged: (v) => setState(() => _showPhoto = v),
                phoneField: _field(
                  'phone',
                  '${l10n.fieldPhone} · ${l10n.fieldOptional}',
                  enabled,
                  keyboardType: TextInputType.phone,
                ),
                emailField: _field(
                  'email',
                  '${l10n.fieldEmail} · ${l10n.fieldOptional}',
                  enabled,
                  keyboardType: TextInputType.emailAddress,
                ),
                photoField: _field(
                  'photo_url',
                  '${l10n.fieldPhotoUrl} · ${l10n.fieldOptional}',
                  enabled,
                  keyboardType: TextInputType.url,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (canEdit) ...[
                    Expanded(
                      child: FilledButton(
                        key: const Key('member-save'),
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
                        : () => context.go(RoutePaths.adminCommittee),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),

              if (canEdit && !_isNew) ...[
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('member-delete'),
                    onPressed: _saving ? null : _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      l10n.memberDelete,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }

  /// Server field errors for anything that is not one of the text inputs —
  /// in practice the publication and consent switches.
  List<String> _errorsWithoutAField() {
    final fieldErrors = _error?.fieldErrors;
    if (fieldErrors == null) return const [];

    return [
      for (final entry in fieldErrors.entries)
        if (!_fields.containsKey(entry.key))
          for (final message in entry.value) message,
    ];
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
        key: Key('member-$name'),
        controller: _fields[name],
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: lines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          // Server-side field errors take precedence: the guard refusals name
          // the exact switch that was rejected.
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}

/// The consent block: what is on file, and what may therefore be published.
class _ConsentSection extends StatelessWidget {
  const _ConsentSection({
    required this.enabled,
    required this.hasConsent,
    required this.consentRecordedAt,
    required this.showPhone,
    required this.showEmail,
    required this.showPhoto,
    required this.onConsentChanged,
    required this.onShowPhoneChanged,
    required this.onShowEmailChanged,
    required this.onShowPhotoChanged,
    required this.phoneField,
    required this.emailField,
    required this.photoField,
  });

  final bool enabled;
  final bool hasConsent;
  final String? consentRecordedAt;
  final bool showPhone;
  final bool showEmail;
  final bool showPhoto;
  final ValueChanged<bool> onConsentChanged;
  final ValueChanged<bool> onShowPhoneChanged;
  final ValueChanged<bool> onShowEmailChanged;
  final ValueChanged<bool> onShowPhotoChanged;
  final Widget phoneField;
  final Widget emailField;
  final Widget photoField;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Card(
      key: const Key('member-consent'),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.consentTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.consentExplain,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            phoneField,
            emailField,
            photoField,

            SwitchListTile(
              key: const Key('member-has-consent'),
              contentPadding: EdgeInsets.zero,
              value: hasConsent,
              onChanged: enabled ? onConsentChanged : null,
              title: Text(l10n.consentRecorded),
              subtitle: (hasConsent && consentRecordedAt != null)
                  ? Text(l10n.consentRecordedOn(_date(consentRecordedAt!)))
                  : null,
            ),

            if (!hasConsent)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.consentMissingHint,
                  key: const Key('member-consent-missing'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),

            SwitchListTile(
              key: const Key('member-show-phone'),
              contentPadding: EdgeInsets.zero,
              value: showPhone,
              // Inert without consent, in both directions: the switch cannot be
              // turned on, and the server would refuse it anyway.
              onChanged: enabled && hasConsent ? onShowPhoneChanged : null,
              title: Text(l10n.showPhonePublicly),
            ),
            SwitchListTile(
              key: const Key('member-show-email'),
              contentPadding: EdgeInsets.zero,
              value: showEmail,
              onChanged: enabled && hasConsent ? onShowEmailChanged : null,
              title: Text(l10n.showEmailPublicly),
            ),
            SwitchListTile(
              key: const Key('member-show-photo'),
              contentPadding: EdgeInsets.zero,
              value: showPhoto,
              onChanged: enabled && hasConsent ? onShowPhotoChanged : null,
              title: Text(l10n.showPhotoPublicly),
            ),
          ],
        ),
      ),
    );
  }

  /// The date part of an ISO timestamp; the time of day is not useful here.
  static String _date(String isoTimestamp) {
    final t = isoTimestamp.indexOf('T');
    return t == -1 ? isoTimestamp : isoTimestamp.substring(0, t);
  }
}
