import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/donation.dart';
import '../domain/donation_repository.dart';

/// HTTP implementation of [DonationRepository] against the Laravel API.
class DonationRepositoryImpl implements DonationRepository {
  const DonationRepositoryImpl(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  @override
  Future<DonationDetails?> publicDetails({required String language}) async {
    final envelope = await _api.get<DonationDetails?>(
      ApiEndpoints.publicDonationSettings,
      queryParameters: {'lang': language},
      decode: (data) {
        final json = ApiEnvelopeParser.asMap(data);
        // Null is the documented answer for a site whose committee has not
        // published anything: an empty state, not a failure.
        return json == null ? null : DonationDetails.fromJson(json);
      },
    );
    return envelope.data;
  }

  @override
  Future<DonationPage> donations(DonationQuery query) async {
    final envelope = await _api.get<List<Donation>>(
      ApiEndpoints.adminDonations,
      queryParameters: query.toQueryParameters(),
      decode: (data) => _list(
        data,
        'donations',
      ).map(Donation.fromJson).toList(growable: false),
    );

    // The summary rides in `meta` beside the pagination block, so the screen
    // never has to add up a page and call it a total.
    return DonationPage(
      donations: envelope.data,
      summary: _summaryFrom(envelope.rawMeta),
      meta: envelope.meta,
    );
  }

  @override
  Future<Donation> donation(int id) async {
    final envelope = await _api.get<Donation>(
      ApiEndpoints.adminDonation(id),
      decode: (data) => Donation.fromJson(_object(data, 'donation')),
    );
    return envelope.data;
  }

  @override
  Future<Donation> record(DonationDraft draft) async {
    final envelope = await _api.post<Donation>(
      ApiEndpoints.adminDonations,
      body: draft.toJson(),
      decode: (data) => Donation.fromJson(_object(data, 'donation')),
    );
    return envelope.data;
  }

  @override
  Future<Donation> save(int id, DonationDraft draft) async {
    final envelope = await _api.put<Donation>(
      ApiEndpoints.adminDonation(id),
      body: draft.toJson(),
      decode: (data) => Donation.fromJson(_object(data, 'donation')),
    );
    return envelope.data;
  }

  @override
  Future<Donation> confirm(int id) async {
    final envelope = await _api.post<Donation>(
      ApiEndpoints.adminDonationConfirm(id),
      decode: (data) => Donation.fromJson(_object(data, 'donation')),
    );
    return envelope.data;
  }

  @override
  Future<Donation> reverse(int id, String reason) async {
    final envelope = await _api.post<Donation>(
      ApiEndpoints.adminDonationReverse(id),
      body: {'reversal_reason': reason.trim()},
      decode: (data) => Donation.fromJson(_object(data, 'donation')),
    );
    return envelope.data;
  }

  @override
  String receiptUrl(int id) =>
      '${_config.apiBaseUrl}${ApiEndpoints.adminDonationReceipt(id)}';

  @override
  Future<AdminDonationSettings> settings() async {
    final envelope = await _api.get<AdminDonationSettings>(
      ApiEndpoints.adminDonationSettings,
      decode: (data) =>
          AdminDonationSettings.fromJson(_object(data, 'donation settings')),
    );
    return envelope.data;
  }

  @override
  Future<AdminDonationSettings> saveSettings(
    DonationSettingsDraft draft,
  ) async {
    final envelope = await _api.put<AdminDonationSettings>(
      ApiEndpoints.adminDonationSettings,
      body: draft.toJson(),
      decode: (data) =>
          AdminDonationSettings.fromJson(_object(data, 'donation settings')),
    );
    return envelope.data;
  }

  static DonationSummary _summaryFrom(Map<String, dynamic>? meta) {
    final json = ApiEnvelopeParser.asMap(meta?['summary']);
    return json == null
        ? DonationSummary.empty
        : DonationSummary.fromJson(json);
  }

  static List<Map<String, dynamic>> _list(Object? data, String what) {
    if (data is! List) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a list of $what.',
      );
    }
    return data
        .map(ApiEnvelopeParser.asMap)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  static Map<String, dynamic> _object(Object? data, String what) {
    final json = ApiEnvelopeParser.asMap(data);
    if (json == null) {
      throw AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a $what object in the response data.',
      );
    }
    return json;
  }
}
