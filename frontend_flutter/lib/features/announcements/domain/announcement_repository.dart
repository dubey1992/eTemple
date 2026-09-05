import '../../../core/api/api_envelope.dart';
import 'announcement.dart';

/// One page of the admin list.
class AnnouncementPage {
  const AnnouncementPage({required this.announcements, this.meta});

  static const AnnouncementPage empty = AnnouncementPage(announcements: []);

  final List<Announcement> announcements;
  final PageMeta? meta;

  bool get hasMore => meta?.hasMore ?? false;
  int get currentPage => meta?.currentPage ?? 1;
}

/// What the admin list is being asked for.
class AnnouncementQuery {
  const AnnouncementQuery({
    this.status,
    this.priority,
    this.search,
    this.includeArchived = false,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? priority;
  final String? search;

  /// Archived notices are kept but not shown by default — the same treatment
  /// spam gets in the enquiry inbox.
  final bool includeArchived;

  final int page;
  final int perPage;

  AnnouncementQuery atPage(int page) => AnnouncementQuery(
    status: status,
    priority: priority,
    search: search,
    includeArchived: includeArchived,
    page: page,
    perPage: perPage,
  );

  Map<String, Object?> toQueryParameters() => {
    'status': ?status,
    'priority': ?priority,
    'search': ?search,
    if (includeArchived) 'include_archived': true,
    'page': page,
    'per_page': perPage,
  };

  @override
  bool operator ==(Object other) =>
      other is AnnouncementQuery &&
      other.status == status &&
      other.priority == priority &&
      other.search == search &&
      other.includeArchived == includeArchived &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode =>
      Object.hash(status, priority, search, includeArchived, page, perPage);
}

/// Contract for the temple's notices.
///
/// [save] and [publish] and [send] are three methods rather than one `save`
/// with a status argument, because they are three decisions with different
/// consequences — and one of them cannot be undone. A client that could send by
/// setting a field would make "no sends without explicit admin action" a
/// property of a screen rather than of the system.
///
/// There is no `delete`: [archive] takes a notice off the website and keeps the
/// row, including its record of what was sent.
abstract interface class AnnouncementRepository {
  /// The temple's current notices, in the visitor's language. Published and
  /// inside their window — the server decides which, from its own clock.
  Future<List<PublicAnnouncement>> current({required String language});

  /// One page of the admin list. Requires `content.view`.
  Future<AnnouncementPage> announcements(AnnouncementQuery query);

  Future<Announcement> announcement(int id);

  /// Writes a new notice. It is a draft: this sends nothing and shows nothing.
  Future<Announcement> create(AnnouncementDraft draft);

  Future<Announcement> save(int id, AnnouncementDraft draft);

  /// Puts it on the website for its window. Still sends nothing.
  Future<Announcement> publish(int id);

  /// Takes it off the website, keeping the row.
  Future<Announcement> archive(int id);

  /// The irreversible one. [channels] is required and must not be empty: there
  /// is no default, because a default would mean this could happen without
  /// anybody choosing it.
  Future<Announcement> send(int id, List<String> channels);
}
