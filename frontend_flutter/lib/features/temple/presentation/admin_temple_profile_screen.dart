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
import '../data/temple_providers.dart';
import '../domain/temple_profile.dart';

/// Edits the temple's own identity: its name, address, history and mission.
///
/// This screen owns the temple's name. Before Phase 3 it was compiled into the
/// app's ARB files; what is typed here is what the public header, the browser
/// tab and the footer show.
class AdminTempleProfileScreen extends ConsumerWidget {
  const AdminTempleProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(adminTempleProfileProvider);

    return profile.when(
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
          onRetry: () => ref.invalidate(adminTempleProfileProvider),
        );
      },
      data: (data) => _ProfileForm(profile: data),
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.profile});

  final EditableTempleProfile profile;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;

  bool _saving = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _fields = {
      for (final field in EditableTempleProfile.fields)
        field: TextEditingController(text: widget.profile[field]),
    };
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(templeRepositoryProvider)
          .saveProfile(
            TempleProfileDraft({
              for (final entry in _fields.entries) entry.key: entry.value.text,
            }),
          );

      // The public shell, hero and footer read the profile, so refresh it or
      // the editor would save the temple's name and still see the old header.
      ref.invalidate(adminTempleProfileProvider);
      ref.invalidate(templeProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveSuccess)));
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
    // Watched, not read: the session resolves after the first build, so a read
    // here would evaluate before the permissions arrive and never re-evaluate.
    final canEdit = ref
        .watch(permissionsProvider)
        .can(Permissions.templeManage);

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.templeProfileTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.templeProfileSubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
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
                _Notice(
                  key: const Key('temple-read-only'),
                  message: l10n.stateUnauthorizedBody,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_error != null) ...[
                Container(
                  key: const Key('temple-error'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _error!.localizedMessage(l10n),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              _sectionHeading(l10n.sectionIdentity),
              _field('name_hi', '${l10n.fieldTempleName} (हिन्दी)', canEdit),
              _field(
                'name_en',
                '${l10n.fieldTempleName} (English) · ${l10n.fieldOptional}',
                canEdit,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.templeNameHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _field(
                'established_year',
                '${l10n.fieldEstablishedYear} · ${l10n.fieldOptional}',
                canEdit,
                keyboardType: TextInputType.number,
              ),
              _field(
                'logo_url',
                '${l10n.fieldLogoUrl} · ${l10n.fieldOptional}',
                canEdit,
                keyboardType: TextInputType.url,
              ),

              _sectionHeading(l10n.sectionAddress),
              _field('address_line1', l10n.fieldAddressLine1, canEdit),
              _field('address_line2', l10n.fieldAddressLine2, canEdit),
              _field('village', l10n.fieldVillage, canEdit),
              _field('panchayat', l10n.fieldPanchayat, canEdit),
              _field('police_station', l10n.fieldPoliceStation, canEdit),
              _field('district', l10n.fieldDistrict, canEdit),
              _field('state', l10n.fieldState, canEdit),
              _field('postal_code', l10n.fieldPostalCode, canEdit),
              _field('country', l10n.fieldCountry, canEdit),
              _field(
                'map_url',
                '${l10n.fieldMapUrl} · ${l10n.fieldOptional}',
                canEdit,
                keyboardType: TextInputType.url,
              ),

              _sectionHeading(l10n.sectionHistory),
              _field(
                'history_hi',
                '${l10n.fieldHistory} (हिन्दी)',
                canEdit,
                lines: 6,
              ),
              _field(
                'history_en',
                '${l10n.fieldHistory} (English) · ${l10n.fieldOptional}',
                canEdit,
                lines: 6,
              ),

              _sectionHeading(l10n.sectionMission),
              _field(
                'mission_hi',
                '${l10n.fieldMission} (हिन्दी)',
                canEdit,
                lines: 4,
              ),
              _field(
                'mission_en',
                '${l10n.fieldMission} (English) · ${l10n.fieldOptional}',
                canEdit,
                lines: 4,
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (canEdit) ...[
                    Expanded(
                      child: FilledButton(
                        key: const Key('temple-save'),
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
                        : () => context.go(RoutePaths.admin),
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

  Widget _sectionHeading(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _field(
    String name,
    String label,
    bool canEdit, {
    TextInputType? keyboardType,
    int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('temple-$name'),
        controller: _fields[name],
        enabled: canEdit && !_saving,
        keyboardType: keyboardType,
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          // Server-side field errors take precedence: the API validates URL and
          // year ranges that this form does not attempt to re-implement.
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lock_outline,
            size: 20,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
