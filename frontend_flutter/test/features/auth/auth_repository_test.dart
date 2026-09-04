import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/api/api_client.dart';
import 'package:rkt_web/core/config/app_config.dart';
import 'package:rkt_web/core/config/app_environment.dart';
import 'package:rkt_web/core/errors/app_exception.dart';
import 'package:rkt_web/core/errors/error_code.dart';
import 'package:rkt_web/features/auth/data/auth_repository_impl.dart';

import '../../support/fake_http.dart';

const _config = AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: 'http://localhost:8000/api',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 5),
  enableVerboseLogging: false,
);

Map<String, Object?> _userPayload({
  String status = 'active',
  String role = 'admin',
}) => {
  'id': 3,
  'first_name': 'सीता',
  'last_name': 'देवी',
  'full_name': 'सीता देवी',
  'email': 'committee@thakurbari.in',
  'mobile': null,
  'status': status,
  'last_login_at': '2026-09-04T06:30:00+05:30',
  'role': {'id': 2, 'slug': role, 'name': 'Admin'},
};

({AuthRepositoryImpl repository, FakeHttpAdapter adapter}) build(
  Future<ResponseBody> Function(RequestOptions options) handler, {
  bool isWeb = true,
  Map<String, String> cookies = const {},
}) {
  final adapter = FakeHttpAdapter(handler);
  final dio = Dio()..httpClientAdapter = adapter;
  final client = ApiClient(
    config: _config,
    dio: dio,
    browser: FakeBrowserSupport(isWeb: isWeb, cookies: cookies),
  );

  return (repository: AuthRepositoryImpl(client), adapter: adapter);
}

