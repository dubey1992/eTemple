import 'package:rkt_web/core/api/api_envelope.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/accounts/domain/account.dart';
import 'package:rkt_web/features/accounts/domain/accounts_repository.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';

/// Scriptable stand-in for the HTTP accounts repository.
///
/// **The arithmetic is not reimplemented here.** What the totals come to is the
/// server's decision, computed by the database over the whole filter; a fake
/// that added up its own rows would be testing the fake, and would quietly
/// teach the screens that the client may compute a published figure. What this
/// does instead is return whatever the server is being made to say.
class FakeAccountsRepository implements AccountsRepository {
  FakeAccountsRepository({
    Transparency? transparency,
    List<Transaction>? transactions,
    List<AccountingCategory>? categories,
    AccountsSummary? summary,
    AccountingSettings? settings,
    this.lastPage = 1,
    this.transparencyError,
    this.listError,
    this.detailError,
    this.saveError,
    this.categoryError,
  }) : _transparency = transparency ?? testTransparency(),
       list = transactions ?? const [],
       categoryList = categories ?? [testCategory()],
       _summary = summary ?? AccountsSummary.empty,
       _settings = settings ?? testAccountingSettings();

  final Transparency _transparency;
  List<Transaction> list;
  List<AccountingCategory> categoryList;
  final AccountsSummary _summary;
  AccountingSettings _settings;
  int lastPage;

  AppException? transparencyError;
  AppException? listError;
  AppException? detailError;
  AppException? saveError;
  AppException? categoryError;

  int recordCalls = 0;
  int saveCalls = 0;
  final List<int> approved = [];
  final List<int> reversalIds = [];
  final List<String> reversalReasons = [];
  final List<int> deletedCategories = [];
  TransactionDraft? lastDraft;
  AttachmentUpload? lastBill;
  AccountingCategoryDraft? lastCategoryDraft;
  AccountingSettingsDraft? lastSettingsDraft;
  TransactionQuery? lastQuery;
  String? lastLanguage;
  int? lastYear;

  @override
  Future<Transparency> transparency({
    required String language,
    int? year,
  }) async {
    lastLanguage = language;
    lastYear = year;
    if (transparencyError != null) throw transparencyError!;
    return _transparency;
  }

