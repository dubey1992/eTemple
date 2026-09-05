import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../domain/enquiry.dart';
import '../domain/enquiry_repository.dart';
import 'enquiry_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final enquiryRepositoryProvider = Provider<EnquiryRepository>(
  (ref) => EnquiryRepositoryImpl(ref.watch(apiClientProvider)),
);

/// The ticket the contact form is submitted with.
///
/// Fetched when the page opens rather than when the visitor presses send, for
/// two reasons: the server measures how long the form was open, and the
/// question — when there is one — has to be on screen while they type.
///
/// Invalidated after every successful submission, because a ticket is spent
/// once (PHASE_7_PLAN assumption N2).
final enquiryFormProvider = FutureProvider.autoDispose<EnquiryForm>(
  (ref) => ref.watch(enquiryRepositoryProvider).form(),
);

/// One page of the inbox. Requires `enquiries.manage`.
final enquiriesProvider = FutureProvider.family<EnquiryPage, EnquiryQuery>(
  (ref, query) => ref.watch(enquiryRepositoryProvider).enquiries(query),
);

/// How many are waiting, by status, over the whole inbox.
final enquirySummaryProvider =
    FutureProvider.family<EnquirySummary, EnquiryQuery>(
      (ref, query) => ref.watch(enquiryRepositoryProvider).summary(query),
    );

/// One enquiry, with its assignee and whoever closed it.
final enquiryProvider = FutureProvider.family<Enquiry, int>(
  (ref, id) => ref.watch(enquiryRepositoryProvider).enquiry(id),
);

/// The inbox's filters, held in a provider rather than in the screen so the
/// committee member's choice survives a rebuild — switching language must not
/// throw them back to page one of everything.
class EnquiryInboxView {
  const EnquiryInboxView({
    this.status,
    this.category,
    this.assignedTo,
    this.search,
    this.page = 1,
  });

  final String? status;
  final String? category;
  final String? assignedTo;
  final String? search;
  final int page;

  /// Every filter change resets to the first page: page four of a filter that
  /// now matches two rows is an empty screen with no explanation.
  EnquiryInboxView withStatus(String? status) => EnquiryInboxView(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: search,
  );

  EnquiryInboxView withCategory(String? category) => EnquiryInboxView(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: search,
  );

  EnquiryInboxView withAssignedTo(String? assignedTo) => EnquiryInboxView(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: search,
  );

  EnquiryInboxView withSearch(String? search) => EnquiryInboxView(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: (search == null || search.trim().isEmpty) ? null : search.trim(),
  );

  EnquiryInboxView atPage(int page) => EnquiryInboxView(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: search,
    page: page,
  );

  EnquiryQuery get query => EnquiryQuery(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: search,
    page: page,
  );

  @override
  bool operator ==(Object other) =>
      other is EnquiryInboxView &&
      other.status == status &&
      other.category == category &&
      other.assignedTo == assignedTo &&
      other.search == search &&
      other.page == page;

  @override
  int get hashCode => Object.hash(status, category, assignedTo, search, page);
}

class EnquiryInboxController extends Notifier<EnquiryInboxView> {
  @override
  EnquiryInboxView build() => const EnquiryInboxView();

  void selectStatus(String? status) => state = state.withStatus(status);

  void selectCategory(String? category) => state = state.withCategory(category);

  void selectAssignee(String? assignedTo) =>
      state = state.withAssignedTo(assignedTo);

  void search(String? term) => state = state.withSearch(term);

  void goToPage(int page) => state = state.atPage(page);
}

final enquiryInboxProvider =
    NotifierProvider<EnquiryInboxController, EnquiryInboxView>(
      EnquiryInboxController.new,
    );
