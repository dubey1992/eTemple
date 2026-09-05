import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../content/data/content_providers.dart';
import '../domain/account.dart';
import '../domain/accounts_repository.dart';
import 'accounts_repository_impl.dart';

/// Bound to the HTTP implementation here; tests override this with a fake.
final accountsRepositoryProvider = Provider<AccountsRepository>(
  (ref) => AccountsRepositoryImpl(
    ref.watch(apiClientProvider),
    ref.watch(appConfigProvider),
  ),
);

/// Which financial year the public page is showing.
///
/// Null means "whichever the server calls current", which is what a first visit
/// and a shared link without a year both ask for.
final transparencyYearProvider =
    NotifierProvider<TransparencyYearController, int?>(
      TransparencyYearController.new,
    );

class TransparencyYearController extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int? year) => state = year;
}

/// What the temple did with the money, in the visitor's language.
///
/// A response with `isPublished == false` is a value, not a failure: it is what
/// a temple whose committee has not opened its books answers, and the page
/// shows the temple's own words for it.
final transparencyProvider = FutureProvider<Transparency>((ref) {
  final language = ref.watch(contentLanguageProvider);
  final year = ref.watch(transparencyYearProvider);

  return ref
      .watch(accountsRepositoryProvider)
      .transparency(language: language, year: year);
});

/// One page of the ledger.
final transactionsProvider =
    FutureProvider.family<TransactionPage, TransactionQuery>(
      (ref, query) => ref.watch(accountsRepositoryProvider).transactions(query),
    );

/// The running figures for a filter.
///
/// A separate call from the page rather than a block riding in `meta`, because
/// the server computes it over the whole filter and dropping the status — the
/// two questions have different answers and deserve different requests.
final accountsSummaryProvider =
    FutureProvider.family<AccountsSummary, TransactionQuery>(
      (ref, query) => ref.watch(accountsRepositoryProvider).summary(query),
    );

/// One entry, with who recorded, approved and reversed it.
final transactionProvider = FutureProvider.family<Transaction, int>(
  (ref, id) => ref.watch(accountsRepositoryProvider).transaction(id),
);

/// Every heading, including the deactivated ones, with their usage counts.
final accountingCategoriesProvider = FutureProvider<List<AccountingCategory>>(
  (ref) => ref.watch(accountsRepositoryProvider).categories(),
);

/// The headings a new entry may actually be filed under.
final activeCategoriesProvider = FutureProvider<List<AccountingCategory>>(
  (ref) => ref.watch(accountsRepositoryProvider).categories(activeOnly: true),
);

/// Whether the books are public, and where they start.
final accountingSettingsProvider = FutureProvider<AccountingSettings>(
  (ref) => ref.watch(accountsRepositoryProvider).settings(),
);

/// The ledger's filters, held in a provider rather than in the screen so the
/// treasurer's choice survives a rebuild — switching language must not throw
/// them back to page one of everything.
class LedgerView {
  const LedgerView({
    this.status,
    this.type,
    this.categoryId,
    this.search,
    this.page = 1,
  });

  final String? status;
  final String? type;
  final int? categoryId;
  final String? search;
  final int page;

  /// Every filter change resets to the first page: page four of a filter that
  /// now matches two rows is an empty screen with no explanation.
  LedgerView withStatus(String? status) => LedgerView(
    status: status,
    type: type,
    categoryId: categoryId,
    search: search,
  );

  LedgerView withType(String? type) => LedgerView(
    status: status,
    type: type,
    categoryId: categoryId,
    search: search,
  );

  LedgerView withCategory(int? categoryId) => LedgerView(
    status: status,
    type: type,
    categoryId: categoryId,
    search: search,
  );

  LedgerView withSearch(String? search) => LedgerView(
    status: status,
    type: type,
    categoryId: categoryId,
    search: (search == null || search.trim().isEmpty) ? null : search.trim(),
  );

  LedgerView atPage(int page) => LedgerView(
    status: status,
    type: type,
    categoryId: categoryId,
    search: search,
    page: page,
  );

  TransactionQuery get query => TransactionQuery(
    status: status,
    type: type,
    categoryId: categoryId,
    search: search,
    page: page,
  );

  @override
  bool operator ==(Object other) =>
      other is LedgerView &&
      other.status == status &&
      other.type == type &&
      other.categoryId == categoryId &&
      other.search == search &&
      other.page == page;

  @override
  int get hashCode => Object.hash(status, type, categoryId, search, page);
}

class LedgerController extends Notifier<LedgerView> {
  @override
  LedgerView build() => const LedgerView();

  void selectStatus(String? status) => state = state.withStatus(status);

  void selectType(String? type) => state = state.withType(type);

  void selectCategory(int? categoryId) =>
      state = state.withCategory(categoryId);

  void search(String? term) => state = state.withSearch(term);

  void goToPage(int page) => state = state.atPage(page);
}

final ledgerProvider = NotifierProvider<LedgerController, LedgerView>(
  LedgerController.new,
);
