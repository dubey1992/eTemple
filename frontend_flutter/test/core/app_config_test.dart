import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/config/app_config.dart';
import 'package:rkt_web/core/config/app_environment.dart';

void main() {
  group('AppEnvironment', () {
    test('parses the known keys case-insensitively', () {
      expect(AppEnvironment.fromKey('production'), AppEnvironment.production);
      expect(AppEnvironment.fromKey(' Staging '), AppEnvironment.staging);
    });

    test('defaults to development for anything unrecognised', () {
      expect(AppEnvironment.fromKey(null), AppEnvironment.development);
      expect(AppEnvironment.fromKey('prod'), AppEnvironment.development);
    });
  });

  group('AppConfig', () {
    test('uses safe local defaults when nothing is defined', () {
      final config = AppConfig.fromEnvironment();

      expect(config.environment, AppEnvironment.development);
      expect(config.apiBaseUrl, 'http://localhost:8000/api');
      expect(config.connectTimeout, const Duration(seconds: 15));
      expect(config.receiveTimeout, const Duration(seconds: 20));
    });

    test('enables verbose logging outside production only', () {
      expect(AppConfig.fromEnvironment().enableVerboseLogging, isTrue);

      const production = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://api.example.test/api',
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 20),
        enableVerboseLogging: false,
        useMethodOverride: true,
      );
      expect(production.enableVerboseLogging, isFalse);
    });

    test('derives the API origin for the Sanctum CSRF route', () {
      const config = AppConfig(
        environment: AppEnvironment.production,
        apiBaseUrl: 'https://api.thakurbari.example/api',
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 20),
        enableVerboseLogging: false,
        useMethodOverride: true,
      );

      expect(config.apiOrigin, 'https://api.thakurbari.example');
    });

    test('keeps a non-default port in the origin', () {
      const config = AppConfig(
        environment: AppEnvironment.development,
        apiBaseUrl: 'http://localhost:8000/api',
        connectTimeout: Duration(seconds: 15),
        receiveTimeout: Duration(seconds: 20),
        enableVerboseLogging: true,
        useMethodOverride: true,
      );

      expect(config.apiOrigin, 'http://localhost:8000');
    });

    test('the development default keeps its host off the web', () {
      // On the Dart VM there is no page, so there is no host to move onto and
      // the compiled-in default stands unchanged. In a browser the host is
      // taken from `window.location`, which is what stops a bundle opened at
      // `127.0.0.1:5000` from writing its XSRF cookie against `localhost` and
      // failing every sign-in with a 419 (PHASE_7_PLAN §8, defect D1).
      //
      // That branch needs a browser and is covered by the live check in
      // PHASE_7_COMPLETION rather than here.
      expect(
        AppConfig.fromEnvironment().apiBaseUrl,
        'http://localhost:8000/api',
      );
    });
  });
}
