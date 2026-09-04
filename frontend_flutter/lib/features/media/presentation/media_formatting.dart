import '../../../l10n/app_localizations.dart';
import '../domain/media_item.dart';

/// Turns the media API's codes and numbers into text a committee member can
/// read.
///
/// Kept out of the widgets so the wording is decided once and can be unit
/// tested without pumping a screen.
class MediaFormatting {
  const MediaFormatting._();

  static String typeLabel(String type, AppLocalizations l10n) =>
      type == MediaTypes.video ? l10n.mediaTypeVideo : l10n.mediaTypePhoto;

  static String statusLabel(String status, AppLocalizations l10n) =>
      status == MediaStatuses.published
      ? l10n.statusPublished
      : l10n.statusDraft;

  /// What a reference is, in words.
  ///
  /// An unknown type falls back to the raw code rather than to an empty string:
  /// a blocked deletion has to say *something* about what is blocking it, and a
  /// code the reader can quote to us beats a blank line.
  static String referenceLabel(String type, AppLocalizations l10n) =>
      switch (type) {
        'event_poster' => l10n.mediaReferenceEventPoster,
        'committee_member' => l10n.mediaReferenceCommitteeMember,
        'temple_logo' => l10n.mediaReferenceTempleLogo,
        'album_cover' => l10n.mediaReferenceAlbumCover,
        'page' => l10n.mediaReferencePage,
        _ => type,
      };

  /// A file size a person can judge — "1.4 MB", not "1468006".
  ///
  /// Binary units, because that is what an operating system reports for the
  /// same file, and a number that disagrees with the one on their desktop
  /// invites a support question.
  static String fileSize(int? bytes) {
    if (bytes == null || bytes <= 0) return '—';
    if (bytes < 1024) return '$bytes B';

    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(0)} KB';

    return '${(kb / 1024).toStringAsFixed(1)} MB';
  }

  /// "1920 × 1280", or nothing at all for a video, which has no dimensions.
  static String? dimensions(int? width, int? height) {
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    return '$width × $height';
  }
}
