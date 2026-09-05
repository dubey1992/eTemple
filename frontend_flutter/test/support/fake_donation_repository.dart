import 'package:rkt_web/core/api/api_envelope.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/content/domain/localized_value.dart';
import 'package:rkt_web/features/donations/domain/donation.dart';
import 'package:rkt_web/features/donations/domain/donation_repository.dart';

/// Scriptable stand-in for the HTTP donation repository.
///
/// The **totals are not recomputed here**. The server computes them over every
/// donation matching the filter, and a fake that added up its own list would
/// quietly teach the tests that adding up a page is acceptable — which is
/// exactly the mistake the real summary exists to prevent. A test that cares
/// about totals sets [summary] to what the server would have said.
class FakeDonationRepository implements DonationRepository {
  FakeDonationRepository({
    List<Donation>? donations,
    this.details,
    AdminDonationSettings? settings,
    this.summary = DonationSummary.empty,
    this.lastPage = 1,
    this.listError,
    this.detailError,
    this.saveError,
    this.delay = Duration.zero,
  }) : register = donations ?? const [],
       _settings = settings ?? AdminDonationSettings.empty;

  List<Donation> register;
  DonationDetails? details;
  AdminDonationSettings _settings;

  // ignore: use_setters_to_change_properties
  void setSettings(AdminDonationSettings value) => _settings = value;
  DonationSummary summary;
  int lastPage;

  AppException? listError;
  AppException? detailError;
  AppException? saveError;
  Duration delay;

  int recordCalls = 0;
  int saveCalls = 0;
  int confirmCalls = 0;
  int reverseCalls = 0;
  int settingsSaveCalls = 0;

  DonationQuery? lastQuery;
  String? lastLanguage;
  DonationDraft? lastDraft;
  DonationSettingsDraft? lastSettingsDraft;
  int? lastConfirmedId;
  int? lastReversedId;
  String? lastReversalReason;

  Future<void> _pause() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  @override
  Future<DonationDetails?> publicDetails({required String language}) async {
    lastLanguage = language;
    await _pause();
    if (listError != null) throw listError!;
    return details;
  }

  @override
  Future<DonationPage> donations(DonationQuery query) async {
    lastQuery = query;
    await _pause();
    if (listError != null) throw listError!;

    final matching = register
        .where((d) => query.status == null || d.status == query.status)
        .where((d) => query.mode == null || d.paymentMode == query.mode)
        .where(
          (d) =>
              query.search == null ||
              d.donorName.contains(query.search!) ||
              (d.receiptNumber?.contains(query.search!) ?? false),
        )
        .toList();

    return DonationPage(
      donations: matching,
      summary: summary,
      meta: PageMeta(
        currentPage: query.page,
        perPage: query.perPage,
        total: matching.length,
        lastPage: lastPage,
        hasMore: query.page < lastPage,
      ),
    );
  }

  @override
  Future<Donation> donation(int id) async {
    await _pause();
    if (detailError != null) throw detailError!;

    return register.firstWhere(
      (d) => d.id == id,
      orElse: () => throw const AppException(code: ErrorCode.notFound),
    );
  }

  @override
  Future<Donation> record(DonationDraft draft) async {
    recordCalls++;
    lastDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testDonation(id: 99, donorName: draft.donorName);
  }

  @override
  Future<Donation> save(int id, DonationDraft draft) async {
    saveCalls++;
    lastDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return testDonation(id: id, donorName: draft.donorName);
  }

  @override
  Future<Donation> confirm(int id) async {
    confirmCalls++;
    lastConfirmedId = id;
    await _pause();
    if (saveError != null) throw saveError!;
    return testDonation(
      id: id,
      status: DonationStatuses.confirmed,
      receiptNumber: 'RKT/2026-27/0001',
      isLocked: true,
    );
  }

  @override
  Future<Donation> reverse(int id, String reason) async {
    reverseCalls++;
    lastReversedId = id;
    lastReversalReason = reason;
    await _pause();
    if (saveError != null) throw saveError!;
    return testDonation(
      id: id,
      status: DonationStatuses.reversed,
      reversalReason: reason,
    );
  }

  @override
  String receiptUrl(int id) =>
      'https://api.example/api/admin/donations/$id/receipt';

  @override
  Future<AdminDonationSettings> settings() async {
    await _pause();
    if (listError != null) throw listError!;
    return _settings;
  }

  @override
  Future<AdminDonationSettings> saveSettings(
    DonationSettingsDraft draft,
  ) async {
    settingsSaveCalls++;
    lastSettingsDraft = draft;
    await _pause();
    if (saveError != null) throw saveError!;
    return _settings;
  }
}

/// One donation, as the register would show it.
Donation testDonation({
  int id = 1,
  String donorName = 'रामप्रसाद यादव',
  int amountPaise = 50_100,
  String amountFormatted = '₹501.00',
  String donationDate = '2026-06-15',
  String paymentMode = PaymentModes.cash,
  String purpose = DonationPurposes.general,
  String status = DonationStatuses.pending,
  String? receiptNumber,
  String? referenceNumber,
  String? notes,
  String? reversalReason,
  bool isLocked = false,
  bool isAnonymous = false,
}) {
  return Donation(
    id: id,
    donorName: donorName,
    amountPaise: amountPaise,
    amountFormatted: amountFormatted,
    donationDate: donationDate,
    paymentMode: paymentMode,
    purpose: purpose,
    status: status,
    receiptNumber: receiptNumber,
    referenceNumber: referenceNumber,
    notes: notes,
    reversalReason: reversalReason,
    reversedAt: reversalReason == null ? null : '2026-06-20T10:00:00+05:30',
    isLocked: isLocked || receiptNumber != null,
    isAnonymous: isAnonymous,
  );
}

LocalizedValue _hi(String? value) =>
    LocalizedValue(value: value, language: 'hi', fallbackUsed: false);

/// The published bank details, as a visitor would receive them.
DonationDetails testDonationDetails({
  String? upiId = 'thakurbari@upi',
  String? bankName = 'Demo Bank',
  String? accountName = 'Radha Krishna Thakurbari',
  String? accountNumber = 'XXXX XXXX 1234',
  String? ifsc = 'DEMO0001234',
  String? qrUrl,
  String? intro,
  String? note,
}) {
  return DonationDetails(
    upiId: upiId,
    bankName: bankName,
    accountName: accountName,
    accountNumber: accountNumber,
    ifsc: ifsc,
    qrUrl: qrUrl,
    intro: _hi(intro),
    note: _hi(note),
  );
}

DonationSummary testSummary({
  int totalPaise = 12_550_000,
  String totalFormatted = '₹1,25,500.00',
  int pendingPaise = 0,
  String pendingFormatted = '₹0.00',
  int confirmedCount = 2,
  int pendingCount = 1,
  int reversedCount = 0,
  int donorCount = 126,
}) {
  return DonationSummary(
    totalPaise: totalPaise,
    totalFormatted: totalFormatted,
    pendingPaise: pendingPaise,
    pendingFormatted: pendingFormatted,
    confirmedCount: confirmedCount,
    pendingCount: pendingCount,
    reversedCount: reversedCount,
    donorCount: donorCount,
  );
}