void main() {
  group('signIn', () {
    test('returns the parsed user on success', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': true,
                'data': _userPayload(),
                'meta': null,
              }),
      );

      final user = await harness.repository.signIn(
        email: '  Committee@Thakurbari.in ',
        password: 'a-valid-password',
      );

      expect(user.id, 3);
      expect(user.displayName, 'सीता देवी');
      expect(user.email, 'committee@thakurbari.in');
      expect(user.isActive, isTrue);
      expect(user.role?.slug, 'admin');
      expect(user.lastLoginAt, isNotNull);
    });

    test('fetches the CSRF cookie before posting credentials', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': true,
                'data': _userPayload(),
                'meta': null,
              }),
      );

      await harness.repository.signIn(
        email: 'committee@thakurbari.in',
        password: 'a-valid-password',
      );

      expect(
        harness.adapter.requests.first.path,
        contains('/sanctum/csrf-cookie'),
      );
      expect(harness.adapter.requests.last.path, contains('/auth/login'));
    });

    test('sends the trimmed e-mail and the raw password', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': true,
                'data': _userPayload(),
                'meta': null,
              }),
      );

      await harness.repository.signIn(
        email: '  committee@thakurbari.in  ',
        password: '  spaced password  ',
        remember: true,
      );

      final body = harness.adapter.requests.last.data! as Map<String, dynamic>;
      expect(body['email'], 'committee@thakurbari.in');
      expect(body['password'], '  spaced password  ');
      expect(body['remember'], isTrue);
    });

    test('echoes the XSRF-TOKEN cookie back as a header', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': true,
                'data': _userPayload(),
                'meta': null,
              }),
        cookies: {'XSRF-TOKEN': 'token-value'},
      );

      await harness.repository.signIn(
        email: 'committee@thakurbari.in',
        password: 'a-valid-password',
      );

      final login = harness.adapter.requests.last;
      expect(login.headers['X-XSRF-TOKEN'], 'token-value');
      expect(login.headers['X-Requested-With'], 'XMLHttpRequest');
    });

    test('surfaces invalid credentials as a typed exception', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': false,
                'error': {
                  'code': 'INVALID_CREDENTIALS',
                  'message': 'These credentials do not match our records.',
                },
              }, statusCode: 401),
      );

      await expectLater(
        harness.repository.signIn(
          email: 'committee@thakurbari.in',
          password: 'wrong-password',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            ErrorCode.invalidCredentials,
          ),
        ),
      );
    });

    test('surfaces a blocked account distinctly', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': false,
                'error': {'code': 'ACCOUNT_BLOCKED', 'message': 'Blocked.'},
              }, statusCode: 403),
      );

      await expectLater(
        harness.repository.signIn(
          email: 'blocked@thakurbari.in',
          password: 'a-valid-password',
        ),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            ErrorCode.accountBlocked,
          ),
        ),
      );
    });

    test('surfaces server-side field errors', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': false,
                'error': {
                  'code': 'VALIDATION_FAILED',
                  'message': 'The submitted data is invalid.',
                  'details': {
                    'email': ['The email field is required.'],
                  },
                },
              }, statusCode: 422),
      );

      try {
        await harness.repository.signIn(email: '', password: 'a-password');
        fail('Expected an AppException.');
      } on AppException catch (error) {
        expect(error.isValidation, isTrue);
        expect(error.firstErrorFor('email'), 'The email field is required.');
      }
    });

    test('skips the CSRF round-trip off the web', () async {
      final harness = build(
        (options) async => FakeHttpAdapter.jsonResponse({
          'success': true,
          'data': _userPayload(),
          'meta': null,
        }),
        isWeb: false,
      );

      await harness.repository.signIn(
        email: 'committee@thakurbari.in',
        password: 'a-valid-password',
      );

      expect(harness.adapter.requests, hasLength(1));
      expect(harness.adapter.requests.single.path, contains('/auth/login'));
    });
  });

  group('currentUser', () {
    test('returns the user for a live session', () async {
      final harness = build(
        (_) async => FakeHttpAdapter.jsonResponse({
          'success': true,
          'data': _userPayload(role: 'treasurer'),
          'meta': null,
        }),
      );

      final user = await harness.repository.currentUser();
      expect(user?.role?.slug, 'treasurer');
    });

    test('returns null when there is no session', () async {
      final harness = build(
        (_) async => FakeHttpAdapter.jsonResponse({
          'success': false,
          'error': {'code': 'UNAUTHENTICATED', 'message': 'Login required.'},
        }, statusCode: 401),
      );

      expect(await harness.repository.currentUser(), isNull);
    });

    test(
      'returns null when the account was deactivated since sign-in',
      () async {
        final harness = build(
          (_) async => FakeHttpAdapter.jsonResponse({
            'success': false,
            'error': {'code': 'ACCOUNT_INACTIVE', 'message': 'Not active.'},
          }, statusCode: 403),
        );

        expect(await harness.repository.currentUser(), isNull);
      },
    );

    test(
      'rethrows a transport failure rather than reporting signed out',
      () async {
        final harness = build(
          (options) async => throw DioException(
            requestOptions: options,
            type: DioExceptionType.connectionError,
          ),
        );

        await expectLater(
          harness.repository.currentUser(),
          throwsA(
            isA<AppException>().having(
              (e) => e.code,
              'code',
              ErrorCode.network,
            ),
          ),
        );
      },
    );

    test('tolerates a payload missing every optional field', () async {
      final harness = build(
        (_) async => FakeHttpAdapter.jsonResponse({
          'success': true,
          'data': {
            'id': 9,
            'first_name': 'राम',
            'email': 'ram@thakurbari.in',
            'status': 'active',
          },
          'meta': null,
        }),
      );

      final user = await harness.repository.currentUser();
      expect(user!.lastName, isNull);
      expect(user.role, isNull);
      expect(user.lastLoginAt, isNull);
      expect(user.displayName, 'राम');
    });

    test('raises malformedResponse when data is not a user object', () async {
      final harness = build(
        (_) async => FakeHttpAdapter.jsonResponse({
          'success': true,
          'data': 'not-an-object',
          'meta': null,
        }),
      );

      await expectLater(
        harness.repository.currentUser(),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            ErrorCode.malformedResponse,
          ),
        ),
      );
    });
  });

  group('signOut', () {
    test('completes normally when the session has already expired', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': false,
                'error': {'code': 'UNAUTHENTICATED', 'message': 'Gone.'},
              }, statusCode: 401),
      );

      await expectLater(harness.repository.signOut(), completes);
    });

    test('rethrows a genuine failure', () async {
      final harness = build(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        harness.repository.signOut(),
        throwsA(
          isA<AppException>().having((e) => e.code, 'code', ErrorCode.network),
        ),
      );
    });
  });

  group('requestPasswordReset', () {
    test('posts the address and accepts the generic confirmation', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': true,
                'data': {'message': 'If that e-mail address belongs…'},
                'meta': null,
              }),
      );

      await harness.repository.requestPasswordReset(
        ' committee@thakurbari.in ',
      );

      final body = harness.adapter.requests.last.data! as Map<String, dynamic>;
      expect(body['email'], 'committee@thakurbari.in');
    });

    test('surfaces throttling', () async {
      final harness = build(
        (options) async => options.path.contains('csrf-cookie')
            ? FakeHttpAdapter.jsonResponse(null, statusCode: 204)
            : FakeHttpAdapter.jsonResponse({
                'success': false,
                'error': {
                  'code': 'TOO_MANY_REQUESTS',
                  'message': 'Too many attempts.',
                },
              }, statusCode: 429),
      );

      await expectLater(
        harness.repository.requestPasswordReset('committee@thakurbari.in'),
        throwsA(
          isA<AppException>().having(
            (e) => e.code,
            'code',
            ErrorCode.tooManyRequests,
          ),
        ),
      );
    });
  });
}
