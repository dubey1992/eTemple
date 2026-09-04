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
import '../../../core/files/file_chooser.dart';
import '../../../core/files/picked_file.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/page_container.dart';
import '../../../core/widgets/state_views.dart';
import '../../admin/data/admin_providers.dart';
import '../data/media_providers.dart';
import '../domain/media_item.dart';
import 'media_formatting.dart';
import 'widgets/media_image.dart';

/// Adds a photograph or a video link, and edits either.
///
/// Two shapes, one screen: a photograph carries a file and a video carries a
/// link, and the form shows exactly the one that applies. Splitting them into
/// two screens would duplicate the title, caption, album and status fields —
/// which are the same question either way.
class AdminMediaEditorScreen extends ConsumerWidget {
  const AdminMediaEditorScreen({super.key, this.mediaId, this.chooser});

  final int? mediaId;

  /// Injectable so the upload path is exercisable off a browser, where the
  /// real chooser has no file dialogue to open.
  final FileChooser? chooser;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = mediaId;
    if (id == null) return _MediaForm(chooser: chooser);

    final item = ref.watch(adminMediaItemProvider(id));

    return item.when(
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
          onRetry: () => ref.invalidate(adminMediaItemProvider(id)),
        );
      },
      data: (data) => _MediaForm(item: data, chooser: chooser),
    );
  }
}

class _MediaForm extends ConsumerStatefulWidget {
  const _MediaForm({this.item, this.chooser});

  final AdminMedia? item;

  /// Injectable so the form is exercisable without a browser.
  final FileChooser? chooser;

  @override
  ConsumerState<_MediaForm> createState() => _MediaFormState();
}

