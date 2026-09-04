import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'api_client.dart';

/// Build-time configuration. Overridden in tests to point at a fake server.
final appConfigProvider = Provider<AppConfig>(
  (ref) => AppConfig.fromEnvironment(),
);

final appLoggerProvider = Provider<AppLogger>(
  (ref) =>
      AppLogger(enabled: ref.watch(appConfigProvider).enableVerboseLogging),
);

/// The shared HTTP client. Repositories depend on this, never on Dio directly.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    config: ref.watch(appConfigProvider),
    logger: ref.watch(appLoggerProvider),
  ),
);