  @override
  Future<TransactionPage> transactions(TransactionQuery query) async {
    lastQuery = query;
    if (listError != null) throw listError!;

    return TransactionPage(
      transactions: list,
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
  Future<AccountsSummary> summary(TransactionQuery query) async {
    if (listError != null) throw listError!;
    return _summary;
  }

  @override
  Future<Transaction> transaction(int id) async {
    if (detailError != null) throw detailError!;
    return list.firstWhere((item) => item.id == id);
  }

  @override
  Future<Transaction> record(
    TransactionDraft draft, {
    AttachmentUpload? bill,
  }) async {
    recordCalls++;
    lastDraft = draft;
    lastBill = bill;
    if (saveError != null) throw saveError!;

    final created = testTransaction(
      id: list.length + 1,
      hasAttachment: bill != null,
    );
    list = [...list, created];
    return created;
  }

  @override
  Future<Transaction> save(
    int id,
    TransactionDraft draft, {
    AttachmentUpload? bill,
  }) async {
    saveCalls++;
    lastDraft = draft;
    lastBill = bill;
    if (saveError != null) throw saveError!;
    return _replace(id);
  }

  @override
  Future<Transaction> approve(int id) async {
    approved.add(id);
    if (saveError != null) throw saveError!;
    return _replace(id, status: TransactionStatuses.approved, locked: true);
  }

  @override
  Future<Transaction> reverse(int id, String reason) async {
    reversalIds.add(id);
    reversalReasons.add(reason);
    if (saveError != null) throw saveError!;
    return _replace(id, status: TransactionStatuses.reversed);
  }

  @override
  String attachmentUrl(int id) =>
      'http://localhost/api/admin/transactions/'
      '$id/attachment';

  @override
  Future<List<AccountingCategory>> categories({
    String? type,
    bool? activeOnly,
  }) async {
    if (categoryError != null) throw categoryError!;

    return categoryList
        .where((c) => type == null || c.type == type)
        .where((c) => activeOnly != true || c.isActive)
        .toList(growable: false);
  }

  @override
  Future<AccountingCategory> createCategory(
    AccountingCategoryDraft draft,
  ) async {
    lastCategoryDraft = draft;
    if (categoryError != null) throw categoryError!;

    final created = testCategory(
      id: categoryList.length + 1,
      nameHi: draft.nameHi,
      type: draft.type,
    );
    categoryList = [...categoryList, created];
    return created;
  }

  @override
  Future<AccountingCategory> saveCategory(
    int id,
    AccountingCategoryDraft draft,
  ) async {
    lastCategoryDraft = draft;
    if (categoryError != null) throw categoryError!;

    final existing = categoryList.firstWhere((c) => c.id == id);
    final updated = testCategory(
      id: existing.id,
      nameHi: draft.nameHi,
      type: draft.type,
      isActive: draft.isActive,
      transactionCount: existing.transactionCount,
    );
    categoryList = [for (final c in categoryList) c.id == id ? updated : c];
    return updated;
  }

  @override
  Future<void> deleteCategory(int id) async {
    deletedCategories.add(id);
    if (categoryError != null) throw categoryError!;
    categoryList = categoryList.where((c) => c.id != id).toList();
  }

  @override
  Future<AccountingSettings> settings() async {
    if (detailError != null) throw detailError!;
    return _settings;
  }

  @override
  Future<AccountingSettings> saveSettings(AccountingSettingsDraft draft) async {
    lastSettingsDraft = draft;
    if (saveError != null) throw saveError!;

    _settings = testAccountingSettings(isPublished: draft.isPublished);
    return _settings;
  }

  Transaction _replace(int id, {String? status, bool? locked}) {
    final existing = list.firstWhere((item) => item.id == id);
    final updated = testTransaction(
      id: existing.id,
      type: existing.type,
      categoryId: existing.categoryId,
      amountPaise: existing.amountPaise,
      status: status ?? existing.status,
      isLocked: locked ?? existing.isLocked,
      hasAttachment: existing.hasAttachment,
    );

    list = [for (final item in list) item.id == id ? updated : item];

    return updated;
  }
}

AccountingCategory testCategory({
  int id = 1,
  String code = 'utilities',
  String type = TransactionTypes.expense,
  String nameHi = 'बिजली एवं पानी',
  String? nameEn = 'Electricity and water',
  bool isActive = true,
  int? transactionCount = 0,
}) => AccountingCategory(
  id: id,
  code: code,
  type: type,
  nameHi: nameHi,
  nameEn: nameEn,
  isActive: isActive,
  sortOrder: 0,
  transactionCount: transactionCount,
);

Transaction testTransaction({
  int id = 1,
  String type = TransactionTypes.expense,
  int categoryId = 1,
  int amountPaise = 120000,
  String? amountFormatted,
  String transactionDate = '2026-09-01',
  String status = TransactionStatuses.pending,
  bool isLocked = false,
  bool hasAttachment = false,
  String? payeeName,
  String? reversalReason,
  AccountingCategory? category,
}) => Transaction(
  id: id,
  type: type,
  categoryId: categoryId,
  category: category ?? testCategory(id: categoryId, type: type),
  amountPaise: amountPaise,
  amountFormatted: amountFormatted ?? '₹1,200.00',
  transactionDate: transactionDate,
  paymentMode: 'cash',
  paymentModeLabel: 'नकद / Cash',
  requiresReference: false,
  status: status,
  isLocked: isLocked,
  hasAttachment: hasAttachment,
  attachmentName: hasAttachment ? 'bill.jpg' : null,
  payeeName: payeeName,
  reversalReason: reversalReason,
);

AccountingSettings testAccountingSettings({
  bool isPublished = false,
  int openingBalancePaise = 0,
}) => AccountingSettings(
  isPublished: isPublished,
  openingBalancePaise: openingBalancePaise,
  openingBalanceFormatted: '₹0.00',
);

CategoryTotal testCategoryTotal({
  String code = 'construction',
  String name = 'निर्माण कार्य',
  bool fallbackUsed = false,
  int totalPaise = 900000,
}) => CategoryTotal(
  code: code,
  name: LocalizedValue(
    value: name,
    language: fallbackUsed ? 'hi' : 'en',
    fallbackUsed: fallbackUsed,
  ),
  totalPaise: totalPaise,
);

/// The published figures, in whatever shape the server is being made to send.
Transparency testTransparency({
  bool isPublished = true,
  String? intro,
  TransparencyYear? summary,
  List<TransparencyYearOption>? years,
}) => Transparency(
  isPublished: isPublished,
  intro: intro == null
      ? LocalizedValue.empty
      : LocalizedValue(value: intro, language: 'hi', fallbackUsed: false),
  note: LocalizedValue.empty,
  availableYears:
      years ?? const [TransparencyYearOption(year: 2026, label: '2026–27')],
  summary: isPublished ? (summary ?? testTransparencyYear()) : null,
);

TransparencyYear testTransparencyYear({
  int year = 2026,
  String yearLabel = '2026–27',
  int openingBalancePaise = 4000000,
  int donationsPaise = 750000,
  int otherIncomePaise = 120000,
  int totalExpensePaise = 300000,
  int donationCount = 2,
  List<CategoryTotal>? incomeByCategory,
  List<CategoryTotal>? expenseByCategory,
}) {
  final income = donationsPaise + otherIncomePaise;

  return TransparencyYear(
    year: year,
    yearLabel: yearLabel,
    startsOn: '$year-04-01',
    endsOn: '${year + 1}-03-31',
    openingBalancePaise: openingBalancePaise,
    donationsPaise: donationsPaise,
    otherIncomePaise: otherIncomePaise,
    totalIncomePaise: income,
    totalExpensePaise: totalExpensePaise,
    closingBalancePaise: openingBalancePaise + income - totalExpensePaise,
    donationCount: donationCount,
    incomeByCategory: incomeByCategory ?? const [],
    expenseByCategory: expenseByCategory ?? [testCategoryTotal()],
  );
}
