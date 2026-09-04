import 'app_environment.dart';

/// Build-time configuration.
///
/// Everything here arrives through `--dart-define`. The client deliberately
/// holds **no** secrets: a Flutter Web bundle is public, so API keys, database
/// credentials and tokens must never appear in this class or anywhere else in
/// `lib/` (spec security rule: "Flutter must never contain API secrets or
/// database credentials").
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    required this.enableVerboseLogging,
  });

  /// Reads the configuration handed to the build.
  ///
  /// Example:
  /// ```
  /// flutter build web --release \
  ///   --dart-define=APP_ENV=production \
  ///   --dart-define=API_BASE_URL=https://api.thakurbari.example/api
  /// ```
  factory AppConfig.fromEnvironment() {
    const environmentKey = String.fromEnvironment(
      'APP_ENV',
      defaultValue: 'development',
    );
    final environment = AppEnvironment.fromKey(environmentKey);

    const apiBaseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://localhost:8000/api',
    );

    const connectTimeoutMs = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 15000,
    );
    const receiveTimeoutMs = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 20000,
    );

    return AppConfig(
      environment: environment,
      apiBaseUrl: _normalizeBaseUrl(apiBaseUrl),
      connectTimeout: Duration(milliseconds: connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: receiveTimeoutMs),
      // Verbose request logging is never enabled in a production bundle.
      enableVerboseLogging: !environment.isProduction,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableVerboseLogging;

  /// Origin of the API, without the `/api` path segment.
  ///
  /// Sanctum serves `/sanctum/csrf-cookie` from the application root rather than
  /// from under `/api`.
  String get apiOrigin {
    final uri = Uri.parse(apiBaseUrl);
    return Uri(
      scheme: uri.scheme,
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
    ).toString();
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
