import 'error_code.dart';

/// A failure the UI is allowed to see.
///
/// Everything thrown out of the data layer is normalised into this type by
/// [ErrorMapper], so widgets never handle Dio types, status codes or server
/// stack traces.
class AppException implements Exception {
  const AppException({
    required this.code,
    this.debugMessage,
    this.fieldErrors = const {},
    this.statusCode,
  });

  /// A failure with no useful classification, for the rare call site that
  /// receives a bare Object it could not map.
  const AppException.unknown()
    : code = ErrorCode.unknown,
      debugMessage = null,
      fieldErrors = const {},
      statusCode = null;

  final ErrorCode code;

  /// Developer-facing detail. Never rendered to a visitor: user-facing text is
  /// produced from [code] through the localizations.
  final String? debugMessage;

  /// Field-level validation messages keyed by input name, as returned in the
  /// `error.details` object of the API envelope.
  final Map<String, List<String>> fieldErrors;

  final int? statusCode;

  bool get isValidation => code == ErrorCode.validationFailed;

  /// True when the server said the resource does not exist. For CMS content
  /// that means "not written yet", which is an empty state rather than an error.
  bool get isNotFound => code == ErrorCode.notFound;

  /// First server-side message for [field], if the server reported one.
  String? firstErrorFor(String field) {
    final messages = fieldErrors[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }

  @override
  String toString() =>
      'AppException(${code.wireValue}'
      '${statusCode != null ? ', status: $statusCode' : ''}'
      '${debugMessage != null ? ', $debugMessage' : ''})';
}
