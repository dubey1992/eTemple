import '../../../core/api/api_envelope.dart';
import '../../content/domain/localized_value.dart';

/// Reads a number that may have arrived as an int, a double or a string.
///
/// JSON numbers cross the wire in whichever shape the encoder chose, and a
/// paise figure read as null because it arrived as "1200" would silently become
/// zero in a total.
int? _asInt(Object? value) => switch (value) {
  final int v => v,
  final num v => v.toInt(),
  final String v => int.tryParse(v),
  _ => null,
};

/// Which way the money went, mirroring `App\Support\TransactionType`.
///
/// Two values and no third. A "transfer" is deliberately absent: moving money
/// from the cash box to the bank changes nothing about what the temple received
/// or spent, and recording it as both would inflate both published figures.
class TransactionTypes {
  const TransactionTypes._();

  static const String income = 'income';
  static const String expense = 'expense';

  static const List<String> all = [income, expense];
}

/// Where a ledger entry is in its life, mirroring `App\Models\Transaction`.
class TransactionStatuses {
  const TransactionStatuses._();

  /// Recorded, not yet checked against the bill or the statement. Counts in no
  /// total, and can still be corrected.
  static const String pending = 'pending';

  /// Checked. Counts in every total, including the one the village reads, and
  /// is locked to everything but its description.
  static const String approved = 'approved';

  /// Cancelled. Counts in no total; the row, its bill and its reason stay.
  static const String reversed = 'reversed';

  static const List<String> all = [pending, approved, reversed];
}

/// One heading the temple's books are filed under.
class AccountingCategory {
  const AccountingCategory({
    required this.id,
    required this.code,
    required this.type,
    required this.nameHi,
    required this.isActive,
    required this.sortOrder,
    this.nameEn,
    this.descriptionHi,
    this.descriptionEn,
    this.transactionCount,
  });

  factory AccountingCategory.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return AccountingCategory(
      id: _asInt(json['id']) ?? 0,
      code: read('code') ?? '',
      type: read('type') ?? TransactionTypes.expense,
      nameHi: read('name_hi') ?? '',
      nameEn: read('name_en'),
      descriptionHi: read('description_hi'),
      descriptionEn: read('description_en'),
      sortOrder: _asInt(json['sort_order']) ?? 0,
      isActive: json['is_active'] != false,
      transactionCount: _asInt(json['transaction_count']),
    );
  }

  final int id;
  final String code;
  final String type;
  final String nameHi;
  final String? nameEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final int sortOrder;
  final bool isActive;

  /// How many entries are filed under it, when the server was asked to count.
  /// Null means "not asked", which is not the same as zero.
  final int? transactionCount;

  bool get isIncome => type == TransactionTypes.income;

  /// A used heading cannot be deleted and cannot change side of the books:
  /// either would rewrite the meaning of entries already published.
  bool get isInUse => (transactionCount ?? 0) > 0;

  /// The name in the reader's language, falling back to the Hindi.
  ///
  /// This is the client's own fallback for the *editor*, where both languages
  /// travel raw. The public breakdown is resolved by the server and arrives as
  /// a [LocalizedValue] with `fallback_used` already decided.
  String nameFor(String language) {
    if (language == 'en') {
      final english = nameEn;
      if (english != null && english.trim().isNotEmpty) return english;
    }
    return nameHi;
  }
}

