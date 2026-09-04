import '../errors/app_exception.dart';
import '../errors/error_code.dart';

/// Pagination block returned in the envelope's `meta` object.
///
/// Defined once here and reused by every paginated endpoint from Phase 1 on.
class PageMeta {
  const PageMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
    required this.lastPage,
    required this.hasMore,
  });

  factory PageMeta.fromJson(Map<String, dynamic> json) {
    final currentPage = _asInt(json['current_page']) ?? 1;
    final lastPage = _asInt(json['last_page']) ?? currentPage;

    return PageMeta(
      currentPage: currentPage,
      perPage: _asInt(json['per_page']) ?? 0,
      total: _asInt(json['total']) ?? 0,
      lastPage: lastPage,
      // Defensive: derive the flag when an older server omits it.
      hasMore: json['has_more'] as bool? ?? currentPage < lastPage,
    );
  }

  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;
  final bool hasMore;

  static int? _asInt(Object? value) => switch (value) {
    final int v => v,
    final num v => v.toInt(),
    final String v => int.tryParse(v),
    _ => null,
  };
}

/// A decoded success envelope: `{"success": true, "data": ..., "meta": ...}`.
class ApiEnvelope<T> {
  const ApiEnvelope({required this.data, this.meta});

  final T data;
  final PageMeta? meta;
}

/// Parses the API's JSON envelope.
///
/// Parsing is deliberately defensive (spec: "Keep Flutter DTO/model parsing
/// defensive against nullable/optional fields"): a payload that does not match
/// the contract raises [ErrorCode.malformedResponse] rather than a raw cast
/// error deep inside a widget.
class ApiEnvelopeParser {
  const ApiEnvelopeParser._();

  /// Decodes a success envelope and maps `data` with [fromData].
  static ApiEnvelope<T> parse<T>(
    Object? body,
    T Function(Object? data) fromData,
  ) {
    final map = asMap(body);
    if (map == null) {
      throw const AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Response body was not a JSON object.',
      );
    }

    if (map['success'] != true) {
      throw parseError(map, statusCode: null);
    }

    final metaJson = asMap(map['meta']);

    return ApiEnvelope<T>(
      data: fromData(map['data']),
      meta: metaJson != null && metaJson.containsKey('current_page')
          ? PageMeta.fromJson(metaJson)
          : null,
    );
  }

  /// Builds an [AppException] from an error envelope.
  ///
  /// Falls back to a status-code-derived code when the body is missing or does
  /// not follow the contract (for example an HTML error page from a proxy).
  static AppException parseError(Object? body, {required int? statusCode}) {
    final map = asMap(body);
    final error = asMap(map?['error']);

    final code = error == null
        ? _codeForStatus(statusCode)
        : ErrorCode.fromWire(error['code'] as String?);

    return AppException(
      code: code == ErrorCode.unknown ? _codeForStatus(statusCode) : code,
      debugMessage: error?['message'] as String?,
      fieldErrors: _parseFieldErrors(error?['details']),
      statusCode: statusCode,
    );
  }

  static Map<String, dynamic>? asMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((k, v) => MapEntry('$k', v));
    return null;
  }

  static Map<String, List<String>> _parseFieldErrors(Object? details) {
    final map = asMap(details);
    if (map == null) return const {};

    final result = <String, List<String>>{};
    map.forEach((field, messages) {
      if (messages is List) {
        result[field] = messages.map((m) => '$m').toList(growable: false);
      } else if (messages is String) {
        result[field] = [messages];
      }
    });
    return result;
  }

  static ErrorCode _codeForStatus(int? status) => switch (status) {
    401 => ErrorCode.unauthenticated,
    403 => ErrorCode.forbidden,
    404 => ErrorCode.notFound,
    405 => ErrorCode.methodNotAllowed,
    419 => ErrorCode.csrfTokenMismatch,
    422 => ErrorCode.validationFailed,
    429 => ErrorCode.tooManyRequests,
    final int s when s >= 500 => ErrorCode.serverError,
    _ => ErrorCode.unknown,
  };
}
