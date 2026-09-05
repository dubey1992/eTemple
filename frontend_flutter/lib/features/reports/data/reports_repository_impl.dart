import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/config/app_config.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/report.dart';
import '../domain/reports_repository.dart';

/// HTTP implementation of [ReportsRepository] against the Laravel API.
class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._api, this._config);

  final ApiClient _api;
  final AppConfig _config;

  @override
  Future<ReportCatalogue> catalogue({required String language}) async {
    final envelope = await _api.get<ReportCatalogue>(
      ApiEndpoints.adminReports,
      queryParameters: {'lang': language},
      decode: (data) => ReportCatalogue.fromJson(_object(data, 'report list')),
    );
    return envelope.data;
  }

  @override
  Future<ReportData> report(
    ReportQuery query, {
    required String language,
  }) async {
    final envelope = await _api.get<Map<String, dynamic>>(
      ApiEndpoints.adminReport(query.key),
      queryParameters: {...query.toQueryParameters(), 'lang': language},
      decode: (data) => _object(data, 'report'),
    );

    return ReportData.fromJson(envelope.data, envelope.rawMeta);
  }

  @override
  String exportUrl(
    ReportQuery query, {
    required String format,
    required String language,
  }) {
    // Built from the same query object the screen was drawn with. Nothing is
    // re-derived and no row is uploaded: the server runs the report again with
    // these filters, so the file and the screen agree by construction
    // (PHASE_10_PLAN assumption N1).
    final parameters =
        <String, String>{
            for (final entry in query.toQueryParameters().entries)
              if (entry.value != null) entry.key: '${entry.value}',
            'format': format,
            'lang': language,
          }
          // Paging is the one thing an export does not inherit: a file is the whole
          // filter, not the page somebody happened to be looking at.
          ..remove('page')
          ..remove('per_page');

    final query0 = parameters.entries
        .map(
          (e) =>
              '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}',
        )
        .join('&');

    return '${_config.apiBaseUrl}${ApiEndpoints.adminReportExport(query.key)}'
        '?$query0';
  }

  @override
  Future<Overview> overview({required String language}) async {
    final envelope = await _api.get<Overview>(
      ApiEndpoints.adminOverview,
      queryParameters: {'lang': language},
      decode: (data) => Overview.fromJson(_object(data, 'overview')),
    );
    return envelope.data;
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
