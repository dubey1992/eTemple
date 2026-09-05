/// Non-web stub. See `link_opener.dart`.
class LinkOpener {
  const LinkOpener();

  /// No-op: there is no browser to open a tab in.
  bool open(String url) => false;

  /// The same. See [open], and `link_opener_web.dart` for why our own API
  /// needs a tab opened without `noreferrer`.
  bool openOwn(String url) => false;
}
