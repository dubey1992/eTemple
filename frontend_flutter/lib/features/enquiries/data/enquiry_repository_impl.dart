import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/enquiry.dart';
import '../domain/enquiry_repository.dart';

/// HTTP implementation of [EnquiryRepository] against the Laravel API.
class EnquiryRepositoryImpl implements EnquiryRepository {
  const EnquiryRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<EnquiryForm> form() async {
    final envelope = await _api.get<EnquiryForm>(
      ApiEndpoints.publicEnquiryForm,
      decode: (data) => EnquiryForm.fromJson(_object(data, 'contact form')),
    );
    return envelope.data;
  }

  @override
  Future<EnquiryReceipt> submit(EnquiryDraft draft) async {
    final envelope = await _api.post<EnquiryReceipt>(
      ApiEndpoints.publicEnquiries,
      body: draft.toJson(),
      decode: (data) =>
          EnquiryReceipt.fromJson(_object(data, 'enquiry acknowledgement')),
    );
    return envelope.data;
  }

  @override
  Future<EnquiryPage> enquiries(EnquiryQuery query) async {
    final envelope = await _api.get<List<Enquiry>>(
      ApiEndpoints.adminEnquiries,
      queryParameters: query.toQueryParameters(),
      decode: (data) => _list(
        data,
        'enquiries',
      ).map(Enquiry.fromJson).toList(growable: false),
    );

    return EnquiryPage(enquiries: envelope.data, meta: envelope.meta);
  }

  @override
  Future<EnquirySummary> summary(EnquiryQuery query) async {
    final envelope = await _api.get<EnquirySummary>(
      ApiEndpoints.adminEnquirySummary,
      queryParameters: {
        // The status is deliberately not sent: the counts describe the whole
        // inbox, not the tab the reader happens to be on.
        'category': ?query.category,
        'assigned_to': ?query.assignedTo,
        'search': ?query.search,
      },
      decode: (data) =>
          EnquirySummary.fromJson(_object(data, 'enquiry summary')),
    );
    return envelope.data;
  }

  @override
  Future<Enquiry> enquiry(int id) async {
    final envelope = await _api.get<Enquiry>(
      ApiEndpoints.adminEnquiry(id),
      decode: (data) => Enquiry.fromJson(_object(data, 'enquiry')),
    );
    return envelope.data;
  }

  @override
  Future<Enquiry> updateStatus(int id, String status) =>
      _patch(id, {'status': status});

  @override
  Future<Enquiry> assign(int id, int? userId) =>
      // Sent explicitly as null when unassigning: the server distinguishes an
      // absent key from a null one, and so must this.
      _patch(id, {'assigned_to': userId});

  Future<Enquiry> _patch(int id, Map<String, Object?> body) async {
    final envelope = await _api.put<Enquiry>(
      ApiEndpoints.adminEnquiryStatus(id),
      body: body,
      decode: (data) => Enquiry.fromJson(_object(data, 'enquiry')),
    );
    return envelope.data;
  }

  static List<Map<String, dynamic>> _list(Object? data, String what) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  static Map<String, dynamic> _object(Object? data, String what) {
    if (data is! Map<String, dynamic>) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected $what.',
      );
    }

    return data;
  }
}
