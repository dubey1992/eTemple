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
import '../data/media_providers.dart';
import '../domain/media_item.dart';
import 'media_formatting.dart';

/// Creates and edits an album.
///
/// Deleting one never deletes its photographs, and the confirmation says so —
/// an album is an arrangement, and a committee member removing an arrangement
/// should not have to wonder whether they just lost the Janmashtami pictures.
class AdminAlbumEditorScreen extends ConsumerWidget {
  const AdminAlbumEditorScreen({super.key, this.albumId});

  final int? albumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = albumId;
    if (id == null) return const _AlbumForm();

    final albums = ref.watch(adminAlbumsProvider);

    return albums.when(
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
          onRetry: () => ref.invalidate(adminAlbumsProvider),
        );
      },
      data: (data) {
        final album = data.where((a) => a.id == id).firstOrNull;
        if (album == null) {
          return EmptyView(
            key: const Key('album-not-found'),
            message: context.l10n.notFoundBody,
            icon: Icons.collections_bookmark_outlined,
          );
        }
        return _AlbumForm(album: album);
      },
    );
  }
}

class _AlbumForm extends ConsumerStatefulWidget {
  const _AlbumForm({this.album});

  final AdminAlbum? album;

  @override
  ConsumerState<_AlbumForm> createState() => _AlbumFormState();
}

class _AlbumFormState extends ConsumerState<_AlbumForm> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'title_hi',
      'title_en',
      'description_hi',
      'description_en',
      'slug',
    ])
      name: TextEditingController(),
  };

  late String _status;
  int? _coverId;
  bool _saving = false;
  AppException? _error;

  bool get _isNew => widget.album == null;

  @override
  void initState() {
    super.initState();

    final album = widget.album;
    _status = album?.status ?? MediaStatuses.draft;
    _coverId = album?.coverMediaId;

    if (album != null) {
      _fields['title_hi']!.text = album.titleHi;
      _fields['title_en']!.text = album.titleEn ?? '';
      _fields['description_hi']!.text = album.descriptionHi ?? '';
      _fields['description_en']!.text = album.descriptionEn ?? '';
      _fields['slug']!.text = album.slug;
    }
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

  AlbumDraft _draft() => AlbumDraft(
    titleHi: _fields['title_hi']!.text,
    titleEn: _text('title_en'),
    descriptionHi: _text('description_hi'),
    descriptionEn: _text('description_en'),
    slug: _text('slug'),
    coverMediaId: _coverId,
    status: _status,
  );

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final album = widget.album;

      if (album == null) {
        await repository.createAlbum(_draft());
      } else {
        await repository.saveAlbum(album.id, _draft());
      }

      _refreshLists();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveSuccess)));
        context.go(RoutePaths.adminAlbums);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final album = widget.album;
    if (album == null || _saving) return;

    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('album-delete-dialog'),
        title: Text(l10n.albumDeleteConfirmTitle),
        content: Text(l10n.albumDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('album-delete-confirm'),
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
      await ref.read(mediaRepositoryProvider).deleteAlbum(album.id);
      _refreshLists();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.albumDeleted)));
        context.go(RoutePaths.adminAlbums);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Photographs move between albums as a side effect of this screen, so the
  /// library and the public gallery are both refreshed, not just the list.
  void _refreshLists() {
    ref.invalidate(adminAlbumsProvider);
    ref.invalidate(albumsProvider);
    ref.invalidate(galleryProvider);
    for (final status in <String?>[
      null,
      MediaStatuses.published,
      MediaStatuses.draft,
    ]) {
      ref.invalidate(adminMediaProvider(AdminMediaQuery(status: status)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final canEdit = ref.watch(permissionsProvider).can(Permissions.mediaManage);
    final enabled = canEdit && !_saving;
    final photos = ref.watch(pickerPhotosProvider).value ?? const [];

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? l10n.albumNew : l10n.albumEdit,
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
                  key: const Key('album-read-only'),
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
                  key: const Key('album-error'),
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

              _field(
                'title_hi',
                l10n.fieldTitleHindi,
                enabled,
                validator: (v) =>
                    Validators.notEmpty(v)?.localizedMessage(l10n),
              ),
              _field(
                'title_en',
                '${l10n.fieldTitleEnglish} · ${l10n.fieldOptional}',
                enabled,
              ),
              _field(
                'description_hi',
                '${l10n.fieldDescriptionHindi} · ${l10n.fieldOptional}',
                enabled,
                lines: 3,
              ),
              _field(
                'description_en',
                '${l10n.fieldDescriptionEnglish} · ${l10n.fieldOptional}',
                enabled,
                lines: 3,
              ),
              _field(
                'slug',
                '${l10n.fieldSlug} · ${l10n.fieldOptional}',
                enabled,
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Text(
                  l10n.slugHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              DropdownButtonFormField<int?>(
                key: const Key('album-cover'),
                initialValue: photos.any((p) => p.id == _coverId)
                    ? _coverId
                    : null,
                decoration: InputDecoration(labelText: l10n.fieldCoverPhoto),
                items: [
                  DropdownMenuItem(
                    key: const Key('album-cover-none'),
                    value: null,
                    child: Text(l10n.albumNone),
                  ),
                  for (final photo in photos)
                    DropdownMenuItem(
                      key: Key('album-cover-${photo.id}'),
                      value: photo.id,
                      child: Text(photo.titleHi),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _coverId = value)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                key: const Key('album-status'),
                initialValue: _status,
                decoration: InputDecoration(labelText: l10n.fieldStatus),
                items: [
                  for (final status in MediaStatuses.all)
                    DropdownMenuItem(
                      key: Key('album-status-$status'),
                      value: status,
                      child: Text(MediaFormatting.statusLabel(status, l10n)),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _status = value ?? _status)
                    : null,
              ),

              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (canEdit) ...[
                    Expanded(
                      child: FilledButton(
                        key: const Key('album-save'),
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
                        : () => context.go(RoutePaths.adminAlbums),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),

              if (canEdit && !_isNew) ...[
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('album-delete'),
                    onPressed: _saving ? null : _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      l10n.albumDelete,
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

  Widget _field(
    String name,
    String label,
    bool enabled, {
    int lines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('album-$name'),
        controller: _fields[name],
        enabled: enabled,
        maxLines: lines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          errorText: _error?.firstErrorFor(name),
        ),
      ),
    );
  }
}
