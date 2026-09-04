import 'package:dio/dio.dart';

import '../api/api_envelope.dart';
import 'app_exception.dart';
import 'error_code.dart';

/// Turns transport-level failures into the single [AppException] type.
///
/// Nothing above the data layer should ever see a [DioException].
class ErrorMapper {
  const ErrorMapper._();

  static AppException map(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is DioException) return _fromDio(error);

    return AppException(
      code: ErrorCode.unknown,
      debugMessage: error.toString(),
    );
  }

  static AppException _fromDio(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppException(
          code: ErrorCode.timeout,
          debugMessage: error.message,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return AppException(
          code: ErrorCode.network,
          debugMessage: error.message,
        );

      case DioExceptionType.cancel:
        return AppException(
          code: ErrorCode.cancelled,
          debugMessage: error.message,
        );

      case DioExceptionType.badCertificate:
        return AppException(
          code: ErrorCode.network,
          debugMessage: 'Bad TLS certificate: ${error.message}',
        );

      case DioExceptionType.badResponse:
        return ApiEnvelopeParser.parseError(
          error.response?.data,
          statusCode: error.response?.statusCode,
        );
    }
  }
}
