import 'package:web/web.dart' as web;

/// Web implementation. See `link_opener.dart`.
class LinkOpener {
  const LinkOpener();

  /// Opens [url] in a new tab.
  ///
  /// `noopener` is not optional: without it the opened page gets a handle on
  /// this one through `window.opener` and can navigate it somewhere else, which
  /// matters most for exactly the case this is used for — a link to a third
  /// party.
  bool open(String url) {
    web.window.open(url, '_blank', 'noopener,noreferrer');
    return true;
  }
}
