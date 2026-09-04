import 'package:dio/dio.dart';

/// Non-web stub. See `browser_support.dart`.
class BrowserSupport {
  const BrowserSupport();

  /// No-op: credentialed requests are a browser concept.
  void enableCredentials(Dio dio) {}

  /// No-op: there is no document to read cookies from.
  String? readCookie(String name) => null;

  bool get isWeb => false;
}