/// One movement of the temple's money, as the ledger shows it.
///
/// There is no public counterpart to this class and there is not going to be:
/// the public page publishes category totals, and this row carries who was
/// paid.
class Transaction {
  const Transaction({
    required this.id,
    required this.type,
    required this.categoryId,
    required this.amountPaise,
    required this.amountFormatted,
    required this.transactionDate,
    required this.paymentMode,
    required this.paymentModeLabel,
    required this.requiresReference,
    required this.status,
    required this.isLocked,
    required this.hasAttachment,
    this.typeLabel,
    this.category,
    this.referenceNumber,
    this.payeeName,
    this.description,
    this.attachmentName,
    this.attachmentSize,
    this.attachmentMime,
    this.approvedAt,
    this.approvedByName,
    this.reversedAt,
    this.reversedByName,
    this.reversalReason,
    this.createdByName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    final category = json['category'];

    return Transaction(
      id: _asInt(json['id']) ?? 0,
      type: read('type') ?? TransactionTypes.expense,
      typeLabel: read('type_label'),
      categoryId: _asInt(json['category_id']) ?? 0,
      category: category is Map<String, dynamic>
          ? AccountingCategory.fromJson(category)
          : null,
      // The paise are the authority and the formatted string is what a person
      // reads. Nothing on this side ever divides by a hundred.
      amountPaise: _asInt(json['amount_paise']) ?? 0,
      amountFormatted: read('amount_formatted') ?? '—',
      transactionDate: read('transaction_date') ?? '',
      paymentMode: read('payment_mode') ?? 'cash',
      paymentModeLabel: read('payment_mode_label') ?? '',
      referenceNumber: read('reference_number'),
      requiresReference: json['requires_reference'] == true,
      payeeName: read('payee_name'),
      description: read('description'),
      // What there is, never where it is: the stored path is not sent to any
      // client, so the bill is fetched by transaction id instead.
      hasAttachment: json['has_attachment'] == true,
      attachmentName: read('attachment_name'),
      attachmentSize: _asInt(json['attachment_size']),
      attachmentMime: read('attachment_mime'),
      status: read('status') ?? TransactionStatuses.pending,
      isLocked: json['is_locked'] == true,
      approvedAt: read('approved_at'),
      approvedByName: read('approved_by_name'),
      reversedAt: read('reversed_at'),
      reversedByName: read('reversed_by_name'),
      reversalReason: read('reversal_reason'),
      createdByName: read('created_by_name'),
    );
  }

  final int id;
  final String type;
  final String? typeLabel;
  final int categoryId;
  final AccountingCategory? category;
  final int amountPaise;
  final String amountFormatted;
  final String transactionDate;
  final String paymentMode;
  final String paymentModeLabel;
  final String? referenceNumber;
  final bool requiresReference;
  final String? payeeName;
  final String? description;
  final bool hasAttachment;
  final String? attachmentName;
  final int? attachmentSize;
  final String? attachmentMime;
  final String status;
  final bool isLocked;
  final String? approvedAt;
  final String? approvedByName;
  final String? reversedAt;
  final String? reversedByName;
  final String? reversalReason;
  final String? createdByName;

  bool get isIncome => type == TransactionTypes.income;

  bool get isPending => status == TransactionStatuses.pending;

  bool get isApproved => status == TransactionStatuses.approved;

  bool get isReversed => status == TransactionStatuses.reversed;
}

/// What the treasurer is about to write into the books.
///
/// Deliberately carries **no status and nothing about approval**: approving is
/// a decision with its own endpoint, not a field a form can set by naming it.
class TransactionDraft {
  const TransactionDraft({
    required this.amount,
    required this.transactionDate,
    required this.categoryId,
    required this.paymentMode,
    this.type,
    this.referenceNumber,
    this.payeeName,
    this.description,
  });

  /// As typed. Parsed into exact paise once, by the server — a client that
  /// parsed it too would be a second opinion about somebody's money.
  final String amount;
  final String transactionDate;
  final int categoryId;
  final String paymentMode;

  /// Optional: the category decides which side of the books an entry is on.
  final String? type;

  final String? referenceNumber;
  final String? payeeName;
  final String? description;

  Map<String, Object?> toJson() => {
    'amount': amount,
    'transaction_date': transactionDate,
    'category_id': categoryId,
    'type': ?type,
    'payment_mode': paymentMode,
    'reference_number': referenceNumber ?? '',
    'payee_name': payeeName ?? '',
    'description': description ?? '',
  };
}

/// A new or corrected heading.
class AccountingCategoryDraft {
  const AccountingCategoryDraft({
    required this.type,
    required this.nameHi,
    this.code,
    this.nameEn,
    this.descriptionHi,
    this.descriptionEn,
    this.sortOrder,
    this.isActive = true,
  });

  final String type;
  final String nameHi;
  final String? code;
  final String? nameEn;
  final String? descriptionHi;
  final String? descriptionEn;
  final int? sortOrder;
  final bool isActive;

  Map<String, Object?> toJson() => {
    'code': ?code,
    'type': type,
    'name_hi': nameHi,
    'name_en': nameEn ?? '',
    'description_hi': descriptionHi ?? '',
    'description_en': descriptionEn ?? '',
    'sort_order': ?sortOrder,
    'is_active': isActive,
  };
}

/// The running figures above the register.
class AccountsSummary {
  const AccountsSummary({
    required this.incomePaise,
    required this.expensePaise,
    required this.netPaise,
    required this.approvedCount,
    required this.pendingCount,
    required this.pendingIncomePaise,
    required this.pendingExpensePaise,
    required this.reversedCount,
  });

