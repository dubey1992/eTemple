import '../../../l10n/app_localizations.dart';
import '../domain/announcement.dart';

/// The words for the codes the API sends.
class AnnouncementLabels {
  const AnnouncementLabels._();

  static String priority(AppLocalizations l10n, String code) => switch (code) {
    AnnouncementPriorities.important => l10n.announcementPriorityImportant,
    AnnouncementPriorities.urgent => l10n.announcementPriorityUrgent,
    _ => l10n.announcementPriorityNormal,
  };

  static String status(AppLocalizations l10n, String code) => switch (code) {
    AnnouncementStatuses.published => l10n.announcementStatusPublished,
    AnnouncementStatuses.archived => l10n.announcementStatusArchived,
    _ => l10n.announcementStatusDraft,
  };

  static String channel(AppLocalizations l10n, String code) => switch (code) {
    AnnouncementChannels.site => l10n.announcementChannelSite,
    AnnouncementChannels.email => l10n.announcementChannelEmail,
    AnnouncementChannels.sms => l10n.announcementChannelSms,
    AnnouncementChannels.whatsapp => l10n.announcementChannelWhatsapp,
    _ => code,
  };

  /// What the list shows beside a notice: where it stands *right now*, which is
  /// not the same as its status.
  ///
  /// A published announcement can be showing, waiting for its start date, or
  /// finished — three different things a committee member needs to tell apart
  /// at a glance, and none of them is a column.
  static String state(
    AppLocalizations l10n,
    Announcement announcement,
    String Function(DateTime) formatDate,
  ) {
    if (announcement.isShowing) return l10n.announcementShowingNow;

    if (announcement.isScheduled) {
      return l10n.announcementScheduledFor(formatDate(announcement.startAt));
    }

    if (announcement.hasExpired && announcement.endAt != null) {
      return l10n.announcementExpiredOn(formatDate(announcement.endAt!));
    }

    return status(l10n, announcement.status);
  }
}
