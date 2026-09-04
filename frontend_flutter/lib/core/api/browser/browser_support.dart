/// Platform-specific browser behaviour needed by the API client.
///
/// The web implementation turns on credentialed XHR (so the HttpOnly session
/// cookie is sent) and reads the non-HttpOnly `XSRF-TOKEN` cookie that Laravel
/// sets. On the Dart VM — which is what `flutter test` runs on — both are no-ops,
/// which keeps the client unit-testable without a browser.
library;

export 'browser_support_io.dart'
    if (dart.library.js_interop) 'browser_support_web.dart';
