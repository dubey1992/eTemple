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

  /// The host the page itself was served from — `localhost`, `127.0.0.1`, or a
  /// real domain.
  ///
  /// Used only to build the *development* default API origin. Cookies are keyed
  /// by host, and `localhost` and `127.0.0.1` are two different hosts: a bundle
  /// with `localhost:8000` compiled into it, opened at `127.0.0.1:5000`, writes
  /// its `XSRF-TOKEN` where the page cannot read it, and every sign-in fails as
  /// a 419 reported to the user as "session expired"
  /// (PHASE_7_PLAN §8, defect D1).
  String? get currentHost {
    final host = web.window.location.hostname;
    return host.isEmpty ? null : host;
  }

  bool get isWeb => true;
}
