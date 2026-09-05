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

  /// Opens a URL **on this application's own API** in a new tab.
  ///
  /// The difference from [open] is one word: `noreferrer` is absent, and it has
  /// to be. Sanctum decides a request is stateful — and therefore carries the
  /// session — by matching the `Referer` **or** the `Origin` against its
  /// configured domains. A top-level navigation started by `window.open` sends
  /// no `Origin` at all, so stripping the `Referer` leaves the request with
  /// neither: the API sees an anonymous caller and refuses it.
  ///
  /// `noopener` stays, because that is the part that protects this page.
  ///
  /// Used for the report exports, a donation receipt and a transaction's bill —
  /// all of them our own, authenticated endpoints.
  bool openOwn(String url) {
    web.window.open(url, '_blank', 'noopener');
    return true;
  }
}