  factory AccountsSummary.fromJson(Map<String, dynamic> json) =>
      AccountsSummary(
        incomePaise: _asInt(json['income_paise']) ?? 0,
        expensePaise: _asInt(json['expense_paise']) ?? 0,
        netPaise: _asInt(json['net_paise']) ?? 0,
        approvedCount: _asInt(json['approved_count']) ?? 0,
        pendingCount: _asInt(json['pending_count']) ?? 0,
        pendingIncomePaise: _asInt(json['pending_income_paise']) ?? 0,
        pendingExpensePaise: _asInt(json['pending_expense_paise']) ?? 0,
        reversedCount: _asInt(json['reversed_count']) ?? 0,
      );

  static const AccountsSummary empty = AccountsSummary(
    incomePaise: 0,
    expensePaise: 0,
    netPaise: 0,
    approvedCount: 0,
    pendingCount: 0,
    pendingIncomePaise: 0,
    pendingExpensePaise: 0,
    reversedCount: 0,
  );

  /// Approved money only — the same rule the public page follows.
  final int incomePaise;
  final int expensePaise;

  /// Signed: a month that spent more than it received is a real month.
  final int netPaise;

  final int approvedCount;

  /// Named as pending wherever it is shown. Money nobody has checked yet.
  final int pendingCount;
  final int pendingIncomePaise;
  final int pendingExpensePaise;

  final int reversedCount;

  bool get hasPending => pendingCount > 0;
}

/// One page of the register.
class TransactionPage {
  const TransactionPage({required this.transactions, this.meta});

  final List<Transaction> transactions;
  final PageMeta? meta;
}

/// Whether the temple's books are public, and where they start.
class AccountingSettings {
  const AccountingSettings({
    required this.isPublished,
    required this.openingBalancePaise,
    required this.openingBalanceFormatted,
    this.openingBalanceDate,
    this.introHi,
    this.introEn,
    this.noteHi,
    this.noteEn,
    this.updatedAt,
    this.updatedByName,
  });

  factory AccountingSettings.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return AccountingSettings(
      isPublished: json['is_published'] == true,
      openingBalancePaise: _asInt(json['opening_balance_paise']) ?? 0,
      openingBalanceFormatted: read('opening_balance_formatted') ?? '₹0.00',
      openingBalanceDate: read('opening_balance_date'),
      introHi: read('intro_hi'),
      introEn: read('intro_en'),
      noteHi: read('note_hi'),
      noteEn: read('note_en'),
      updatedAt: read('updated_at'),
      updatedByName: read('updated_by_name'),
    );
  }

  final bool isPublished;
  final int openingBalancePaise;
  final String openingBalanceFormatted;
  final String? openingBalanceDate;
  final String? introHi;
  final String? introEn;
  final String? noteHi;
  final String? noteEn;
  final String? updatedAt;
  final String? updatedByName;
}

/// What the committee is about to change about publishing its books.
class AccountingSettingsDraft {
  const AccountingSettingsDraft({
    required this.isPublished,
    required this.openingBalance,
    this.openingBalanceDate,
    this.introHi,
    this.introEn,
    this.noteHi,
    this.noteEn,
  });

  final bool isPublished;

  /// As typed, and possibly negative: a temple that begins in deficit should be
  /// able to say so rather than rounding its own history up to zero.
  final String openingBalance;

  final String? openingBalanceDate;
  final String? introHi;
  final String? introEn;
  final String? noteHi;
  final String? noteEn;

  Map<String, Object?> toJson() => {
    'is_published': isPublished,
    'opening_balance': openingBalance,
    'opening_balance_date': openingBalanceDate ?? '',
    'intro_hi': introHi ?? '',
    'intro_en': introEn ?? '',
    'note_hi': noteHi ?? '',
    'note_en': noteEn ?? '',
  };
}

/// One line of the published breakdown: a heading and what it came to.
class CategoryTotal {
  const CategoryTotal({
    required this.code,
    required this.name,
    required this.totalPaise,
  });

  factory CategoryTotal.fromJson(Map<String, dynamic> json) {
    return CategoryTotal(
      code: json['code'] is String ? json['code'] as String : '',
      // Already resolved by the server, with `fallback_used` decided there.
      name: LocalizedValue.fromJson(json['name']),
      totalPaise: _asInt(json['total_paise']) ?? 0,
    );
  }

  final String code;
  final LocalizedValue name;
  final int totalPaise;
}

