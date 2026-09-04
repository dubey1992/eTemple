/// Non-web stub. See `link_opener.dart`.
class LinkOpener {
  const LinkOpener();

  /// No-op: there is no browser to open a tab in.
  bool open(String url) => false;
}