class _MediaFormState extends ConsumerState<_MediaForm> {
  final _formKey = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'title_hi',
      'title_en',
      'caption_hi',
      'caption_en',
      'external_url',
    ])
      name: TextEditingController(),
  };

  late String _type;
  late String _status;
  int? _albumId;
  PickedFile? _picked;

  bool _saving = false;
  AppException? _error;
  MediaReferences? _blocked;

  bool get _isNew => widget.item == null;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _type = item?.mediaType ?? MediaTypes.photo;
    _status = item?.status ?? MediaStatuses.draft;
    _albumId = item?.albumId;

    if (item != null) {
      _fields['title_hi']!.text = item.titleHi;
      _fields['title_en']!.text = item.titleEn ?? '';
      _fields['caption_hi']!.text = item.captionHi ?? '';
      _fields['caption_en']!.text = item.captionEn ?? '';
      _fields['external_url']!.text = item.externalUrl ?? '';
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

  Future<void> _choose() async {
    final chooser = widget.chooser ?? const FileChooser();

    if (!chooser.isSupported) {
      setState(() => _error = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mediaChooserUnavailable)),
      );
      return;
    }

    final picked = await chooser.pickImage();
    if (!mounted || picked == null) return;

    setState(() {
      _picked = picked;
      // A file with no title yet gets the file's own name as a starting point;
      // it is only a suggestion and the committee overwrites it.
      if (_fields['title_hi']!.text.trim().isEmpty) {
        _fields['title_hi']!.text = picked.name;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final isPhotoUpload = _isNew && _type == MediaTypes.photo;
    if (isPhotoUpload && _picked == null) {
      setState(
        () => _error = const AppException(
          code: ErrorCode.validationFailed,
          fieldErrors: {'file': []},
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
      _blocked = null;
    });

    try {
      final repository = ref.read(mediaRepositoryProvider);
      final item = widget.item;

      if (item != null) {
        await repository.saveMedia(
          item.id,
          MediaDraft(
            titleHi: _fields['title_hi']!.text,
            titleEn: _text('title_en'),
            captionHi: _text('caption_hi'),
            captionEn: _text('caption_en'),
            externalUrl: _type == MediaTypes.video
                ? _text('external_url')
                : null,
            albumId: _albumId,
            status: _status,
          ),
        );
        ref.invalidate(adminMediaItemProvider(item.id));
      } else if (_type == MediaTypes.video) {
        await repository.createVideo(
          VideoDraft(
            externalUrl: _fields['external_url']!.text,
            titleHi: _fields['title_hi']!.text,
            titleEn: _text('title_en'),
            captionHi: _text('caption_hi'),
            captionEn: _text('caption_en'),
            albumId: _albumId,
            status: _status,
          ),
        );
      } else {
        final picked = _picked!;
        await repository.uploadPhoto(
          PhotoUpload(
            bytes: picked.bytes,
            fileName: picked.name,
            contentType: picked.mimeType,
            titleHi: _fields['title_hi']!.text,
            titleEn: _text('title_en'),
            captionHi: _text('caption_hi'),
            captionEn: _text('caption_en'),
            albumId: _albumId,
            status: _status,
          ),
        );
      }

      _refreshLists();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.saveSuccess)));
        context.go(RoutePaths.adminMedia);
      }
    } on AppException catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final item = widget.item;
    if (item == null || _saving) return;

    final l10n = context.l10n;

    // Asked before the button is honoured, so a blocked deletion is explained
    // rather than attempted and refused.
    setState(() {
      _saving = true;
      _error = null;
      _blocked = null;
    });

    MediaReferences references;
    try {
      references = await ref.read(mediaRepositoryProvider).references(item.id);
    } on AppException catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _saving = false;
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (!references.canDelete) {
      setState(() => _blocked = references);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('media-delete-dialog'),
        title: Text(l10n.mediaDeleteConfirmTitle),
        content: Text(l10n.mediaDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            key: const Key('media-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(mediaRepositoryProvider).deleteMedia(item.id);
      _refreshLists();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.mediaDeleted)));
        context.go(RoutePaths.adminMedia);
      }
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error);

      // The server checks again on the way in, so something added between the
      // question and the answer is still refused. Ask again rather than guess:
      // the point of the panel is to name what is in the way.
      if (error.code == ErrorCode.mediaInUse) {
        try {
          final refreshed = await ref
              .read(mediaRepositoryProvider)
              .references(item.id);
          if (mounted) setState(() => _blocked = refreshed);
        } on AppException {
          // The refusal itself has already been shown; a second failure here
          // must not replace it with a less useful message.
        }
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// The library is filtered several ways and the public gallery reads the same
  /// records, so every view of them is refreshed rather than just this one.
  void _refreshLists() {
    for (final status in <String?>[
      null,
      MediaStatuses.published,
      MediaStatuses.draft,
    ]) {
      for (final type in <String?>[null, MediaTypes.photo, MediaTypes.video]) {
        ref.invalidate(
          adminMediaProvider(AdminMediaQuery(status: status, type: type)),
        );
      }
    }
    ref.invalidate(galleryProvider);
    ref.invalidate(homeGalleryProvider);
    ref.invalidate(albumsProvider);
    ref.invalidate(adminAlbumsProvider);
    ref.invalidate(pickerPhotosProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // Watched, not read: the session resolves after the first build.
    final canEdit = ref.watch(permissionsProvider).can(Permissions.mediaManage);
    final enabled = canEdit && !_saving;
    final albums = ref.watch(adminAlbumsProvider).value ?? const [];

    return SingleChildScrollView(
      child: PageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isNew ? l10n.mediaNew : l10n.mediaEdit,
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
                _Notice(
                  noticeKey: const Key('media-read-only'),
                  background: theme.colorScheme.secondaryContainer,
                  foreground: theme.colorScheme.onSecondaryContainer,
                  child: Text(
                    l10n.stateUnauthorizedBody,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_blocked != null) ...[
                _Notice(
                  noticeKey: const Key('media-in-use'),
                  background: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mediaInUseTitle,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.mediaInUseBody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final reference in _blocked!.references)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '• ${MediaFormatting.referenceLabel(reference.type, l10n)}'
                            '${reference.label.isEmpty ? '' : ' — ${reference.label}'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ] else if (_error != null) ...[
                _Notice(
                  noticeKey: const Key('media-error'),
                  background: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _error!.localizedMessage(l10n),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                      // A refusal about the file itself has no text field to
                      // attach to, so it is spelled out here.
                      for (final message
                          in _error!.fieldErrors['file'] ?? const <String>[])
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

              // The kind is chosen once, at creation: an uploaded photograph
              // cannot become a link, and turning a link into a file would need
              // an upload the form no longer offers.
              if (_isNew) ...[
                SegmentedButton<String>(
                  key: const Key('media-kind'),
                  segments: [
                    ButtonSegment(
                      value: MediaTypes.photo,
                      label: Text(l10n.mediaTypePhoto),
                      icon: const Icon(Icons.image_outlined, size: 18),
                    ),
                    ButtonSegment(
                      value: MediaTypes.video,
                      label: Text(l10n.mediaTypeVideo),
                      icon: const Icon(Icons.smart_display_outlined, size: 18),
                    ),
                  ],
                  selected: {_type},
                  onSelectionChanged: enabled
                      ? (selection) => setState(() => _type = selection.first)
                      : null,
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              if (_type == MediaTypes.photo && _isNew) ...[
                _FilePicker(
                  picked: _picked,
                  enabled: enabled,
                  onChoose: _choose,
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_type == MediaTypes.photo && !_isNew) ...[
                _StoredFileSummary(item: widget.item!),
                const SizedBox(height: AppSpacing.md),
              ],

              if (_type == MediaTypes.video) ...[
                _field(
                  'external_url',
                  l10n.fieldVideoUrl,
                  enabled,
                  keyboardType: TextInputType.url,
                  validator: (v) =>
                      Validators.notEmpty(v)?.localizedMessage(l10n),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Text(
                    l10n.videoUrlHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
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
                'caption_hi',
                '${l10n.fieldCaptionHindi} · ${l10n.fieldOptional}',
                enabled,
                lines: 3,
              ),
              _field(
                'caption_en',
                '${l10n.fieldCaptionEnglish} · ${l10n.fieldOptional}',
                enabled,
                lines: 3,
              ),

              DropdownButtonFormField<int?>(
                key: const Key('media-album'),
                initialValue: albums.any((a) => a.id == _albumId)
                    ? _albumId
                    : null,
                decoration: InputDecoration(labelText: l10n.fieldAlbum),
                items: [
                  DropdownMenuItem(
                    key: const Key('media-album-none'),
                    value: null,
                    child: Text(l10n.albumNone),
                  ),
                  for (final album in albums)
                    DropdownMenuItem(
                      key: Key('media-album-${album.id}'),
                      value: album.id,
                      child: Text(album.titleHi),
                    ),
                ],
                onChanged: enabled
                    ? (value) => setState(() => _albumId = value)
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),

              DropdownButtonFormField<String>(
                key: const Key('media-status'),
                initialValue: _status,
                decoration: InputDecoration(labelText: l10n.fieldStatus),
                items: [
                  for (final status in MediaStatuses.all)
                    DropdownMenuItem(
                      key: Key('media-status-$status'),
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
                        key: const Key('media-save'),
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
                        : () => context.go(RoutePaths.adminMedia),
                    child: Text(l10n.actionCancel),
                  ),
                ],
              ),

              if (canEdit && !_isNew) ...[
                const SizedBox(height: AppSpacing.xl),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const Key('media-delete'),
                    onPressed: _saving ? null : _confirmDelete,
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: theme.colorScheme.error,
                    ),
                    label: Text(
                      l10n.mediaDelete,
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
    TextInputType? keyboardType,
    int lines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        key: Key('media-$name'),
        controller: _fields[name],
        enabled: enabled,
        keyboardType: keyboardType,
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

/// The file chooser row: a button, and what it produced.
class _FilePicker extends StatelessWidget {
  const _FilePicker({
    required this.picked,
    required this.enabled,
    required this.onChoose,
  });

  final PickedFile? picked;
  final bool enabled;
  final VoidCallback onChoose;

  /// Mirrors `config/media.php`'s `max_upload_kb`. Stated to the person
  /// choosing a file so an 11-megapixel photograph is refused by the dialogue
  /// rather than after a slow upload.
  static const int maxUploadMegabytes = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              key: const Key('media-choose-file'),
              onPressed: enabled ? onChoose : null,
              icon: const Icon(Icons.upload_file_outlined, size: 18),
              label: Text(l10n.mediaChooseFile),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                picked == null
                    ? l10n.mediaNoFileChosen
                    : l10n.mediaFileSelected(
                        picked!.name,
                        MediaFormatting.fileSize(picked!.byteSize),
                      ),
                key: const Key('media-chosen-file'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.mediaFileHint(maxUploadMegabytes),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// What is already stored, for an item being edited.
///
/// The file cannot be replaced here — every reference on the site is by URL, so
/// swapping the bytes under one would silently change a page, an event poster
/// and a portrait at once — so this states the facts rather than offering a
/// button that does not exist.
class _StoredFileSummary extends StatelessWidget {
  const _StoredFileSummary({required this.item});

  final AdminMedia item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimensions = MediaFormatting.dimensions(item.width, item.height);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.previewUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: MediaImage(
              url: item.previewUrl!,
              width: 96,
              height: 96,
              cacheWidth: 288,
              error: (_) => const SizedBox(width: 96, height: 96),
            ),
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            [
              ?item.originalName,
              ?item.mimeType,
              MediaFormatting.fileSize(item.byteSize),
              ?dimensions,
            ].join(' · '),
            key: const Key('media-stored-summary'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.noticeKey,
    required this.background,
    required this.foreground,
    required this.child,
  });

  final Key noticeKey;
  final Color background;
  final Color foreground;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    key: noticeKey,
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    child: child,
  );
}
