import 'package:flutter/material.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../domain/announcement.dart';
import '../announcement_labels.dart';

/// Asks which channels to send on, and makes the consequence plain first.
///
/// Returns the chosen channels, or null if the committee member backed out.
///
/// Three things are deliberate here:
///
///  * **Nothing is ticked by default.** The specification's rule is "no sends
///    without explicit admin action", and a pre-ticked box would mean the most
///    consequential action in this phase could happen without anybody choosing
///    it (PHASE_8_PLAN assumption N5).
///  * **The words say it cannot be undone**, before the button rather than
///    after it.
///  * **Unavailable channels are shown, disabled, with the reason.** Hiding
///    them would leave a committee wondering whether the temple can send an
///    SMS; showing them enabled would let them believe it just did.
Future<List<String>?> showSendAnnouncementDialog(BuildContext context) {
  return showDialog<List<String>>(
    context: context,
    builder: (context) => const _SendAnnouncementDialog(),
  );
}

class _SendAnnouncementDialog extends StatefulWidget {
  const _SendAnnouncementDialog();

  @override
  State<_SendAnnouncementDialog> createState() =>
      _SendAnnouncementDialogState();
}

class _SendAnnouncementDialogState extends State<_SendAnnouncementDialog> {
  /// Empty on purpose. The send button stays disabled until something is
  /// chosen.
  final Set<String> _chosen = {};

  /// Which channels this build knows are connected.
  ///
  /// SMS and WhatsApp need a provider that has been chosen, approved and
  /// configured, and none has been. The server refuses them too — this only
  /// stops the console offering a button that would fail.
  static const Set<String> _available = {
    AnnouncementChannels.site,
    AnnouncementChannels.email,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AlertDialog(
      key: const Key('announcement-send-dialog'),
      title: Text(l10n.announcementSendTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.announcementSendBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.announcementChannels,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          for (final channel in AnnouncementChannels.all)
            CheckboxListTile(
              key: Key('announcement-channel-$channel'),
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _chosen.contains(channel),
              enabled: _available.contains(channel),
              title: Text(AnnouncementLabels.channel(l10n, channel)),
              subtitle: _available.contains(channel)
                  ? null
                  : Text(l10n.announcementChannelUnavailable),
              onChanged: _available.contains(channel)
                  ? (value) => setState(() {
                      value ?? false
                          ? _chosen.add(channel)
                          : _chosen.remove(channel);
                    })
                  : null,
            ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.announcementRecipientsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const Key('announcement-send-cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          key: const Key('announcement-send-confirm'),
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.of(context).pop(_chosen.toList()),
          child: Text(l10n.announcementSendConfirm),
        ),
      ],
    );
  }
}
