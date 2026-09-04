import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../data/media_providers.dart';
import '../../domain/media_item.dart';
import 'media_image.dart';

/// A URL field that can be filled from the gallery instead of typed.
///
/// This is the integration Phase 5 exists to make possible. `logo_url`,
/// `photo_url` and `poster_url` have been plain text boxes since Phases 3 and
/// 4 because there was no library to choose from; they still store a URL —
/// which keeps those phases undisturbed and keeps an externally hosted image
/// possible — but a committee member now picks a photograph rather than
/// pasting an address they have to find somewhere else first.
///
/// The text field stays editable on purpose. Removing it would make an
/// external image impossible, and the field is also how an existing value
/// entered before this phase is still visible.
class MediaPickerField extends ConsumerWidget {
  const MediaPickerField({
    super.key,
    required this.controller,
    required this.label,
    required this.fieldKey,
    this.enabled = true,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final Key fieldKey;
  final bool enabled;
  final String? errorText;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final photos = ref.watch(pickerPhotosProvider);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(labelText: label, errorText: errorText),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              OutlinedButton.icon(
                key: Key('$_name-choose'),
                onPressed: enabled
                    ? () => _choose(context, ref, photos.value ?? const [])
                    : null,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: Text(l10n.mediaPickerChoose),
              ),
              if (controller.text.trim().isNotEmpty) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  key: Key('$_name-clear'),
                  onPressed: enabled
                      ? () {
                          controller.clear();
                          onChanged?.call();
                        }
                      : null,
                  child: Text(l10n.mediaPickerClear),
                ),
              ],
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.mediaPickerHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// A stable prefix for the buttons' keys, derived from the field's own key so
  /// two pickers on one screen never collide.
  String get _name {
    final key = fieldKey;
    return key is ValueKey<String> ? key.value : 'media-picker';
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    List<AdminMedia> photos,
  ) async {
    final chosen = await showDialog<AdminMedia>(
      context: context,
      builder: (context) => _MediaPickerDialog(photos: photos),
    );

    if (chosen == null) return;

    // The URL the *server* looks for when it decides whether this file may be
    // deleted, so choosing here and the deletion guard agree by construction.
    controller.text = chosen.referenceUrl ?? '';
    onChanged?.call();
  }
}

class _MediaPickerDialog extends StatelessWidget {
  const _MediaPickerDialog({required this.photos});

  final List<AdminMedia> photos;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('media-picker-dialog'),
      title: Text(l10n.mediaPickerChoose),
      content: SizedBox(
        width: 520,
        height: 420,
        child: photos.isEmpty
            ? Center(
                child: Text(
                  l10n.mediaPickerEmpty,
                  key: const Key('media-picker-empty'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];

                  return InkWell(
                    key: Key('media-picker-option-${photo.id}'),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () => Navigator.of(context).pop(photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: photo.previewUrl == null
                          ? ColoredBox(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: Center(child: Text(photo.titleHi)),
                            )
                          : MediaImage(
                              url: photo.previewUrl!,
                              // Bounded decode, as everywhere else a thumbnail
                              // is shown.
                              cacheWidth: 480,
                              error: (_) => ColoredBox(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
      ],
    );
  }
}
