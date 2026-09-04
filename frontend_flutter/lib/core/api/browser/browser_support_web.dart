import 'package:dio/browser.dart';
import 'package:dio/dio.dart';
import 'package:web/web.dart' as web;

/// Web implementation. See `browser_support.dart`.
class BrowserSupport {
  const BrowserSupport();

  /// Sends cookies with cross-origin API calls.
  ///
  /// Required for Sanctum's cookie/session authentication: without it the
  /// browser drops the HttpOnly session cookie and every protected call is 401.
  void enableCredentials(Dio dio) {
    final adapter = dio.httpClientAdapter;
    if (adapter is BrowserHttpClientAdapter) {
      adapter.withCredentials = true;
    }
  }

  /// Reads a readable (non-HttpOnly) cookie by name.
  ///
  /// Only ever used for `XSRF-TOKEN`, which Laravel intentionally exposes to
  /// script so the client can echo it back as a header. The session cookie
  /// itself is HttpOnly and is deliberately unreadable here.
  String? readCookie(String name) {
    final raw = web.document.cookie;
    if (raw.isEmpty) return null;

    for (final part in raw.split(';')) {
      final entry = part.trim();
      final separator = entry.indexOf('=');
      if (separator <= 0) continue;
      if (entry.substring(0, separator) != name) continue;

      return Uri.decodeComponent(entry.substring(separator + 1));
    }
    return null;
  }

  bool get isWeb => true;
}
