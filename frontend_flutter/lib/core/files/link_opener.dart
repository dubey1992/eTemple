/// Opens an external link in a new browser tab.
///
/// Split by platform in the same way as `browser_support.dart`: on the Dart VM
/// — which is what `flutter test` runs on — opening is a no-op that reports
/// failure, so a widget offering an external link stays testable.
library;

export 'link_opener_io.dart'
    if (dart.library.js_interop) 'link_opener_web.dart';
