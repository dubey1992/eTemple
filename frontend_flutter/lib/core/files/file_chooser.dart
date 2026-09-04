/// Opens the browser's own file chooser.
///
/// Split by platform in the same way as `browser_support.dart`: the web
/// implementation drives an `<input type="file">`, and on the Dart VM — which
/// is what `flutter test` runs on — the chooser returns nothing, so widgets
/// that offer an upload stay testable without a browser.
///
/// No package is added for this. The one thing a picker library would buy is
/// desktop and mobile support, and this product is Flutter **Web**.
library;

export 'file_chooser_io.dart'
    if (dart.library.js_interop) 'file_chooser_web.dart';
