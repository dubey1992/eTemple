/// Deployment environments the application can be built for.
///
/// The value is supplied at build time with `--dart-define=APP_ENV=...`; it is
/// never read from a bundled file, so no environment file can leak into a build.
enum AppEnvironment {
  development('development'),
  staging('staging'),
  production('production');

  const AppEnvironment(this.key);

  final String key;

  static AppEnvironment fromKey(String? value) {
    return AppEnvironment.values.firstWhere(
      (environment) => environment.key == value?.trim().toLowerCase(),
      orElse: () => AppEnvironment.development,
    );
  }

  bool get isProduction => this == AppEnvironment.production;

  bool get isDevelopment => this == AppEnvironment.development;
}
