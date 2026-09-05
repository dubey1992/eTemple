import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/localization/locale_controller.dart';
import '../../../app/localization/message_translations.dart';
import '../../../app/routing/route_paths.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../data/content_providers.dart';
import '../domain/content_repository.dart';
import '../domain/page_content.dart';

/// Edits one CMS page in both languages.
///
/// Hindi is the source language and is required; English is optional, and the
/// form says so rather than silently accepting a half-translated page. The
/// server validates the same rules regardless of what this form allows.
class AdminPageEditorScreen extends ConsumerWidget {
  const AdminPageEditorScreen({super.key, required this.pageId});

  final int pageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(adminPageProvider(pageId));

    return page.when(
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
          onRetry: () => ref.invalidate(adminPageProvider(pageId)),
        );
      },
      // Keyed by id so switching pages rebuilds the form with fresh controllers
      // instead of carrying the previous page's text across.
      data: (data) => _EditorForm(key: ValueKey(data.id), page: data),
    );
  }
}

class _EditorForm extends ConsumerStatefulWidget {
  const _EditorForm({super.key, required this.page});

  final EditablePage page;

  @override
  ConsumerState<_EditorForm> createState() => _EditorFormState();
}

class _EditorFormState extends ConsumerState<_EditorForm> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleHi;
  late final TextEditingController _titleEn;
  late final TextEditingController _contentHi;
  late final TextEditingController _contentEn;
  late final TextEditingController _metaTitleHi;
  late final TextEditingController _metaDescriptionHi;

  late PageStatus _status;
  bool _saving = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    final page = widget.page;
    _titleHi = TextEditingController(text: page.titleHi);
    _titleEn = TextEditingController(text: page.titleEn ?? '');
    _contentHi = TextEditingController(text: page.contentHi);
    _contentEn = TextEditingController(text: page.contentEn ?? '');
    _metaTitleHi = TextEditingController(text: page.metaTitleHi ?? '');
    _metaDescriptionHi = TextEditingController(
      text: page.metaDescriptionHi ?? '',
    );
    _status = page.status;
  }

  @override
  void dispose() {
    for (final c in [
      _titleHi,
      _titleEn,
      _contentHi,
      _contentEn,
      _metaTitleHi,
      _metaDescriptionHi,
    ]) {
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
          .savePage(
            widget.page.id,
            EditablePageDraft(
              titleHi: _titleHi.text,
              titleEn: _titleEn.text,
              contentHi: _contentHi.text,
              contentEn: _contentEn.text,
              metaTitleHi: _metaTitleHi.text,
              metaDescriptionHi: _metaDescriptionHi.text,
              status: _status,
            ),
          );

      // The public site reads through these providers, so invalidate them or an
      // editor would save and still see the old page.
      ref.invalidate(adminPagesProvider);
      ref.invalidate(adminPageProvider(widget.page.id));
      ref.invalidate(pageProvider(widget.page.slug));
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
              Text(l10n.adminEditPage, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '/${widget.page.slug}',
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
                  key: const Key('editor-error'),
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

              _Field(
                fieldKey: const Key('editor-title-hi'),
                controller: _titleHi,
                label: l10n.fieldTitleHindi,
                enabled: !_saving,
                serverError: _error?.firstErrorFor('title_hi'),
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _Field(
                fieldKey: const Key('editor-title-en'),
                controller: _titleEn,
                label: '${l10n.fieldTitleEnglish} · ${l10n.fieldOptional}',
                enabled: !_saving,
                serverError: _error?.firstErrorFor('title_en'),
              ),
              _Field(
                fieldKey: const Key('editor-content-hi'),
                controller: _contentHi,
                label: l10n.fieldContentHindi,
                enabled: !_saving,
                maxLines: 8,
                serverError: _error?.firstErrorFor('content_hi'),
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _Field(
                fieldKey: const Key('editor-content-en'),
                controller: _contentEn,
                label: '${l10n.fieldContentEnglish} · ${l10n.fieldOptional}',
                enabled: !_saving,
                maxLines: 8,
                serverError: _error?.firstErrorFor('content_en'),
              ),
              // The card convention, stated where somebody writing a page can
              // see it. Without this the three About cards look like magic
              // that only the developer knows how to reproduce.
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.pageCardsHint,
                  key: const Key('editor-cards-hint'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _Field(
                fieldKey: const Key('editor-meta-title'),
                controller: _metaTitleHi,
                label: '${l10n.fieldMetaTitle} · ${l10n.fieldOptional}',
                enabled: !_saving,
              ),
              _Field(
                fieldKey: const Key('editor-meta-description'),
                controller: _metaDescriptionHi,
                label: '${l10n.fieldMetaDescription} · ${l10n.fieldOptional}',
                enabled: !_saving,
                maxLines: 3,
              ),

              SwitchListTile(
                key: const Key('editor-status'),
                contentPadding: EdgeInsets.zero,
                value: _status == PageStatus.published,
                onChanged: _saving
                    ? null
                    : (on) => setState(
                        () => _status = on
                            ? PageStatus.published
                            : PageStatus.draft,
                      ),
                title: Text(
                  _status == PageStatus.published
                      ? l10n.statusPublished
                      : l10n.statusDraft,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      key: const Key('editor-save'),
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
                        : () => context.go(RoutePaths.adminPages),
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
}

class _Field extends StatelessWidget {
  const _Field({
    required this.fieldKey,
    required this.controller,
    required this.label,
    required this.enabled,
    this.maxLines = 1,
    this.serverError,
    this.validator,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;
  final bool enabled;
  final int maxLines;
  final String? serverError;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
          errorText: serverError,
        ),
        validator: validator,
      ),
    );
  }
}
