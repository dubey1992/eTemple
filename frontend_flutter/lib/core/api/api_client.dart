import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';
import '../errors/error_mapper.dart';
import '../logging/app_logger.dart';
import 'api_endpoints.dart';
import 'api_envelope.dart';
import 'browser/browser_support.dart';

/// The single HTTP entry point for the application.
///
/// Responsibilities kept here on purpose:
///  * credentialed (cookie/session) requests to the Laravel API,
///  * CSRF header handling for unsafe methods,
///  * envelope decoding,
///  * turning every transport failure into an [AppException].
///
/// Repositories call [get]/[post] and receive already-decoded data; no widget
/// and no notifier ever touches Dio directly.
class ApiClient {
  ApiClient({
    required AppConfig config,
    Dio? dio,
    this.browser = const BrowserSupport(),
    AppLogger? logger,
  }) : _config = config,
       _logger = logger ?? AppLogger(enabled: config.enableVerboseLogging),
       _dio = dio ?? Dio() {
    _configure();
  }

  final AppConfig _config;
  final AppLogger _logger;

  /// Platform bridge for credentialed requests and cookie reads.
  /// Overridden in tests with a fake to simulate a browser.
  final BrowserSupport browser;
  final Dio _dio;

  /// Exposed for interceptor configuration and tests only.
  Dio get dio => _dio;

  void _configure() {
    _dio.options = _dio.options.copyWith(
      baseUrl: _config.apiBaseUrl,
      connectTimeout: _config.connectTimeout,
      receiveTimeout: _config.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: <String, Object?>{
        ..._dio.options.headers,
        'Accept': 'application/json',
        // Marks the call as an XHR so Laravel answers JSON instead of a redirect.
        'X-Requested-With': 'XMLHttpRequest',
      },
      // Non-2xx responses are handled by the mapper, not by throwing raw.
      validateStatus: (status) => status != null && status < 400,
    );

    browser.enableCredentials(_dio);

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _attachCsrfHeader(options);
          _logger.debug('→ ${options.method} ${options.path}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.debug(
            '← ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          // Never log the request body: it may contain a password.
          _logger.debug(
            '✗ ${error.response?.statusCode ?? '-'} '
            '${error.requestOptions.method} ${error.requestOptions.path}',
          );
          handler.next(error);
        },
      ),
    );
  }

  void _attachCsrfHeader(RequestOptions options) {
    const safeMethods = {'GET', 'HEAD', 'OPTIONS'};
    if (safeMethods.contains(options.method.toUpperCase())) return;

    final token = browser.readCookie('XSRF-TOKEN');
    if (token != null && token.isNotEmpty) {
      options.headers['X-XSRF-TOKEN'] = token;
    }
  }

  /// Fetches Laravel's CSRF cookie before the first state-changing request.
  ///
  /// Safe to call repeatedly; a failure here is surfaced like any other API
  /// failure so the caller can show a real message rather than a silent no-op.
  Future<void> ensureCsrfCookie() async {
    if (!browser.isWeb) return;

    try {
      await _dio.get<void>(
        '${_config.apiOrigin}${ApiEndpoints.csrfCookie}',
        options: Options(headers: {'Accept': '*/*'}),
      );
    } catch (error, stackTrace) {
      throw ErrorMapper.map(error, stackTrace);
    }
  }

  Future<ApiEnvelope<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
      ),
      decode,
    );
  }

  Future<ApiEnvelope<T>> post<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.post<Object?>(path, data: body, cancelToken: cancelToken),
      decode,
    );
  }

  Future<ApiEnvelope<T>> put<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.put<Object?>(path, data: body, cancelToken: cancelToken),
      decode,
    );
  }

  Future<ApiEnvelope<T>> delete<T>(
    String path, {
    Object? body,
    required T Function(Object? data) decode,
    CancelToken? cancelToken,
  }) {
    return _send(
      () => _dio.delete<Object?>(path, data: body, cancelToken: cancelToken),
      decode,
    );
  }

  Future<ApiEnvelope<T>> _send<T>(
    Future<Response<Object?>> Function() request,
    T Function(Object? data) decode,
  ) async {
    try {
      final response = await request();
      return ApiEnvelopeParser.parse<T>(response.data, decode);
    } catch (error, stackTrace) {
      final exception = ErrorMapper.map(error, stackTrace);
      _logger.debug('api error: $exception');
      throw exception;
    }
  }
}
