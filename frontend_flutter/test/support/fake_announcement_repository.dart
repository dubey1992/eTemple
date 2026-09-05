import 'package:rkt_web/core/api/api_envelope.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/announcements/domain/announcement.dart';
import 'package:rkt_web/features/announcements/domain/announcement_repository.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';

/// Scriptable stand-in for the HTTP announcement repository.
///
/// **The schedule is not reimplemented here.** Which notices are currently
/// showing is the server's decision, taken from its own clock; a fake that
/// filtered by date would be testing the fake, and would quietly teach the
/// screens that the client is allowed to decide. What this does instead is
/// return whatever the server is being made to say.
class FakeAnnouncementRepository implements AnnouncementRepository {
  FakeAnnouncementRepository({
    List<PublicAnnouncement>? current,
    List<Announcement>? announcements,
    this.lastPage = 1,
    this.currentError,
    this.listError,
    this.detailError,
    this.saveError,
  }) : _current = current ?? const [],
       list = announcements ?? const [];

  final List<PublicAnnouncement> _current;
  List<Announcement> list;
  int lastPage;

  AppException? currentError;
  AppException? listError;
  AppException? detailError;
  AppException? saveError;

  int createCalls = 0;
  int saveCalls = 0;
  final List<int> published = [];
  final List<int> archived = [];
  final List<(int, List<String>)> sends = [];
  AnnouncementDraft? lastDraft;
  AnnouncementQuery? lastQuery;
  String? lastLanguage;

  @override
  Future<List<PublicAnnouncement>> current({required String language}) async {
    lastLanguage = language;
    if (currentError != null) throw currentError!;
    return _current;
  }

  @override
  Future<AnnouncementPage> announcements(AnnouncementQuery query) async {
    lastQuery = query;
    if (listError != null) throw listError!;

    return AnnouncementPage(
      announcements: list,
      meta: PageMeta(
        currentPage: query.page,
        lastPage: lastPage,
        perPage: query.perPage,
        total: list.length,
        hasMore: query.page < lastPage,
      ),
    );
  }

  @override
  Future<Announcement> announcement(int id) async {
    if (detailError != null) throw detailError!;
    return list.firstWhere((item) => item.id == id);
  }

  @override
  Future<Announcement> create(AnnouncementDraft draft) async {
    createCalls++;
    lastDraft = draft;
    if (saveError != null) throw saveError!;

    final created = testAnnouncement(
      id: list.length + 1,
      titleHi: draft.titleHi,
    );
    list = [...list, created];
    return created;
  }

  @override
  Future<Announcement> save(int id, AnnouncementDraft draft) async {
    saveCalls++;
    lastDraft = draft;
    if (saveError != null) throw saveError!;
    return _replace(id, titleHi: draft.titleHi);
  }

  @override
  Future<Announcement> publish(int id) async {
    published.add(id);
    if (saveError != null) throw saveError!;
    return _replace(id, status: AnnouncementStatuses.published);
  }

  @override
  Future<Announcement> archive(int id) async {
    archived.add(id);
    if (saveError != null) throw saveError!;
    return _replace(id, status: AnnouncementStatuses.archived);
  }

  @override
  Future<Announcement> send(int id, List<String> channels) async {
    sends.add((id, channels));
    if (saveError != null) throw saveError!;
    return _replace(id, wasSent: true);
  }

  Announcement _replace(
    int id, {
    String? titleHi,
    String? status,
    bool? wasSent,
  }) {
    final existing = list.firstWhere((item) => item.id == id);
    final updated = testAnnouncement(
      id: existing.id,
      titleHi: titleHi ?? existing.titleHi,
      messageHi: existing.messageHi,
      status: status ?? existing.status,
      priority: existing.priority,
      wasSent: wasSent ?? existing.wasSent,
      isShowing: existing.isShowing,
    );

    list = [for (final item in list) item.id == id ? updated : item];

    return updated;
  }
}

PublicAnnouncement testPublicAnnouncement({
  int id = 1,
  String title = 'जन्माष्टमी महोत्सव',
  String message = 'सभी ग्रामवासी आमंत्रित हैं।',
  String priority = AnnouncementPriorities.normal,
  String? linkUrl,
  DateTime? endsAt,
}) => PublicAnnouncement(
  id: id,
  title: LocalizedValue(value: title, language: 'hi', fallbackUsed: false),
  message: LocalizedValue(value: message, language: 'hi', fallbackUsed: false),
  priority: priority,
  linkUrl: linkUrl,
  endsAt: endsAt,
);

Announcement testAnnouncement({
  int id = 1,
  String titleHi = 'जन्माष्टमी महोत्सव',
  String messageHi = 'सभी ग्रामवासी आमंत्रित हैं।',
  String priority = AnnouncementPriorities.normal,
  String status = AnnouncementStatuses.draft,
  bool isShowing = false,
  bool isScheduled = false,
  bool hasExpired = false,
  bool wasSent = false,
  DateTime? startAt,
  DateTime? endAt,
  DateTime? sentAt,
  int? recipientCount,
  List<String> channels = const [],
}) => Announcement(
  id: id,
  titleHi: titleHi,
  messageHi: messageHi,
  priority: priority,
  priorityLabel: priority,
  startAt: startAt ?? DateTime(2026, 9, 12),
  endAt: endAt,
  status: status,
  isShowing: isShowing,
  isScheduled: isScheduled,
  hasExpired: hasExpired,
  wasSent: wasSent,
  sentAt: sentAt,
  recipientCount: recipientCount,
  channels: channels,
  channelLabels: channels,
);
