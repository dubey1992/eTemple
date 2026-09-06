import '../api/browser/browser_support.dart';
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
    required this.useMethodOverride,
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

    // A deployment always passes `API_BASE_URL`, and it is used exactly as
    // given. Only the *development default* is adjusted, and only in the
    // browser: see [_developmentDefault].
    final resolvedBaseUrl = const bool.hasEnvironment('API_BASE_URL')
        ? apiBaseUrl
        : _developmentDefault(apiBaseUrl);

    const connectTimeoutMs = int.fromEnvironment(
      'API_CONNECT_TIMEOUT_MS',
      defaultValue: 15000,
    );
    const receiveTimeoutMs = int.fromEnvironment(
      'API_RECEIVE_TIMEOUT_MS',
      defaultValue: 20000,
    );

    // Send PUT/PATCH/DELETE as POST + X-HTTP-Method-Override.
    //
    // The production host answers those three verbs with a LiteSpeed 403 before
    // the request ever reaches PHP — so every edit and every delete in the
    // console failed, and because that 403 carries no CORS header the browser
    // reported it as a CORS error rather than as the 403 it is.
    //
    // Defaults to true, including in development, on purpose. A flag that is
    // off locally and on in production reproduces exactly the gap that let this
    // ship: nothing but the live host would ever exercise the path the live
    // host uses. Set API_METHOD_OVERRIDE=false only on a host that allows the
    // real verbs and where you want them.
    const useMethodOverride = bool.fromEnvironment(
      'API_METHOD_OVERRIDE',
      defaultValue: true,
    );

    return AppConfig(
      environment: environment,
      apiBaseUrl: _normalizeBaseUrl(resolvedBaseUrl),
      connectTimeout: Duration(milliseconds: connectTimeoutMs),
      receiveTimeout: Duration(milliseconds: receiveTimeoutMs),
      // Verbose request logging is never enabled in a production bundle.
      enableVerboseLogging: !environment.isProduction,
      useMethodOverride: useMethodOverride,
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableVerboseLogging;

  /// Whether PUT/PATCH/DELETE are tunnelled through POST. See the factory.
  final bool useMethodOverride;

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

  /// The development API origin, moved onto whatever host the page is being
  /// served from.
  ///
  /// Cookies are keyed by **host**, and `localhost` and `127.0.0.1` are two
  /// different hosts. With `http://localhost:8000/api` compiled in, a developer
  /// who opens the app at `http://127.0.0.1:5000` gets an `XSRF-TOKEN` written
  /// against `localhost`, invisible to `document.cookie` on `127.0.0.1`; the
  /// header is never sent, every sign-in is a 419, and the visitor is told
  /// "session expired — reload the page", which is true and useless.
  ///
  /// This keeps the scheme, the port and the path of the default and swaps only
  /// the host, so both addresses work. It touches nothing in production, where
  /// `API_BASE_URL` is always supplied (PHASE_7_PLAN §8, defect D1).
  static String _developmentDefault(String fallback) {
    const browser = BrowserSupport();
    final host = browser.currentHost;

    if (!browser.isWeb || host == null || host.isEmpty) return fallback;

    final uri = Uri.parse(fallback);
    if (uri.host == host) return fallback;

    return uri.replace(host: host).toString();
  }

  static String _normalizeBaseUrl(String value) {
    final trimmed = value.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }
}
