import 'dart:typed_data';

import 'package:dio/dio.dart';
// Override is exported from the misc library in Riverpod 3.
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:rkt_web/core/api/api_client.dart';
import 'package:rkt_web/core/api/api_providers.dart';
import 'package:rkt_web/core/config/app_config.dart';

/// Thrown when a widget test reaches the network.
///
/// A test that makes a real request is not testing anything reproducible: it
/// passes or fails depending on whether a development server happens to be
/// running on the machine. That is exactly how a suite comes to pass on a
/// developer's laptop and fail on CI, so this fails loudly and says which
/// repository was left unfaked.
class UnstubbedNetworkCall extends Error {
  UnstubbedNetworkCall(this.method, this.path);

  final String method;
  final String path;

  @override
  String toString() =>
      'A widget test made a real HTTP request: $method $path\n'
      'Override the repository provider for that feature with its fake — see '
      'test/support/fake_*_repository.dart. Nothing in a widget test may touch '
      'the network.';
}

class _RefusingAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw UnstubbedNetworkCall(options.method, options.path);
  }

  @override
  void close({bool force = false}) {}
}

/// An [ApiClient] that refuses to make requests.
///
/// Installed by default in the test harnesses so an unfaked repository fails
/// with a clear message instead of quietly succeeding against a local server —
/// or hanging on a machine where nothing answers.
ApiClient noNetworkApiClient() {
  final dio = Dio()..httpClientAdapter = _RefusingAdapter();

  return ApiClient(config: AppConfig.fromEnvironment(), dio: dio);
}

/// The override every widget-test harness installs.
Override get noNetworkOverride =>
    apiClientProvider.overrideWithValue(noNetworkApiClient());
