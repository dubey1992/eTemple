import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/core/api/api_client.dart';
import 'package:rkt_web/core/config/app_config.dart';
import 'package:rkt_web/core/config/app_environment.dart';

import '../../support/fake_http.dart';

/// PUT, PATCH and DELETE are tunnelled through POST.
///
/// The production host answers all three with a LiteSpeed 403 raised before the
/// request reaches PHP, so every edit and every delete in the console failed.
/// Worse, that 403 carries no `Access-Control-Allow-Origin` header — a header
/// Laravel's own CORS middleware would have added — so the browser reported a
/// CORS failure and hid the status entirely. Nothing in the app was wrong, and
/// nothing in the app could see what was.
///
/// These tests pin the rewrite at the one place it happens. A repository added
/// later inherits it without knowing it exists, which is the point.
AppConfig _config({bool useMethodOverride = true}) => AppConfig(
  environment: AppEnvironment.development,
  apiBaseUrl: 'http://localhost:8000/api',
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 5),
  enableVerboseLogging: false,
  useMethodOverride: useMethodOverride,
);

({ApiClient client, FakeHttpAdapter adapter}) _build({
  bool useMethodOverride = true,
  Map<String, String> cookies = const {},
}) {
  final adapter = FakeHttpAdapter.json({'success': true, 'data': null});
  final dio = Dio()..httpClientAdapter = adapter;

  return (
    client: ApiClient(
      config: _config(useMethodOverride: useMethodOverride),
      dio: dio,
      browser: FakeBrowserSupport(cookies: cookies),
    ),
    adapter: adapter,
  );
}

Object? _decode(Object? data) => data;

void main() {
  group('the verbs the host refuses', () {
    test('PUT goes out as POST and declares the verb it meant', () async {
      final h = _build();

      await h.client.put<Object?>('/admin/temple-profile', decode: _decode);

      final sent = h.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.headers['X-HTTP-Method-Override'], 'PUT');
    });

    test('PATCH goes out as POST', () async {
      final h = _build();

      await h.client.dio.patch<Object?>('/admin/anything');

      final sent = h.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.headers['X-HTTP-Method-Override'], 'PATCH');
    });

    test('DELETE goes out as POST', () async {
      final h = _build();

      await h.client.delete<Object?>('/admin/media/7', decode: _decode);

      final sent = h.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.headers['X-HTTP-Method-Override'], 'DELETE');
    });

    test('the body survives the rewrite', () async {
      final h = _build();

      await h.client.put<Object?>(
        '/admin/temple-profile',
        body: {'name_hi': 'राधा कृष्ण ठाकुरवाड़ी'},
        decode: _decode,
      );

      expect(h.adapter.requests.single.data, {
        'name_hi': 'राधा कृष्ण ठाकुरवाड़ी',
      });
    });

    test('the CSRF header is still attached', () async {
      final h = _build(cookies: {'XSRF-TOKEN': 'a-token'});

      await h.client.put<Object?>('/admin/temple-profile', decode: _decode);

      expect(h.adapter.requests.single.headers['X-XSRF-TOKEN'], 'a-token');
    });
  });

  group('the verbs the host allows', () {
    test('GET is left alone', () async {
      final h = _build();

      await h.client.get<Object?>('/admin/temple-profile', decode: _decode);

      final sent = h.adapter.requests.single;
      expect(sent.method, 'GET');
      expect(sent.headers.containsKey('X-HTTP-Method-Override'), isFalse);
    });

    test('POST is left alone', () async {
      final h = _build();

      await h.client.post<Object?>('/admin/media', decode: _decode);

      final sent = h.adapter.requests.single;
      expect(sent.method, 'POST');
      expect(sent.headers.containsKey('X-HTTP-Method-Override'), isFalse);
    });
  });

  test('a host that allows the real verbs can turn the rewrite off', () async {
    final h = _build(useMethodOverride: false);

    await h.client.put<Object?>('/admin/temple-profile', decode: _decode);

    final sent = h.adapter.requests.single;
    expect(sent.method, 'PUT');
    expect(sent.headers.containsKey('X-HTTP-Method-Override'), isFalse);
  });
}
