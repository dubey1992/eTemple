import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/audit_entry.dart';
import '../domain/audit_repository.dart';

/// HTTP implementation of [AuditRepository] against the Laravel API.
class AuditRepositoryImpl implements AuditRepository {
  const AuditRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<AuditPage> entries(AuditQuery query) async {
    final envelope = await _api.get<List<AuditEntry>>(
      ApiEndpoints.adminAuditLogs,
      queryParameters: query.toQueryParameters(),
      decode: (data) =>
          _list(data)
              .map((row) => AuditEntry.fromJson(row))
              .toList(growable: false),
    );

    final meta = envelope.meta;

    return AuditPage(
      entries: envelope.data,
      total: meta?.total ?? envelope.data.length,
      hasMore: meta?.hasMore ?? false,
    );
  }

  @override
  Future<List<AuditActionOption>> actions() async {
    final envelope = await _api.get<List<AuditActionOption>>(
      ApiEndpoints.adminAuditActions,
      decode: (data) {
        final map = data is Map<String, dynamic> ? data : const {};
        return _list(map['actions'])
            .map((row) => AuditActionOption.fromJson(row))
            .toList(growable: false);
      },
    );

    return envelope.data;
  }

  List<Map<String, dynamic>> _list(Object? data) {
    if (data is! List) {
      throw const AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'The audit trail did not arrive as a list.',
      );
    }

    return data.whereType<Map<String, dynamic>>().toList(growable: false);
  }
}
