import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/api/api_envelope.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';

void main() {
  group('ApiEnvelopeParser.parse', () {
    test('decodes a success envelope', () {
      final envelope = ApiEnvelopeParser.parse<Map<String, dynamic>>({
        'success': true,
        'data': {'id': 7},
        'meta': null,
      }, (data) => ApiEnvelopeParser.asMap(data)!);

      expect(envelope.data['id'], 7);
      expect(envelope.meta, isNull);
    });

    test('decodes pagination meta', () {
      final envelope = ApiEnvelopeParser.parse<List<Object?>>({
        'success': true,
        'data': [1, 2],
        'meta': {
          'current_page': 2,
          'per_page': 2,
          'total': 7,
          'last_page': 4,
          'has_more': true,
        },
      }, (data) => data! as List<Object?>);

      expect(envelope.meta!.currentPage, 2);
      expect(envelope.meta!.total, 7);
      expect(envelope.meta!.hasMore, isTrue);
    });

    test('derives has_more when the server omits it', () {
      final meta = PageMeta.fromJson({
        'current_page': 1,
        'per_page': '10',
        'total': 30,
        'last_page': 3,
      });

      expect(meta.perPage, 10, reason: 'numeric strings are tolerated');
      expect(meta.hasMore, isTrue);
    });

    test('throws malformedResponse for a non-object body', () {
      expect(
        () => ApiEnvelopeParser.parse<Object?>('<html>502</html>', (d) => d),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            ErrorCode.malformedResponse,
          ),
        ),
      );
    });

    test('throws when the envelope reports failure', () {
      expect(
        () => ApiEnvelopeParser.parse<Object?>({
          'success': false,
          'error': {'code': 'FORBIDDEN', 'message': 'nope'},
        }, (d) => d),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            ErrorCode.forbidden,
          ),
        ),
      );
    });
  });

  group('ApiEnvelopeParser.parseError', () {
    test('reads the code, message and field details', () {
      final error = ApiEnvelopeParser.parseError({
        'success': false,
        'error': {
          'code': 'VALIDATION_FAILED',
          'message': 'The submitted data is invalid.',
          'details': {
            'email': ['The email field is required.'],
          },
        },
      }, statusCode: 422);

      expect(error.code, ErrorCode.validationFailed);
      expect(error.isValidation, isTrue);
      expect(error.statusCode, 422);
      expect(error.firstErrorFor('email'), 'The email field is required.');
      expect(error.firstErrorFor('password'), isNull);
    });

    test('accepts a single string detail as well as a list', () {
      final error = ApiEnvelopeParser.parseError({
        'success': false,
        'error': {
          'code': 'VALIDATION_FAILED',
          'details': {'email': 'Required.'},
        },
      }, statusCode: 422);

      expect(error.firstErrorFor('email'), 'Required.');
    });

    test('falls back to the status code when the body is not our envelope', () {
      final error = ApiEnvelopeParser.parseError(
        '<html>Gateway timeout</html>',
        statusCode: 503,
      );

      expect(error.code, ErrorCode.serverError);
    });

    test('falls back to the status code for an unrecognised code string', () {
      final error = ApiEnvelopeParser.parseError({
        'success': false,
        'error': {'code': 'SOMETHING_NEW'},
      }, statusCode: 403);

      expect(error.code, ErrorCode.forbidden);
    });

    test('maps an unknown status with no body to unknown', () {
      expect(
        ApiEnvelopeParser.parseError(null, statusCode: null).code,
        ErrorCode.unknown,
      );
    });
  });

  group('ErrorCode', () {
    test('round-trips the wire values shared with the backend', () {
      expect(ErrorCode.fromWire('ACCOUNT_BLOCKED'), ErrorCode.accountBlocked);
      expect(ErrorCode.fromWire(null), ErrorCode.unknown);
    });

    test('flags the codes that force re-authentication', () {
      expect(ErrorCode.unauthenticated.requiresReauthentication, isTrue);
      expect(ErrorCode.accountInactive.requiresReauthentication, isTrue);
      expect(ErrorCode.accountBlocked.requiresReauthentication, isTrue);
      expect(ErrorCode.validationFailed.requiresReauthentication, isFalse);
    });
  });
}
