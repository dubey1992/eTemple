import 'package:rkt_web/core/api/api_envelope.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/features/enquiries/domain/enquiry.dart';
import 'package:rkt_web/features/enquiries/domain/enquiry_repository.dart';

/// Scriptable stand-in for the HTTP enquiry repository.
///
/// The **anti-spam decisions are not reimplemented here**. Whether a ticket is
/// stale, spent or needs a question is the server's judgement, and a fake that
/// made those calls itself would test the fake. What it does instead is let a
/// test say what the server answered — including refusing — so the screens can
/// be checked against every answer the real one can give.
class FakeEnquiryRepository implements EnquiryRepository {
  FakeEnquiryRepository({
    EnquiryForm? form,
    List<Enquiry>? enquiries,
    this.summaryResult = EnquirySummary.empty,
    this.lastPage = 1,
    this.receipt,
    this.formError,
    this.submitError,
    this.listError,
    this.detailError,
    this.updateError,
  }) : _form = form ?? testEnquiryForm(),
       inbox = enquiries ?? const [];

  EnquiryForm _form;
  List<Enquiry> inbox;
  EnquirySummary summaryResult;
  int lastPage;

  /// What [submit] returns when it is not made to fail.
  EnquiryReceipt? receipt;

  AppException? formError;
  AppException? submitError;
  AppException? listError;
  AppException? detailError;
  AppException? updateError;

  int formCalls = 0;
  int submitCalls = 0;
  EnquiryDraft? lastDraft;
  EnquiryQuery? lastQuery;
  final List<(int, String)> statusChanges = [];
  final List<(int, int?)> assignments = [];

  // ignore: use_setters_to_change_properties
  void setForm(EnquiryForm value) => _form = value;

  @override
  Future<EnquiryForm> form() async {
    formCalls++;
    if (formError != null) throw formError!;
    return _form;
  }

  @override
  Future<EnquiryReceipt> submit(EnquiryDraft draft) async {
    submitCalls++;
    lastDraft = draft;
    if (submitError != null) throw submitError!;

    return receipt ??
        const EnquiryReceipt(
          reference: 'RKT/E/2026-27/0001',
          message: 'received',
        );
  }

  @override
  Future<EnquiryPage> enquiries(EnquiryQuery query) async {
    lastQuery = query;
    if (listError != null) throw listError!;

    return EnquiryPage(
      enquiries: inbox,
      meta: PageMeta(
        currentPage: query.page,
        lastPage: lastPage,
        perPage: query.perPage,
        total: inbox.length,
        hasMore: query.page < lastPage,
      ),
    );
  }

  @override
  Future<EnquirySummary> summary(EnquiryQuery query) async {
    if (listError != null) throw listError!;
    return summaryResult;
  }

  @override
  Future<Enquiry> enquiry(int id) async {
    if (detailError != null) throw detailError!;
    return inbox.firstWhere((item) => item.id == id);
  }

  @override
  Future<Enquiry> updateStatus(int id, String status) async {
    statusChanges.add((id, status));
    if (updateError != null) throw updateError!;
    return _replace(id, status: status);
  }

  @override
  Future<Enquiry> assign(int id, int? userId) async {
    assignments.add((id, userId));
    if (updateError != null) throw updateError!;
    return _replace(id, assignedTo: userId);
  }

  Enquiry _replace(int id, {String? status, int? assignedTo}) {
    final existing = inbox.firstWhere((item) => item.id == id);
    final updated = testEnquiry(
      id: existing.id,
      reference: existing.reference,
      name: existing.name,
      mobile: existing.mobile,
      email: existing.email,
      category: existing.category,
      message: existing.message,
      status: status ?? existing.status,
      assignedTo: assignedTo,
    );

    inbox = [for (final item in inbox) item.id == id ? updated : item];

    return updated;
  }
}

/// A form ticket with no question attached, which is the ordinary case.
EnquiryForm testEnquiryForm({
  EnquiryChallenge? challenge,
  String token = 'test-token',
  int minMessageLength = 20,
}) => EnquiryForm(
  token: token,
  challenge: challenge,
  minFillSeconds: 0,
  expiresInSeconds: 7200,
  categories: const [],
  minMessageLength: minMessageLength,
  maxMessageLength: 2000,
);

Enquiry testEnquiry({
  int id = 1,
  String reference = 'RKT/E/2026-27/0001',
  String name = 'सीता देवी',
  String? mobile = '9876500011',
  String? email,
  String category = EnquiryCategories.general,
  String message = 'मंदिर में सुबह की आरती किस समय होती है?',
  String status = EnquiryStatuses.isNew,
  int? assignedTo,
  String? assignedToName,
  DateTime? createdAt,
}) => Enquiry(
  id: id,
  reference: reference,
  name: name,
  mobile: mobile,
  email: email,
  category: category,
  categoryLabel: 'सामान्य जानकारी / General enquiry',
  message: message,
  preferredLanguage: 'hi',
  status: status,
  isOpen: EnquiryStatuses.isOpen(status),
  assignedTo: assignedTo,
  assignedToName: assignedToName,
  createdAt: createdAt ?? DateTime(2026, 9, 11),
);
