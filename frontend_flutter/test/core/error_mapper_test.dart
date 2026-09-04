import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/core/errors/error_mapper.dart';

DioException _dio(DioExceptionType type, {Response<Object?>? response}) {
  return DioException(
    requestOptions: RequestOptions(path: '/auth/login'),
    type: type,
    response: response,
  );
}

void main() {
  group('ErrorMapper', () {
    test('passes an AppException through unchanged', () {
      const original = AppException(code: ErrorCode.forbidden);
      expect(identical(ErrorMapper.map(original), original), isTrue);
    });

    test('maps every timeout variant to timeout', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(ErrorMapper.map(_dio(type)).code, ErrorCode.timeout);
      }
    });

    test('maps connection failures to network', () {
      expect(
        ErrorMapper.map(_dio(DioExceptionType.connectionError)).code,
        ErrorCode.network,
      );
      expect(
        ErrorMapper.map(_dio(DioExceptionType.unknown)).code,
        ErrorCode.network,
      );
      expect(
        ErrorMapper.map(_dio(DioExceptionType.badCertificate)).code,
        ErrorCode.network,
      );
    });

    test('maps cancellation', () {
      expect(
        ErrorMapper.map(_dio(DioExceptionType.cancel)).code,
        ErrorCode.cancelled,
      );
    });

    test('maps a bad response through the error envelope', () {
      final error = ErrorMapper.map(
        _dio(
          DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/auth/login'),
            statusCode: 403,
            data: {
              'success': false,
              'error': {
                'code': 'ACCOUNT_BLOCKED',
                'message': 'This account has been blocked.',
              },
            },
          ),
        ),
      );

      expect(error.code, ErrorCode.accountBlocked);
      expect(error.statusCode, 403);
    });

    test('maps a 500 with an HTML body to a server error', () {
      final error = ErrorMapper.map(
        _dio(
          DioExceptionType.badResponse,
          response: Response<Object?>(
            requestOptions: RequestOptions(path: '/auth/me'),
            statusCode: 500,
            data: '<html>Internal Server Error</html>',
          ),
        ),
      );

      expect(error.code, ErrorCode.serverError);
    });

    test('maps an arbitrary object to unknown', () {
      expect(ErrorMapper.map(StateError('boom')).code, ErrorCode.unknown);
    });
  });
}