/// The figures for one financial year, exactly as the server computed them.
///
/// Nothing here is recomputed on this side. A total assembled in two places is
/// a total that eventually disagrees with itself, and this particular
/// disagreement would be the temple appearing to misstate its accounts.
class TransparencyYear {
  const TransparencyYear({
    required this.year,
    required this.yearLabel,
    required this.startsOn,
    required this.endsOn,
    required this.openingBalancePaise,
    required this.donationsPaise,
    required this.otherIncomePaise,
    required this.totalIncomePaise,
    required this.totalExpensePaise,
    required this.closingBalancePaise,
    required this.donationCount,
    required this.incomeByCategory,
    required this.expenseByCategory,
    this.asOf,
  });

  factory TransparencyYear.fromJson(Map<String, dynamic> json) {
    List<CategoryTotal> totals(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(CategoryTotal.fromJson)
          .toList(growable: false);
    }

    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return TransparencyYear(
      year: _asInt(json['year']) ?? 0,
      yearLabel: read('year_label') ?? '',
      startsOn: read('starts_on') ?? '',
      endsOn: read('ends_on') ?? '',
      openingBalancePaise: _asInt(json['opening_balance_paise']) ?? 0,
      donationsPaise: _asInt(json['donations_paise']) ?? 0,
      otherIncomePaise: _asInt(json['other_income_paise']) ?? 0,
      totalIncomePaise: _asInt(json['total_income_paise']) ?? 0,
      totalExpensePaise: _asInt(json['total_expense_paise']) ?? 0,
      closingBalancePaise: _asInt(json['closing_balance_paise']) ?? 0,
      donationCount: _asInt(json['donation_count']) ?? 0,
      incomeByCategory: totals('income_by_category'),
      expenseByCategory: totals('expense_by_category'),
      asOf: read('as_of'),
    );
  }

  final int year;
  final String yearLabel;
  final String startsOn;
  final String endsOn;

  /// Stated as its own line rather than folded into the total, so a reader can
  /// see that the books start somewhere.
  final int openingBalancePaise;

  /// Reported separately from [otherIncomePaise] so a reader can see which is
  /// which, and check each against its own source.
  final int donationsPaise;
  final int otherIncomePaise;

  final int totalIncomePaise;
  final int totalExpensePaise;
  final int closingBalancePaise;

  /// A count, never a name. No donor is identified on this page.
  final int donationCount;

  final List<CategoryTotal> incomeByCategory;
  final List<CategoryTotal> expenseByCategory;

  final String? asOf;

  bool get isEmpty =>
      totalIncomePaise == 0 &&
      totalExpensePaise == 0 &&
      openingBalancePaise == 0;
}

/// A financial year the public page may be asked for.
class TransparencyYearOption {
  const TransparencyYearOption({required this.year, required this.label});

  factory TransparencyYearOption.fromJson(Map<String, dynamic> json) =>
      TransparencyYearOption(
        year: _asInt(json['year']) ?? 0,
        label: json['label'] is String ? json['label'] as String : '',
      );

  final int year;
  final String label;
}

/// What the temple has published about its accounts.
///
/// [isPublished] false is a *value*, not a failure: it is what a temple whose
/// committee has not opened its books answers, and the page shows the temple's
/// own words for it rather than a page of zeros.
class Transparency {
  const Transparency({
    required this.isPublished,
    required this.intro,
    required this.note,
    this.openingBalanceDate,
    this.availableYears = const [],
    this.summary,
  });

  factory Transparency.fromJson(Map<String, dynamic> json) {
    final years = json['available_years'];
    final summary = json['summary'];

    return Transparency(
      isPublished: json['is_published'] == true,
      intro: LocalizedValue.fromJson(json['intro']),
      note: LocalizedValue.fromJson(json['note']),
      openingBalanceDate: json['opening_balance_date'] is String
          ? json['opening_balance_date'] as String
          : null,
      availableYears: years is List
          ? years
                .whereType<Map<String, dynamic>>()
                .map(TransparencyYearOption.fromJson)
                .toList(growable: false)
          : const [],
      summary: summary is Map<String, dynamic>
          ? TransparencyYear.fromJson(summary)
          : null,
    );
  }

  final bool isPublished;
  final LocalizedValue intro;
  final LocalizedValue note;
  final String? openingBalanceDate;
  final List<TransparencyYearOption> availableYears;

  /// Absent when the books are not published — see the class docblock.
  final TransparencyYear? summary;
}
