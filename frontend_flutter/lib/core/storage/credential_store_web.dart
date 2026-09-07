import 'dart:convert';

import 'package:web/web.dart' as web;

import 'saved_credentials.dart';

/// Web implementation. See `credential_store.dart` for what this costs.
class CredentialStore {
  const CredentialStore();

  /// One key, so clearing is unambiguous and nothing can be half-forgotten.
  static const String _key = 'rkt.remembered_sign_in';

  SavedCredentials? read() {
    try {
      final raw = web.window.localStorage.getItem(_key);
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;

      final email = decoded['email'];
      final password = decoded['password'];
      if (email is! String || password is! String) return null;
      if (email.isEmpty) return null;

      return SavedCredentials(email: email, password: password);
    } catch (_) {
      // Storage can be unavailable or full (private windows, blocked site
      // data), and the stored value can be anything a previous version wrote.
      // A sign-in form that will not render because a convenience failed is a
      // worse outcome than one that simply starts empty.
      return null;
    }
  }

  void save(SavedCredentials credentials) {
    try {
      web.window.localStorage.setItem(
        _key,
        jsonEncode({
          'email': credentials.email,
          'password': credentials.password,
        }),
      );
    } catch (_) {
      // Nothing to tell the visitor: they asked to be remembered, and they will
      // find they were not. Failing the sign-in over it would be worse.
    }
  }

  void clear() {
    try {
      web.window.localStorage.removeItem(_key);
    } catch (_) {}
  }
}
