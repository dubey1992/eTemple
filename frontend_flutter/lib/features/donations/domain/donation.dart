import '../../../core/api/api_envelope.dart';
import '../../content/domain/localized_value.dart';

/// How a donation reached the temple, mirroring `App\Support\PaymentMode`.
class PaymentModes {
  const PaymentModes._();

  static const String cash = 'cash';
  static const String upi = 'upi';
  static const String bankTransfer = 'bank_transfer';
  static const String cheque = 'cheque';
  static const String card = 'card';
  static const String other = 'other';

  static const List<String> all = [
    cash,
    upi,
    bankTransfer,
    cheque,
    card,
    other,
  ];

  /// Cash is the only mode that leaves nothing to match against a statement,
  /// so it is the only one allowed to arrive without a reference. The server
  /// enforces this; the form uses it to decide whether to mark the field
  /// required.
  static bool requiresReference(String mode) => mode != cash;
}

/// What a donation was given for, mirroring `App\Support\DonationPurpose`.
class DonationPurposes {
  const DonationPurposes._();

  static const String general = 'general';
  static const String puja = 'puja';
  static const String maintenance = 'maintenance';
  static const String festival = 'festival';
  static const String annadan = 'annadan';
  static const String construction = 'construction';
  static const String other = 'other';

  static const List<String> all = [
    general,
    puja,
    maintenance,
    festival,
    annadan,
    construction,
    other,
  ];
}

/// Where a donation is in its life, mirroring `App\Models\Donation`.
class DonationStatuses {
  const DonationStatuses._();

  /// Recorded, not yet matched against the bank statement or the cash box.
  /// Has no receipt number, and can still be corrected.
  static const String pending = 'pending';

  /// Verified. Has a receipt number, and counts in every total.
  static const String confirmed = 'confirmed';

  /// Cancelled. Keeps its receipt number, counts in no total.
  static const String reversed = 'reversed';

  static const List<String> all = [pending, confirmed, reversed];
}

