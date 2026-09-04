import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:rkt_web/core/api/browser/browser_support.dart';

/// Serves canned responses to a real [Dio] instance.
///
/// Using the real client with a fake transport means the tests exercise the
/// interceptors, envelope parsing and error mapping exactly as production does.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  /// Convenience for a single JSON response.
  factory FakeHttpAdapter.json(Object? body, {int statusCode = 200}) =>
      FakeHttpAdapter((_) async => jsonResponse(body, statusCode: statusCode));

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// Every request the adapter has seen, in order.
  final List<RequestOptions> requests = [];

  static ResponseBody jsonResponse(Object? body, {int statusCode = 200}) {
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Pretends to be a browser so the CSRF path can be tested on the Dart VM.
class FakeBrowserSupport implements BrowserSupport {
  FakeBrowserSupport({this.isWeb = true, this.cookies = const {}});

  @override
  final bool isWeb;

  final Map<String, String> cookies;

  bool credentialsEnabled = false;

  @override
  void enableCredentials(Dio dio) => credentialsEnabled = true;

  @override
  String? readCookie(String name) => cookies[name];
}
