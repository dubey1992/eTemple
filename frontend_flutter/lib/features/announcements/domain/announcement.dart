/// Notices from the temple (spec Phase 8).
///
/// Two shapes, because two audiences see different things. A visitor gets the
/// notice; the committee also gets who wrote it, when it starts, whether it is
/// showing, and whether it has already been sent — which is the one fact that
/// cannot be changed afterwards.
library;

import '../../content/domain/localized_value.dart';

/// Priority codes, mirroring `App\Support\AnnouncementPriority`.
class AnnouncementPriorities {
  const AnnouncementPriorities._();

  static const String normal = 'normal';
  static const String important = 'important';
  static const String urgent = 'urgent';

  static const List<String> all = [normal, important, urgent];
}

/// Status codes, mirroring `App\Models\Announcement`.
class AnnouncementStatuses {
  const AnnouncementStatuses._();

  static const String draft = 'draft';
  static const String published = 'published';
  static const String archived = 'archived';

  static const List<String> all = [draft, published, archived];
}

/// Channel codes, mirroring `App\Support\AnnouncementChannel`.
class AnnouncementChannels {
  const AnnouncementChannels._();

  static const String site = 'site';
  static const String email = 'email';
  static const String sms = 'sms';
  static const String whatsapp = 'whatsapp';

  static const List<String> all = [site, email, sms, whatsapp];
}

/// A notice as a visitor sees it.
///
/// It carries nothing about how it came to be there — no author, no status, no
/// schedule, no record of what was sent. There is no field to hide, because the
/// public serializer never sends one.
class PublicAnnouncement {
  const PublicAnnouncement({
    required this.id,
    required this.title,
    required this.message,
    required this.priority,
    this.linkUrl,
    this.endsAt,
  });

  factory PublicAnnouncement.fromJson(Map<String, dynamic> json) =>
      PublicAnnouncement(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: LocalizedValue.fromJson(json['title']),
        message: LocalizedValue.fromJson(json['message']),
        priority: json['priority'] as String? ?? AnnouncementPriorities.normal,
        linkUrl: json['link_url'] as String?,
        endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      );

  final int id;
  final LocalizedValue title;
  final LocalizedValue message;
  final String priority;
  final String? linkUrl;

  /// When this notice stops showing. Null means "until it is taken down".
  ///
  /// Sent so a page open for a long time can drop the banner as it expires
  /// without asking the server again.
  final DateTime? endsAt;

  bool get isUrgent => priority == AnnouncementPriorities.urgent;
  bool get isImportant => priority == AnnouncementPriorities.important;

  /// Whether this notice has run out while the page was open.
  bool hasExpired(DateTime now) => endsAt != null && !endsAt!.isAfter(now);
}

/// A notice as the committee sees it.
///
/// Both languages travel raw, because this is what the editor loads: a resolved
/// value with the Hindi fallback applied would make an empty English field look
/// filled in, and the next save would write the Hindi into it.
class Announcement {
  const Announcement({
    required this.id,
    required this.titleHi,
    required this.messageHi,
    required this.priority,
    required this.priorityLabel,
    required this.startAt,
    required this.status,
    required this.isShowing,
    required this.isScheduled,
    required this.hasExpired,
    required this.wasSent,
    this.titleEn,
    this.messageEn,
    this.endAt,
    this.linkUrl,
    this.sentAt,
    this.sentByName,
    this.recipientCount,
    this.channels = const [],
    this.channelLabels = const [],
    this.createdByName,
    this.updatedAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) => Announcement(
    id: (json['id'] as num?)?.toInt() ?? 0,
    titleHi: json['title_hi'] as String? ?? '',
    titleEn: json['title_en'] as String?,
    messageHi: json['message_hi'] as String? ?? '',
    messageEn: json['message_en'] as String?,
    priority: json['priority'] as String? ?? AnnouncementPriorities.normal,
    priorityLabel: json['priority_label'] as String? ?? '',
    startAt:
        DateTime.tryParse(json['start_at'] as String? ?? '') ?? DateTime.now(),
    endAt: DateTime.tryParse(json['end_at'] as String? ?? ''),
    linkUrl: json['link_url'] as String?,
    status: json['status'] as String? ?? AnnouncementStatuses.draft,
    isShowing: json['is_showing'] as bool? ?? false,
    isScheduled: json['is_scheduled'] as bool? ?? false,
    hasExpired: json['has_expired'] as bool? ?? false,
    wasSent: json['was_sent'] as bool? ?? false,
    sentAt: DateTime.tryParse(json['sent_at'] as String? ?? ''),
    sentByName: json['sent_by_name'] as String?,
    recipientCount: (json['recipient_count'] as num?)?.toInt(),
    channels: _strings(json['channels']),
    channelLabels: _strings(json['channel_labels']),
    createdByName: json['created_by_name'] as String?,
    updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
  );

  final int id;
  final String titleHi;
  final String? titleEn;
  final String messageHi;
  final String? messageEn;
  final String priority;
  final String priorityLabel;
  final DateTime startAt;
  final DateTime? endAt;
  final String? linkUrl;
  final String status;

  /// Computed by the server from the clock, never stored: a status flipped by a
  /// scheduler goes live only when the scheduler runs.
  final bool isShowing;
  final bool isScheduled;
  final bool hasExpired;

  /// The one fact that cannot be undone.
  final bool wasSent;
  final DateTime? sentAt;
  final String? sentByName;

  /// How many addresses the queue was handed — not a delivery guarantee.
  final int? recipientCount;

  final List<String> channels;
  final List<String> channelLabels;
  final String? createdByName;
  final DateTime? updatedAt;

  bool get isDraft => status == AnnouncementStatuses.draft;
  bool get isPublished => status == AnnouncementStatuses.published;
  bool get isArchived => status == AnnouncementStatuses.archived;

  /// Whether the send button should be offered at all.
  ///
  /// The server refuses regardless; this only stops the console offering a
  /// button that would fail.
  bool get canBeSent => isPublished && !wasSent;

  static List<String> _strings(Object? value) => value is List
      ? value.whereType<String>().toList(growable: false)
      : const <String>[];
}

/// What an editor typed, on its way to the server.
class AnnouncementDraft {
  const AnnouncementDraft({
    required this.titleHi,
    required this.messageHi,
    required this.priority,
    this.titleEn,
    this.messageEn,
    this.startAt,
    this.endAt,
    this.linkUrl,
  });

  final String titleHi;
  final String? titleEn;
  final String messageHi;
  final String? messageEn;
  final String priority;
  final DateTime? startAt;
  final DateTime? endAt;
  final String? linkUrl;

  Map<String, Object?> toJson() => {
    'title_hi': titleHi,
    'title_en': titleEn,
    'message_hi': messageHi,
    'message_en': messageEn,
    'priority': priority,
    'start_at': startAt?.toUtc().toIso8601String(),
    'end_at': endAt?.toUtc().toIso8601String(),
    'link_url': linkUrl,
    // Deliberately absent: status, channels and everything about sending.
    // Those are decisions with their own endpoints, and a draft that could
    // carry them would make "no sends without explicit admin action" a
    // property of the screen rather than of the API.
  };
}