/// One donation, as the register shows it.
///
/// There is no public counterpart to this class and there is not going to be:
/// donor detail reaches no public endpoint at any status. Everything here comes
/// from an endpoint behind `donations.view`.
class Donation {
  const Donation({
    required this.id,
    required this.donorName,
    required this.amountPaise,
    required this.amountFormatted,
    required this.donationDate,
    required this.paymentMode,
    required this.purpose,
    required this.status,
    required this.isLocked,
    required this.isAnonymous,
    this.receiptNumber,
    this.donorPhone,
    this.donorAddress,
    this.referenceNumber,
    this.notes,
    this.recordedBy,
    this.confirmedAt,
    this.confirmedBy,
    this.reversedAt,
    this.reversedBy,
    this.reversalReason,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return Donation(
      id: asInt(json['id']) ?? 0,
      receiptNumber: read('receipt_number'),
      donorName: read('donor_name') ?? '',
      donorPhone: read('donor_phone'),
      donorAddress: read('donor_address'),
      isAnonymous: json['is_anonymous'] == true,
      // The paise are the authority and the formatted string is what a person
      // reads. Nothing on this side ever divides by a hundred.
      amountPaise: asInt(json['amount_paise']) ?? 0,
      amountFormatted: read('amount_formatted') ?? '—',
      donationDate: read('donation_date') ?? '',
      paymentMode: read('payment_mode') ?? PaymentModes.cash,
      referenceNumber: read('reference_number'),
      purpose: read('purpose') ?? DonationPurposes.general,
      notes: read('notes'),
      status: read('status') ?? DonationStatuses.pending,
      isLocked: json['is_locked'] == true,
      recordedBy: read('recorded_by'),
      confirmedAt: read('confirmed_at'),
      confirmedBy: read('confirmed_by'),
      reversedAt: read('reversed_at'),
      reversedBy: read('reversed_by'),
      reversalReason: read('reversal_reason'),
    );
  }

  final int id;

  /// Null until the donation is confirmed. A number that exists corresponds to
  /// a receipt that was really given.
  final String? receiptNumber;

  final String donorName;
  final String? donorPhone;
  final String? donorAddress;
  final bool isAnonymous;

  final int amountPaise;
  final String amountFormatted;

  /// `YYYY-MM-DD`, a date and not an instant: a donation happens on a day.
  final String donationDate;

  final String paymentMode;
  final String? referenceNumber;
  final String purpose;
  final String? notes;

  final String status;

  /// True once a receipt has been issued. From then on only the notes may be
  /// edited — the server refuses the rest, and this stops the screen offering
  /// controls that would fail.
  final bool isLocked;

  final String? recordedBy;
  final String? confirmedAt;
  final String? confirmedBy;
  final String? reversedAt;
  final String? reversedBy;
  final String? reversalReason;

  bool get isPending => status == DonationStatuses.pending;

  bool get isConfirmed => status == DonationStatuses.confirmed;

  bool get isReversed => status == DonationStatuses.reversed;

  bool get needsReference => PaymentModes.requiresReference(paymentMode);

  static int? asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// The count and total that ride with the register.
///
/// Computed by the server over **every** donation matching the filter, not by
/// adding up the page in view — which would quietly report the total of one
/// page as the total of everything.
class DonationSummary {
  const DonationSummary({
    required this.totalPaise,
    required this.totalFormatted,
    required this.pendingPaise,
    required this.pendingFormatted,
    required this.confirmedCount,
    required this.pendingCount,
    required this.reversedCount,
    required this.donorCount,
  });

  factory DonationSummary.fromJson(Map<String, dynamic> json) {
    String read(String key, String fallback) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : fallback;
    }

    return DonationSummary(
      totalPaise: Donation.asInt(json['total_paise']) ?? 0,
      totalFormatted: read('total_formatted', '—'),
      pendingPaise: Donation.asInt(json['pending_paise']) ?? 0,
      pendingFormatted: read('pending_formatted', '—'),
      confirmedCount: Donation.asInt(json['confirmed_count']) ?? 0,
      pendingCount: Donation.asInt(json['pending_count']) ?? 0,
      reversedCount: Donation.asInt(json['reversed_count']) ?? 0,
      donorCount: Donation.asInt(json['donor_count']) ?? 0,
    );
  }

  static const DonationSummary empty = DonationSummary(
    totalPaise: 0,
    totalFormatted: '—',
    pendingPaise: 0,
    pendingFormatted: '—',
    confirmedCount: 0,
    pendingCount: 0,
    reversedCount: 0,
    donorCount: 0,
  );

  final int totalPaise;
  final String totalFormatted;
  final int pendingPaise;
  final String pendingFormatted;
  final int confirmedCount;
  final int pendingCount;
  final int reversedCount;
  final int donorCount;
}

/// One page of the register, with the totals for the whole filter.
class DonationPage {
  const DonationPage({
    required this.donations,
    required this.summary,
    this.meta,
  });

  static const DonationPage empty = DonationPage(
    donations: [],
    summary: DonationSummary.empty,
  );

  final List<Donation> donations;
  final DonationSummary summary;
  final PageMeta? meta;

  bool get hasMore => meta?.hasMore ?? false;

  int get total => meta?.total ?? donations.length;

  int get currentPage => meta?.currentPage ?? 1;
}

/// A donation being recorded or corrected.
///
/// The amount travels as the **string the treasurer typed**. Parsing it into
/// paise is the server's job and is done in exactly one place; a double here
/// would round ₹501.50 before the request was even sent.
class DonationDraft {
  const DonationDraft({
    required this.donorName,
    required this.amount,
    required this.donationDate,
    required this.paymentMode,
    required this.purpose,
    this.donorPhone,
    this.donorAddress,
    this.referenceNumber,
    this.notes,
    this.isAnonymous = false,
  });

  final String donorName;
  final String amount;
  final String donationDate;
  final String paymentMode;
  final String purpose;
  final String? donorPhone;
  final String? donorAddress;
  final String? referenceNumber;
  final String? notes;
  final bool isAnonymous;

  Map<String, Object?> toJson() => {
    'donor_name': donorName.trim(),
    'donor_phone': nullIfBlank(donorPhone),
    'donor_address': nullIfBlank(donorAddress),
    'is_anonymous': isAnonymous,
    'amount': amount.trim(),
    'donation_date': donationDate,
    'payment_mode': paymentMode,
    'reference_number': nullIfBlank(referenceNumber),
    'purpose': purpose,
    'notes': nullIfBlank(notes),
  };

  /// Blank optional fields are sent as null so the server stores "absent"
  /// rather than an empty string.
  static String? nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}

/// Where devotees may send money, as a visitor sees it.
///
/// The whole public surface of this phase. There is no donor here, no amount
/// and no count.
class DonationDetails {
  const DonationDetails({
    required this.intro,
    required this.note,
    this.upiId,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.ifsc,
    this.qrUrl,
  });

