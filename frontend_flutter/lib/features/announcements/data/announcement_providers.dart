import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/announcement.dart';
import '../domain/announcement_repository.dart';
import 'announcement_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final announcementRepositoryProvider = Provider<AnnouncementRepository>(
  (ref) => AnnouncementRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The temple's current notices, in the visitor's language.
///
/// Which notices those are is entirely the server's decision, taken from its
/// own clock. The client never filters by date: a banner hidden by the browser
/// while the API still serves it would be a schedule that is only true on
/// screen (PHASE_8_PLAN assumption N2).
final currentAnnouncementsProvider = FutureProvider<List<PublicAnnouncement>>((
  ref,
) {
  final language = ref.watch(contentLanguageProvider);
  return ref.watch(announcementRepositoryProvider).current(language: language);
});

/// One page of the admin list.
final announcementsProvider =
    FutureProvider.family<AnnouncementPage, AnnouncementQuery>(
      (ref, query) =>
          ref.watch(announcementRepositoryProvider).announcements(query),
    );

/// One announcement, as the editor loads it.
final announcementProvider = FutureProvider.family<Announcement, int>(
  (ref, id) => ref.watch(announcementRepositoryProvider).announcement(id),
);

/// Which banners this visitor has closed.
///
/// Held in memory for the session only. Persisting a dismissal would need
/// per-visitor storage, and one that outlived the notice would be worse than
/// none: a villager who closed last month's banner would never see this
/// month's (PHASE_8_PLAN assumption N9).
class DismissedAnnouncements extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void dismiss(int id) => state = {...state, id};
}

final dismissedAnnouncementsProvider =
    NotifierProvider<DismissedAnnouncements, Set<int>>(
      DismissedAnnouncements.new,
    );

/// The one notice the home page banner shows.
///
/// The loudest currently showing, minus anything this visitor has closed. One,
/// not a stack: a page whose top third is a pile of notices is a page nobody
/// reads.
final bannerAnnouncementProvider = Provider<PublicAnnouncement?>((ref) {
  final announcements = ref.watch(currentAnnouncementsProvider).value;
  if (announcements == null || announcements.isEmpty) return null;

  final dismissed = ref.watch(dismissedAnnouncementsProvider);
  final now = DateTime.now();

  for (final announcement in announcements) {
    // The server already excluded expired notices; this catches one that ran
    // out while the page sat open.
    if (dismissed.contains(announcement.id)) continue;
    if (announcement.hasExpired(now)) continue;

    return announcement;
  }

  return null;
});

/// The admin list's filters, held in a provider so a rebuild — or a language
/// switch — does not throw the editor back to page one of everything.
class AnnouncementListView {
  const AnnouncementListView({
    this.status,
    this.priority,
    this.search,
    this.includeArchived = false,
    this.page = 1,
  });

  final String? status;
  final String? priority;
  final String? search;
  final bool includeArchived;
  final int page;

  /// Every filter change resets to the first page: page four of a filter that
  /// now matches two rows is an empty screen with no explanation.
  AnnouncementListView withStatus(String? status) => AnnouncementListView(
    status: status,
    priority: priority,
    search: search,
    includeArchived: includeArchived,
  );

  AnnouncementListView withPriority(String? priority) => AnnouncementListView(
    status: status,
    priority: priority,
    search: search,
    includeArchived: includeArchived,
  );

  AnnouncementListView withSearch(String? search) => AnnouncementListView(
    status: status,
    priority: priority,
    search: (search == null || search.trim().isEmpty) ? null : search.trim(),
    includeArchived: includeArchived,
  );

  AnnouncementListView withArchived(bool includeArchived) =>
      AnnouncementListView(
        status: status,
        priority: priority,
        search: search,
        includeArchived: includeArchived,
      );

  AnnouncementListView atPage(int page) => AnnouncementListView(
    status: status,
    priority: priority,
    search: search,
    includeArchived: includeArchived,
    page: page,
  );

  AnnouncementQuery get query => AnnouncementQuery(
    status: status,
    priority: priority,
    search: search,
    includeArchived: includeArchived,
    page: page,
  );

  @override
  bool operator ==(Object other) =>
      other is AnnouncementListView &&
      other.status == status &&
      other.priority == priority &&
      other.search == search &&
      other.includeArchived == includeArchived &&
      other.page == page;

  @override
  int get hashCode =>
      Object.hash(status, priority, search, includeArchived, page);
}

class AnnouncementListController extends Notifier<AnnouncementListView> {
  @override
  AnnouncementListView build() => const AnnouncementListView();

  void selectStatus(String? status) => state = state.withStatus(status);

  void selectPriority(String? priority) => state = state.withPriority(priority);

  void search(String? term) => state = state.withSearch(term);

  void showArchived(bool include) => state = state.withArchived(include);

  void goToPage(int page) => state = state.atPage(page);
}

final announcementListProvider =
    NotifierProvider<AnnouncementListController, AnnouncementListView>(
      AnnouncementListController.new,
    );
