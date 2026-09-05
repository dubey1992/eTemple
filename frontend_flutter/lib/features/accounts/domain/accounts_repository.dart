import 'dart:typed_data';

import 'account.dart';

/// What the ledger is being asked for.
class TransactionQuery {
  const TransactionQuery({
    this.status,
    this.type,
    this.categoryId,
    this.mode,
    this.from,
    this.to,
    this.search,
    this.page = 1,
    this.perPage = 25,
  });

  final String? status;
  final String? type;
  final int? categoryId;
  final String? mode;

  /// `YYYY-MM-DD`, inclusive at both ends.
  final String? from;
  final String? to;

  /// Matches a payee, a description or a payment reference.
  final String? search;

  final int page;
  final int perPage;

  TransactionQuery atPage(int page) => TransactionQuery(
    status: status,
    type: type,
    categoryId: categoryId,
    mode: mode,
    from: from,
    to: to,
    search: search,
    page: page,
    perPage: perPage,
  );

  Map<String, Object?> toQueryParameters() => {
    'status': ?status,
    'type': ?type,
    'category_id': ?categoryId,
    'mode': ?mode,
    'from': ?from,
    'to': ?to,
    'q': ?search,
    'page': page,
    'per_page': perPage,
  };

  /// The same filter without the status, which is what the summary is asked
  /// for: a total that honoured the status filter would report "spent: 0"
  /// whenever the reader happened to be looking at the pending tab.
  Map<String, Object?> toSummaryParameters() {
    final parameters = toQueryParameters()
      ..remove('status')
      ..remove('page')
      ..remove('per_page');
    return parameters;
  }

  // Value equality because this is a provider family key: without it every
  // rebuild would ask for a new provider and refetch the same page.
  @override
  bool operator ==(Object other) =>
      other is TransactionQuery &&
      other.status == status &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.mode == mode &&
      other.from == from &&
      other.to == to &&
      other.search == search &&
      other.page == page &&
      other.perPage == perPage;

  @override
  int get hashCode => Object.hash(
    status,
    type,
    categoryId,
    mode,
    from,
    to,
    search,
    page,
    perPage,
  );
}

/// A bill being attached to an entry.
///
/// Bytes and a name rather than a file handle, so the same repository works on
/// the web, where there is no path to a file the user picked.
class AttachmentUpload {
  const AttachmentUpload({
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  final Uint8List bytes;
  final String filename;

  /// What the browser claimed. Sent for completeness and **not trusted**: the
  /// server decides the type by reading the bytes.
  final String? contentType;
}

/// Contract for the temple's books.
///
/// Implementations live in `data/` and are the only place that knows about
/// HTTP.
///
/// There is deliberately **no `deleteTransaction`**. Nothing in the ledger is
/// ever deleted; [reverse] — which keeps the row, its bill and a stated reason
/// — is the only undo, and the absence of a delete method here is the client
/// half of that rule. [deleteCategory] exists and is narrow: a heading nothing
/// is filed under is a typo, not history.
abstract interface class AccountsRepository {
  /// What the temple did with the money, for one financial year.
  ///
  /// [year] null asks for the current one. A response with
  /// `isPublished == false` is a value, not a failure.
  Future<Transparency> transparency({required String language, int? year});

  /// One page of the ledger. Requires `accounts.view`.
  Future<TransactionPage> transactions(TransactionQuery query);

  /// The running figures for a filter, computed by the server over the whole
  /// filter rather than over the page in view.
  Future<AccountsSummary> summary(TransactionQuery query);

  /// One entry, with who recorded, approved and reversed it.
  Future<Transaction> transaction(int id);

  /// Records an entry as pending. Requires `accounts.manage`.
  Future<Transaction> record(TransactionDraft draft, {AttachmentUpload? bill});

  /// Corrects an entry. The server refuses everything but the description once
  /// the entry has been approved.
  Future<Transaction> save(
    int id,
    TransactionDraft draft, {
    AttachmentUpload? bill,
  });

  /// Checks an entry and counts it. From here the figure is in the totals the
  /// village reads, and the row is locked.
  Future<Transaction> approve(int id);

  /// The only undo. [reason] is required and is what explains, months later,
  /// why a figure still in the books no longer counts.
  Future<Transaction> reverse(int id, String reason);

  /// The absolute URL of a bill, for opening in a new tab. Behind
  /// `accounts.view`; the browser sends the session cookie.
  String attachmentUrl(int id);

  Future<List<AccountingCategory>> categories({String? type, bool? activeOnly});

  Future<AccountingCategory> createCategory(AccountingCategoryDraft draft);

  Future<AccountingCategory> saveCategory(
    int id,
    AccountingCategoryDraft draft,
  );

  /// Removes a heading nothing is filed under. The server refuses one that is
  /// in use, and says how many entries are in the way.
  Future<void> deleteCategory(int id);

  Future<AccountingSettings> settings();

  Future<AccountingSettings> saveSettings(AccountingSettingsDraft draft);
}
