import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../data/content_providers.dart';
import '../domain/site_settings.dart';

/// Edits the site-wide content: hero tagline, footer and the temple's address.
///
/// Closes the gap left at the end of Phase 1, where this was reachable by API
/// but had no screen. The navigation menu is edited through the same endpoint
/// and is deliberately left for a later pass — replacing the whole menu needs a
/// reorderable editor rather than a text field.
class AdminSiteSettingsScreen extends ConsumerWidget {
  const AdminSiteSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(adminSiteSettingsProvider);

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
          onRetry: () => ref.invalidate(adminSiteSettingsProvider),
        );
      },
      data: (data) => _SettingsForm(settings: data),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.settings});

  final EditableSiteSettings settings;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  final _formKey = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _fields;

  bool _saving = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    final s = widget.settings;
    _fields = {
      'tagline_hi': TextEditingController(text: s.taglineHi ?? ''),
      'tagline_en': TextEditingController(text: s.taglineEn ?? ''),
      'footer_text_hi': TextEditingController(text: s.footerHi ?? ''),
      'footer_text_en': TextEditingController(text: s.footerEn ?? ''),
      'village': TextEditingController(text: s.village ?? ''),
      'panchayat': TextEditingController(text: s.panchayat ?? ''),
      'police_station': TextEditingController(text: s.policeStation ?? ''),
      'district': TextEditingController(text: s.district ?? ''),
      'state': TextEditingController(text: s.state ?? ''),
      'postal_code': TextEditingController(text: s.postalCode ?? ''),
      'contact_phone': TextEditingController(text: s.contactPhone ?? ''),
      'contact_email': TextEditingController(text: s.contactEmail ?? ''),
    };
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
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
          .read(contentRepositoryProvider)
          .saveSiteSettings(
            SiteSettingsDraft({
              for (final entry in _fields.entries) entry.key: entry.value.text,
            }),
          );

      // The public shell and home page read these, so refresh them or the
      // editor would save and still see the old header.
      ref.invalidate(adminSiteSettingsProvider);
      ref.invalidate(siteSettingsProvider);

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

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.siteSettingsTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.siteSettingsSubtitle,
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

              if (_error != null) ...[
                Container(
                  key: const Key('settings-error'),
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

              _field('tagline_hi', '${l10n.fieldTagline} (हिन्दी)'),
              _field(
                'tagline_en',
                '${l10n.fieldTagline} (English) · ${l10n.fieldOptional}',
              ),
              _field(
                'footer_text_hi',
                '${l10n.fieldFooter} (हिन्दी) · ${l10n.fieldOptional}',
              ),
              _field(
                'footer_text_en',
                '${l10n.fieldFooter} (English) · ${l10n.fieldOptional}',
              ),

              const SizedBox(height: AppSpacing.md),
              Text(l10n.sectionAddress, style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.md),

              _field('village', l10n.fieldVillage),
              _field('panchayat', l10n.fieldPanchayat),
              _field('police_station', l10n.fieldPoliceStation),
              _field('district', l10n.fieldDistrict),
              _field('state', l10n.fieldState),
              _field('postal_code', l10n.fieldPostalCode),
              _field('contact_phone', l10n.fieldContactPhone),
              _field(
                'contact_email',
                l10n.fieldContactEmail,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('settings-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.actionSave),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
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

  Widget _field(String name, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('settings-$name'),
        controller: _fields[name],
        enabled: !_saving,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          // Server-side field errors take precedence: the API validates e-mail
          // and URL formats that this form does not attempt to re-implement.
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}
