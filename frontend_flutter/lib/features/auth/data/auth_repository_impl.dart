import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_envelope.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_code.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

/// HTTP implementation of [AuthRepository] against the Laravel API.
///
/// The session lives in an HttpOnly cookie managed by the browser: no token is
/// read, stored or persisted here, which is what the specification requires for
/// browser deployments.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._api);

  final ApiClient _api;

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    bool remember = false,
  }) async {
    // Laravel rejects an unsafe request without a valid CSRF token.
    await _api.ensureCsrfCookie();

    final envelope = await _api.post<AuthUser>(
      ApiEndpoints.login,
      body: {'email': email.trim(), 'password': password, 'remember': remember},
      decode: _decodeUser,
    );

    return envelope.data;
  }

  @override
  Future<void> signOut() async {
    try {
      await _api.post<void>(ApiEndpoints.logout, decode: (_) {});
    } on AppException catch (error) {
      // The session was already gone server-side; the caller's intent is
      // satisfied either way.
      if (error.code.requiresReauthentication) return;
      rethrow;
    }
  }

  @override
  Future<AuthUser?> currentUser() async {
    try {
      final envelope = await _api.get<AuthUser>(
        ApiEndpoints.me,
        decode: _decodeUser,
      );
      return envelope.data;
    } on AppException catch (error) {
      // No session, or the account was deactivated or blocked since sign-in:
      // all three mean "not signed in" for the purposes of restoring state.
      if (error.code.requiresReauthentication) return null;
      rethrow;
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _api.ensureCsrfCookie();

    await _api.post<void>(
      ApiEndpoints.forgotPassword,
      body: {'email': email.trim()},
      decode: (_) {},
    );
  }

  @override
  Future<void> resetPassword({
    required String token,
    required String email,
    required String password,
  }) async {
    await _api.ensureCsrfCookie();

    await _api.post<void>(
      ApiEndpoints.resetPassword,
      body: {
        'token': token,
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
      },
      decode: (_) {},
    );
  }

  static AuthUser _decodeUser(Object? data) {
    final json = ApiEnvelopeParser.asMap(data);
    if (json == null) {
      throw const AppException(
        code: ErrorCode.malformedResponse,
        debugMessage: 'Expected a user object in the response data.',
      );
    }
    return AuthUser.fromJson(json);
  }
}