  factory DonationDetails.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value.trim() : null;
    }

    return DonationDetails(
      upiId: read('upi_id'),
      bankName: read('bank_name'),
      accountName: read('account_name'),
      // Exactly as the committee typed it: whether to mask it, and how, is
      // their decision and their bank's policy.
      accountNumber: read('account_number'),
      ifsc: read('ifsc'),
      qrUrl: read('qr_url'),
      intro: LocalizedValue.fromJson(json['intro']),
      note: LocalizedValue.fromJson(json['note']),
    );
  }

  final String? upiId;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? ifsc;
  final String? qrUrl;
  final LocalizedValue intro;
  final LocalizedValue note;

  /// The labelled rows of the prototype's bank box, in its order, with anything
  /// the committee has not filled in simply absent.
  List<(String, String)> rows({
    required String upiLabel,
    required String bankLabel,
    required String accountNameLabel,
    required String accountLabel,
    required String ifscLabel,
  }) => [
    if (upiId != null) (upiLabel, upiId!),
    if (bankName != null) (bankLabel, bankName!),
    if (accountName != null) (accountNameLabel, accountName!),
    if (accountNumber != null) (accountLabel, accountNumber!),
    if (ifsc != null) (ifscLabel, ifsc!),
  ];
}

/// The donation details as the editor sees them.
class AdminDonationSettings {
  const AdminDonationSettings({
    required this.isPublished,
    required this.isPubliclyVisible,
    this.upiId,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.ifsc,
    this.qrUrl,
    this.introHi,
    this.introEn,
    this.noteHi,
    this.noteEn,
  });

  factory AdminDonationSettings.fromJson(Map<String, dynamic> json) {
    String? read(String key) {
      final value = json[key];
      return value is String && value.trim().isNotEmpty ? value : null;
    }

    return AdminDonationSettings(
      upiId: read('upi_id'),
      bankName: read('bank_name'),
      accountName: read('account_name'),
      accountNumber: read('account_number'),
      ifsc: read('ifsc'),
      qrUrl: read('qr_url'),
      introHi: read('intro_hi'),
      introEn: read('intro_en'),
      noteHi: read('note_hi'),
      noteEn: read('note_en'),
      isPublished: json['is_published'] == true,
      isPubliclyVisible: json['is_publicly_visible'] == true,
    );
  }

  static const AdminDonationSettings empty = AdminDonationSettings(
    isPublished: false,
    isPubliclyVisible: false,
  );

  final String? upiId;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? ifsc;
  final String? qrUrl;
  final String? introHi;
  final String? introEn;
  final String? noteHi;
  final String? noteEn;
  final bool isPublished;

  /// Not the same as [isPublished]: a row published with every field blank
  /// would render an empty box on the public page, which reads as a broken site
  /// rather than an unconfigured one. The editor is told both.
  final bool isPubliclyVisible;
}

/// An edit to the published donation details.
class DonationSettingsDraft {
  const DonationSettingsDraft({
    required this.isPublished,
    this.upiId,
    this.bankName,
    this.accountName,
    this.accountNumber,
    this.ifsc,
    this.qrUrl,
    this.introHi,
    this.introEn,
    this.noteHi,
    this.noteEn,
  });

  final String? upiId;
  final String? bankName;
  final String? accountName;
  final String? accountNumber;
  final String? ifsc;
  final String? qrUrl;
  final String? introHi;
  final String? introEn;
  final String? noteHi;
  final String? noteEn;
  final bool isPublished;

  Map<String, Object?> toJson() => {
    'upi_id': DonationDraft.nullIfBlank(upiId),
    'bank_name': DonationDraft.nullIfBlank(bankName),
    'account_name': DonationDraft.nullIfBlank(accountName),
    'account_number': DonationDraft.nullIfBlank(accountNumber),
    'ifsc': DonationDraft.nullIfBlank(ifsc),
    'qr_url': DonationDraft.nullIfBlank(qrUrl),
    'intro_hi': DonationDraft.nullIfBlank(introHi),
    'intro_en': DonationDraft.nullIfBlank(introEn),
    'note_hi': DonationDraft.nullIfBlank(noteHi),
    'note_en': DonationDraft.nullIfBlank(noteEn),
    'is_published': isPublished,
  };
}
