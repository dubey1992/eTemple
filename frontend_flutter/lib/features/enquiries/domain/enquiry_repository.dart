import '../../../core/api/api_envelope.dart';
import 'enquiry.dart';

/// One page of the inbox.
class EnquiryPage {
  const EnquiryPage({required this.enquiries, this.meta});

  static const EnquiryPage empty = EnquiryPage(enquiries: []);

  final List<Enquiry> enquiries;
  final PageMeta? meta;

  bool get hasMore => meta?.hasMore ?? false;
  int get total => meta?.total ?? enquiries.length;
  int get currentPage => meta?.currentPage ?? 1;
}

/// What the inbox is being asked for.
class EnquiryQuery {
  const EnquiryQuery({
    this.status,
    this.category,
    this.assignedTo,
    this.search,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? category;

  /// A user id as a string, or the literal `unassigned`.
  final String? assignedTo;

  /// Matches the reference, the name, either contact channel, or the message.
  final String? search;

  final int page;
  final int perPage;

  EnquiryQuery atPage(int page) => EnquiryQuery(
    status: status,
    category: category,
    assignedTo: assignedTo,
    search: search,
    page: page,
    perPage: perPage,
  );

  Map<String, Object?> toQueryParameters() => {
    'status': ?status,
    'category': ?category,
    'assigned_to': ?assignedTo,
    'search': ?search,
    'page': page,
    'per_page': perPage,
  };

  // Value equality because this is a provider family key: without it every
  // rebuild would ask for a new provider and refetch the same page.
  @override
  bool operator ==(Object other) =>
      other is EnquiryQuery &&
      other.status == status &&
      other.category == category &&
      other.assignedTo == assignedTo &&
      other.search == search &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode =>
      Object.hash(status, category, assignedTo, search, page, perPage);
}

/// Contract for the contact form and the committee's inbox.
///
/// There is deliberately **no read of one enquiry by a visitor** and **no
/// delete**: an enquiry reaches no public endpoint at any status, and `spam` is
/// the only way a row leaves the inbox (PHASE_7_PLAN assumptions N1 and N8).
/// Their absence here is the client half of both rules.
abstract interface class EnquiryRepository {
  /// Fetches the ticket the contact form must be submitted with — and, once
  /// this address has sent enough messages, the question it must answer.
  Future<EnquiryForm> form();

  /// Sends a message. Returns the reference the visitor is told, which is null
  /// when the submission was dropped as spam.
  Future<EnquiryReceipt> submit(EnquiryDraft draft);

  /// One page of the inbox. Requires `enquiries.manage`.
  Future<EnquiryPage> enquiries(EnquiryQuery query);

  /// How many are waiting, by status, over the whole filter.
  Future<EnquirySummary> summary(EnquiryQuery query);

  /// One enquiry, with who it is assigned to and who closed it.
  Future<Enquiry> enquiry(int id);

  /// Moves an enquiry along.
  Future<Enquiry> updateStatus(int id, String status);

  /// Hands an enquiry to a committee member, or takes it back off them.
  ///
  /// Separate from [updateStatus] rather than one call with two optional
  /// arguments, because `null` there would be ambiguous: unassigning and
  /// leaving the assignee alone would look identical.
  Future<Enquiry> assign(int id, int? userId);
}
